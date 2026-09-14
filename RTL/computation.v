module computation
    (
    input valid_in,
    input  [7:0] pixel00,pixel01,pixel02,
    input  [7:0] pixel10,pixel11,pixel12, 
    input  [7:0] pixel20,pixel21,pixel22,
    input clk,
    output reg [7:0] pixel_out,
    output reg valid_out
);
//sobel range is -1020 to 1020 and we want to truncate between 0 and 255 
wire signed[10:0] p00;
wire signed[10:0] p01;
wire signed[10:0] p02;
wire signed[10:0] p20;
wire signed[10:0] p21;
wire signed[10:0] p22;

wire signed[10:0] top;
wire signed[10:0] bottom;

reg signed [10:0] wide_pixel;
reg [10:0] abs_pixel;

reg valid1, valid2;
//pad with 3 0s because max value for a sobel 3x3 with pixels from 0-255 can be 1020
//this requires 11 bits
assign p00 = {3'b000,pixel00};
assign p01 = {3'b000,pixel01};
assign p02 = {3'b000,pixel02};
assign p20 = {3'b000,pixel20};
assign p21 = {3'b000,pixel21};
assign p22 = {3'b000,pixel22};

assign top = -p00 - (p01 << 1) - p02;
assign bottom =  p20 + (p21 << 1) + p22;

always @(posedge clk) begin
        
        wide_pixel <= top + bottom;
        valid1 <= valid_in;
  
        abs_pixel <= wide_pixel[10] ? (~wide_pixel + 11'd1) : wide_pixel;
        valid2 <= valid1;
     
       if (valid2) begin
            if (abs_pixel > 255)
                pixel_out <= 8'd255;   
            else
                pixel_out <= abs_pixel;
        end
        else begin
            pixel_out <= 8'd0;             
        end
        valid_out <= valid2;
    end
endmodule