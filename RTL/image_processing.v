module image_processing#(
    parameter IMAGE_WIDTH = 258
)(
    input clk,
    input s_axis_tvalid,
    input [7:0] s_axis_tdata,
    input m_axis_tready,
    input rst,
    output s_axis_tready,
    output [7:0] m_axis_tdata, 
    output m_axis_tvalid
);
wire [7:0] prev_prev_row;
wire [7:0] prev_row; 
wire [7:0] curr_row;
wire [7:0] pixel00, pixel01,pixel02;
wire [7:0] pixel10, pixel11,pixel12;
wire [7:0] pixel20, pixel21,pixel22;
wire linebuffer_valid;
wire window_valid;
wire input_transfer; 
wire output_tranfser; 
wire enable_pipeline; 

assign input_transfer = s_axis_tvalid && s_axis_tready; 
//when both are 1 a transfer can be made
//the reason why the pipeline can be enabled at 0 0 is 
//because you can keep the pipeline alive until you get a valid data at the final stage
//once thats valid but still not ready then you freeze the pipeline
assign output_tranfser = m_axis_tvalid && m_axis_tready; 
assign enable_pipeline = !m_axis_tvalid || m_axis_tready;
assign s_axis_tready = enable_pipeline;   
linebuffer
    #(
    .IMAGE_WIDTH(IMAGE_WIDTH)
    ) image_linebuffer(
    .clk(clk), 
    .rst(rst), 
    .enable(enable_pipeline),
    .valid(input_transfer), //did pixel arrive
    .pixel_in(s_axis_tdata),
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
    .enable(enable_pipeline),
    .pixel00(pixel00),
    .pixel01(pixel01),
    .pixel02(pixel02),
    .pixel10(pixel10),
    .pixel11(pixel11),
    .pixel12(pixel12),
    .pixel20(pixel20),
    .pixel21(pixel21),
    .pixel22(pixel22),
    .valid_out(window_valid)
);
computation image_computation(
    .valid_in(window_valid),
    .pixel00(pixel00),
    .pixel01(pixel01),
    .pixel02(pixel02),
    .pixel10(pixel10),
    .pixel11(pixel11),
    .pixel12(pixel12),
    .pixel20(pixel20),
    .pixel21(pixel21),
    .rst(rst),
    .pixel22(pixel22),
    .pixel_out(m_axis_tdata),
    .enable(enable_pipeline),
    .clk(clk),
    .valid_out(m_axis_tvalid)
);
endmodule
