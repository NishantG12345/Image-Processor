module image_processing_tb;

parameter IMAGE_WIDTH = 258;
parameter STALL_MODE = 2;
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
reg output_transfer_sampled;
reg [7:0] output_data_sampled;

integer pix;
integer expected;
integer pix_file;
integer ex_file;
integer out_file;
integer res;

integer errors;
integer input_count;
integer output_count;
integer drain_cycles;
integer ready_counter;

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
always @(negedge clk) begin
    if (rst) begin
        ready_counter <= 0;
        m_axis_tready <= 1;
    end
    else begin
        ready_counter <= ready_counter + 1;

        if (STALL_MODE == 0) begin
            m_axis_tready <= 1;
        end
        else if (STALL_MODE == 1) begin
            if (ready_counter % 10 == 5)
                m_axis_tready <= 0;
            else
                m_axis_tready <= 1;
        end
        else if (STALL_MODE == 2) begin
            if (ready_counter % 100 >= 50 && ready_counter % 100 < 55)
                m_axis_tready <= 0;
            else
                m_axis_tready <= 1;
        end
        else if (STALL_MODE == 3) begin
            if (($urandom % 100) < 75)
                m_axis_tready <= 1;
            else
                m_axis_tready <= 0;
        end
        else begin
            m_axis_tready <= 1;
        end
    end
end

initial begin
    clk = 0;
    rst = 1;
    s_axis_tvalid = 0;
    s_axis_tdata = 0;
    m_axis_tready = 1;

    input_transfer_sampled = 0;
    output_transfer_sampled = 0;
    output_data_sampled = 0;

    errors = 0;
    input_count = 0;
    output_count = 0;
    drain_cycles = 0;
    ready_counter = 0;

    pix_file = $fopen("pixel.txt", "r");
    ex_file = $fopen("expected.txt", "r");
    out_file = $fopen("output.txt", "w");
    if (pix_file == 0 || ex_file == 0 || out_file == 0) begin
        $display("Error opening files");
        $finish;
    end
    #20;
    rst = 0;
    res = $fscanf(pix_file, "%d", pix);
    if (res == 1) begin
        s_axis_tdata = pix;
        s_axis_tvalid = 1;
    end
//MAJOR CHANGE:
//POSEDGE HAS An ACTIVE REGION AND NBA REGION
//AT FIRST DURING ACTIVE REGION RHS IS CALCULATED AND SCHEDULED TO CHANGE//THEN THE NBA REGION THE VALUES ARE UPDATED
//THEN BACK TO ACTIVE REGION WHERE ANY ASSIGNS OR ANYTHING ELSE UPDATED//SINCE WE WAITED #1 previosly it ASSIGNED OUR S_AXIS and M_AXIS TO NEW VALUES
    while (input_count < INPUT_PIXELS) begin
        @(posedge clk);
        input_transfer_sampled = s_axis_tvalid && s_axis_tready;
        output_transfer_sampled = m_axis_tvalid && m_axis_tready;
        output_data_sampled = m_axis_tdata;
        #1;
        if (output_transfer_sampled) begin
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
        if (input_transfer_sampled) begin
            input_count = input_count + 1;
            if (input_count < INPUT_PIXELS) begin
                res = $fscanf(pix_file, "%d", pix);
                if (res != 1) begin
                    $display("Input file ended early");
                    $finish;
                end
                s_axis_tdata = pix;
            end
            else begin
                s_axis_tvalid = 0;
            end
        end
    end

//input pixel can still be in the pipeline so drain for a while
    while (output_count < OUTPUT_PIXELS && drain_cycles < 10000) begin
        @(posedge clk);
        output_transfer_sampled = m_axis_tvalid && m_axis_tready;
        output_data_sampled = m_axis_tdata;

//added to ensure dut and tb produce expected values
        #1;
        if (output_transfer_sampled) begin
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
        drain_cycles = drain_cycles + 1;

    end

    $fclose(pix_file);
    $fclose(ex_file);
    $fclose(out_file);

    $display("Stall mode:           %0d", STALL_MODE);
    $display("Successful inputs:  %0d / %0d", input_count, INPUT_PIXELS);
    $display("Succesful Outputs: %0d / %0d", output_count, OUTPUT_PIXELS);
    $display("Errors:              %0d", errors);

    if (input_count != INPUT_PIXELS)
        $display("Wrong number of inputs sent!");
    else if (output_count != OUTPUT_PIXELS)
        $display("Wrong number of outputs sent!");
    else if (errors != 0)
        $display("There are some errors!");
    else
        $display("All outputs matched! lets go");
    $finish;
end
endmodule