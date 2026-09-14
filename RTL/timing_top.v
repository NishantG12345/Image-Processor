module timing_top (
    input  wire       clk,
    input  wire       rst,
    input  wire       valid,
    input  wire [7:0] pixel_in,
    output wire [7:0] pixel_out,
    output wire       valid_out
);

    image_processing dut (
        .clk(clk),
        .rst(rst),
        .valid(valid),
        .pixel_in(pixel_in),
        .pixel_out(pixel_out),
        .valid_out(valid_out)
    );

endmodule