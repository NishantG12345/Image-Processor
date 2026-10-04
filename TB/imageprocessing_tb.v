module image_processing_tb;

parameter IMAGE_WIDTH = 258;
parameter STALL_MODE = 1;
parameter READY_PCT = 75;
parameter VALID_PCT = 100;
localparam OUTPUT_WIDTH = IMAGE_WIDTH - 2;
localparam INPUT_PIXELS = IMAGE_WIDTH * IMAGE_WIDTH;
localparam OUTPUT_PIXELS = OUTPUT_WIDTH * OUTPUT_WIDTH;
reg clk;
reg rst;
reg s_axis_tvalid;
reg [7:0] s_axis_tdata;
wire s_axis_tready;

wire [7:0] m_axis_tdata;
wire m_axis_tvalid;
reg m_axis_tready;

reg input_transfer_sampled;
reg [7:0] input_data_sampled;
reg output_transfer_sampled;
reg [7:0] output_data_sampled;
reg output_valid_sampled;
reg output_ready_sampled;

reg prev_stalled;
reg [7:0] prev_out_data;

integer pix;
integer expected;
integer pix_file;
integer ex_file;
integer out_file;
integer res;
integer errors;
integer protocol_errors;
integer input_errors;
integer input_count;
integer loaded_count;
integer output_count;
integer drain_cycles;
integer stall_cycles;

reg [7:0] img [0:INPUT_PIXELS-1];

image_processing #(
    .IMAGE_WIDTH(IMAGE_WIDTH)
) dut (
    .clk(clk),
    .rst(rst),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tready(s_axis_tready),
    .m_axis_tdata(m_axis_tdata),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tready(m_axis_tready)
);

always #5 clk = ~clk;

integer ready_counter;

always @(negedge clk) begin
    if (rst) begin
        ready_counter <= 0;
        m_axis_tready <= 1;
    end
    else begin
        ready_counter <= ready_counter + 1;

        if (STALL_MODE == 0)
            m_axis_tready <= 1;
        else if (STALL_MODE == 1) begin
            if (ready_counter % 10 == 5)
                m_axis_tready <= 0;
            else
                m_axis_tready <= 1;
        end
        else begin
            if (($urandom % 100) < READY_PCT)
                m_axis_tready <= 1;
            else
                m_axis_tready <= 0;
        end
    end
end

initial begin
    #(INPUT_PIXELS * 500);
    $display("TIMEOUT: input_count=%0d output_count=%0d", input_count, output_count);
    $finish;
end

task check_output;
begin
    res = $fscanf(ex_file, "%d", expected);
    if (res != 1) begin
        $display("Expected output file ended early");
        $finish;
    end
    if (output_data_sampled !== expected) begin
        $display(
            "Output %0d: got %0d, expected %0d",
            output_count,
            output_data_sampled,
            expected
        );
        errors = errors + 1;
    end
    $fwrite(out_file, "%0d\n", output_data_sampled);
    output_count = output_count + 1;
end
endtask

