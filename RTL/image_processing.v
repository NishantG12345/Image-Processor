module image_processing#(
    parameter IMAGE_WIDTH = 258
)(
    input clk,
    input valid,
    input rst,
    input [7:0] pixel_in,
    output [7:0] pixel_out
);
wire [7:0] prev_prev_row;
wire [7:0] prev_row; 
wire [7:0] curr_row;
wire [7:0] pixel00, pixel01,pixel02;
wire [7:0] pixel10, pixel11,pixel12;
wire [7:0] pixel20, pixel21,pixel22;
wire linebuffer_valid;
wire valid_out;
linebuffer
    #(
    .IMAGE_WIDTH(IMAGE_WIDTH)
    ) image_linebuffer(
    .clk(clk), 
    .rst(rst), 
    .valid(valid), 
    .pixel_in(pixel_in),
    .prev_prev_row(prev_prev_row),
    .prev_row(prev_row),
    .curr_row(curr_row),
    .valid_out(linebuffer_valid)    
    );
window #(
    .IMAGE_WIDTH(IMAGE_WIDTH)
) image_window(
    .clk(clk),
    .reset(rst),
    .valid_in(linebuffer_valid),
    .prev_prev_row(prev_prev_row),
    .prev_row(prev_row),
    .current_row(curr_row),
    .pixel00(pixel00),
    .pixel01(pixel01),
    .pixel02(pixel02),
    .pixel10(pixel10),
    .pixel11(pixel11),
    .pixel12(pixel12),
    .pixel20(pixel20),
    .pixel21(pixel21),
    .pixel22(pixel22),
    .valid_out(valid_out)
);
computation image_computation(
    .valid_out(valid_out),
    .pixel00(pixel00),
    .pixel01(pixel01),
    .pixel02(pixel02),
    .pixel10(pixel10),
    .pixel11(pixel11),
    .pixel12(pixel12),
    .pixel20(pixel20),
    .pixel21(pixel21),
    .pixel22(pixel22),
    .pixel_out(pixel_out)
);
endmodule
