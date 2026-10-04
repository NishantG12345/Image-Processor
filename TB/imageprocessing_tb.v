module image_processing_tb;

parameter IMAGE_WIDTH = 258;
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
initial begin
    clk = 0;
    rst = 1;
    s_axis_tvalid = 0;
    s_axis_tdata = 0;
    m_axis_tready = 1;
    errors = 0;
    input_count = 0;
    output_count = 0;
    drain_cycles = 0;

    pix_file = $fopen("pixel.txt", "r");
    ex_file = $fopen("expected.txt", "r");
    out_file = $fopen("output.txt", "w");

    if (pix_file == 0 || ex_file == 0|| out_file == 0) begin
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

    while (input_count < INPUT_PIXELS) begin
        @(posedge clk);
        #1;
        if (m_axis_tvalid && m_axis_tready) begin
            res = $fscanf(ex_file, "%d", expected);
            if (res != 1) begin
                $display("Expected output file ended early");
                $finish;
            end
            if (m_axis_tdata !== expected) begin
                $display(
                    "Output %0d: got %0d, expected %0d",
                    output_count,
                    m_axis_tdata,
                    expected
                );
                errors = errors + 1;
            end
            $fwrite(out_file, "%0d\n", m_axis_tdata);
            output_count = output_count + 1;
        end
        if (s_axis_tvalid && s_axis_tready) begin
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
    while (output_count < OUTPUT_PIXELS && drain_cycles < 1000) begin
        @(posedge clk);
        #1;
        if (m_axis_tvalid && m_axis_tready) begin
            res = $fscanf(ex_file, "%d", expected);
            if (res != 1) begin
                $display("Expected output file ended early");
                $finish;
            end

            if (m_axis_tdata !== expected) begin
                $display(
                    "Output %0d: got %0d, expected %0d",
                    output_count,
                    m_axis_tdata,
                    expected
                );
                errors = errors + 1;
            end

            $fwrite(out_file, "%0d\n", m_axis_tdata);
            output_count = output_count + 1;

        end
        drain_cycles = drain_cycles + 1;

    end

    $fclose(pix_file);
    $fclose(ex_file);
    $fclose(out_file);
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