task process_cycle;
begin
    if (prev_stalled) begin
        if (output_valid_sampled !== 1'b1) begin
            $display("%0t: PROTOCOL tvalid dropped during stall", $time);
            protocol_errors = protocol_errors + 1;
        end
        if (output_data_sampled !== prev_out_data) begin
            $display("%0t: PROTOCOL tdata changed during stall", $time);
            protocol_errors = protocol_errors + 1;
        end
    end
    if (output_valid_sampled === 1'bx || m_axis_tready === 1'bx) begin
        $display("%0t: X on tvalid or tready", $time);
        protocol_errors = protocol_errors + 1;
    end
    prev_stalled = (output_valid_sampled === 1'b1) && !output_ready_sampled;
    prev_out_data = output_data_sampled;
    if (prev_stalled)
        stall_cycles = stall_cycles + 1;

    if (output_transfer_sampled)
        check_output;

    if (input_transfer_sampled) begin
        if (input_data_sampled !== img[input_count]) begin
            $display(
                "Input %0d: dut accepted %0d, expected %0d",
                input_count,
                input_data_sampled,
                img[input_count]
            );
            input_errors = input_errors + 1;
        end
        input_count = input_count + 1;
    end
end
endtask

task drive_next_input;
begin
    if (loaded_count < INPUT_PIXELS && ($urandom % 100) < VALID_PCT) begin
        s_axis_tdata = img[loaded_count];
        s_axis_tvalid = 1;
        loaded_count = loaded_count + 1;
    end
    else
        s_axis_tvalid = 0;
end
endtask

integer i;

initial begin
    clk = 0;
    rst = 1;
    s_axis_tvalid = 0;
    s_axis_tdata = 0;
    m_axis_tready = 1;
    input_transfer_sampled = 0;
    input_data_sampled = 0;
    output_transfer_sampled = 0;
    output_data_sampled = 0;
    output_valid_sampled = 0;
    output_ready_sampled = 0;
    prev_stalled = 0;
    prev_out_data = 0;
    ready_counter = 0;
    errors = 0;
    protocol_errors = 0;
    input_errors = 0;
    input_count = 0;
    loaded_count = 0;
    output_count = 0;
    drain_cycles = 0;
    stall_cycles = 0;

    pix_file = $fopen("pixel.txt", "r");
    ex_file = $fopen("expected.txt", "r");
    out_file = $fopen("output.txt", "w");

    if (pix_file == 0 || ex_file == 0|| out_file == 0) begin
        $display("Error opening files");
        $finish;
    end

    for (i = 0; i < INPUT_PIXELS; i = i + 1) begin
        res = $fscanf(pix_file, "%d", pix);
        if (res != 1) begin
            $display("Input file ended early");
            $finish;
        end
        img[i] = pix;
    end

    #20;
    rst = 0;
    drive_next_input;

    while (input_count < INPUT_PIXELS) begin
        @(posedge clk);
        input_transfer_sampled = s_axis_tvalid && s_axis_tready;
        input_data_sampled = s_axis_tdata;
        output_transfer_sampled = m_axis_tvalid && m_axis_tready;
        output_data_sampled = m_axis_tdata;
        output_valid_sampled = m_axis_tvalid;
        output_ready_sampled = m_axis_tready;
        #1;
        process_cycle;
        if (input_transfer_sampled || !s_axis_tvalid)
            drive_next_input;
    end
//input pixel can still be in the pipeline so drain for a while
    while (output_count < OUTPUT_PIXELS && drain_cycles < 10000) begin
        @(posedge clk);
        input_transfer_sampled = 0;
        output_transfer_sampled = m_axis_tvalid && m_axis_tready;
        output_data_sampled = m_axis_tdata;
        output_valid_sampled = m_axis_tvalid;
        output_ready_sampled = m_axis_tready;
//added to ensure dut and tb produce expected values
        #1;
        process_cycle;
        drain_cycles = drain_cycles + 1;

    end

    $fclose(pix_file);
    $fclose(ex_file);
    $fclose(out_file);
    $display("Stall mode %0d, stalled cycles: %0d", STALL_MODE, stall_cycles);
    $display("Successful inputs:  %0d / %0d", input_count, INPUT_PIXELS);
    $display("Succesful Outputs: %0d / %0d", output_count, OUTPUT_PIXELS);
    $display("Errors:              %0d", errors);
    $display("Protocol errors:     %0d", protocol_errors);
    $display("Input errors:        %0d", input_errors);
    if (input_count != INPUT_PIXELS)
        $display("Wrong number of inputs sent!");
    else if (output_count != OUTPUT_PIXELS)
        $display("Wrong number of outputs sent!");
    else if (errors != 0 || protocol_errors != 0 || input_errors != 0)
        $display("There are some errors!");
    else
        $display("All outputs matched! lets go");
    $finish;
end
endmodule