module computation
    (
    input valid_out,
    input  [7:0] pixel00,pixel01,pixel02,
    input  [7:0] pixel10,pixel11,pixel12, 
    input  [7:0] pixel20,pixel21,pixel22,
    output reg [7:0] pixel_out 
);
//sobel range is -1020 to 1020 and we want to truncate between 0 and 255 
reg signed[10:0] wide_pixel;
reg signed[10:0] p00;
reg signed[10:0] p01;
reg signed[10:0] p02;
reg signed[10:0] p20;
reg signed[10:0] p21;
reg signed[10:0] p22;

always @(*) begin
    //to ensure proper signed operations must convert to signed reg first
    if(valid_out) begin
        //pad with 3 0s because max value for a sobel 3x3 with pixels from 0-255 can be 1020
        //this requires 11 bits
        p00 = {3'b000,pixel00};
        p01 = {3'b000,pixel01};
        p02 = {3'b000,pixel02};
        p20 = {3'b000,pixel20};
        p21 = {3'b000,pixel21};
        p22 = {3'b000,pixel22};
        wide_pixel = -p00 - (p01 << 1) - p02  +  p20 + (p21 << 1) + p22;
        if (wide_pixel < 0)
        wide_pixel = -wide_pixel;
        if (wide_pixel > 255) begin
        wide_pixel = 255;
        end
        pixel_out = wide_pixel;
    end
    else
    pixel_out = 0;


end
endmodule