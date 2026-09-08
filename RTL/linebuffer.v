    module linebuffer #(
        IMAGE_WIDTH = 256
    ) 
        (
        input clk, 
        input rst,
        input valid, 
        input ready,
        input [7:0] pixel_in;
        output reg [7:0] linebuffer_1 [0:IMAGE_WIDTH-1],
        output reg [7:0] linebuffer_2 [0:IMAGE_WIDTH-1]
    );
        localparam ADDR_WIDTH = $clog2(IMAGE_WIDTH);
        reg [ADDR_WIDTH-1:0] write_ptr;
        always @(posedge clk) begin
            if(rst) begin
                linebuffer_1 <= 0;
                linebuffer_2 <= 0;
            end
            else if(valid && ready) begin
            linebuffer_1[write_ptr] <= pixel_in;
            linebuffer_2[write_ptr] <= linebuffer_1[write_ptr];
            write_ptr1 <= write_ptr1 + 1; 
            end
        end
    endmodule

    //what happens when we reach the next row 