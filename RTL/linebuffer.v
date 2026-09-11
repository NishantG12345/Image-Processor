    module linebuffer #(
    parameter IMAGE_WIDTH = 258
    ) 
        (
        input clk, 
        input rst,
        input valid, 
        input [7:0] pixel_in,  
        output reg [7:0] prev_prev_row,
        output reg [7:0] prev_row, 
        output reg [7:0] curr_row,
        output reg valid_out
    );
        reg [7:0] linebuffer_1 [0:IMAGE_WIDTH-1];
        reg [7:0] linebuffer_2 [0:IMAGE_WIDTH-1];
        localparam ADDR_WIDTH = $clog2(IMAGE_WIDTH);
        reg [ADDR_WIDTH-1:0] write_ptr;
        always @(posedge clk) begin
            if(rst) begin
                write_ptr<=0;
                valid_out<=0;
                //dont reset linebuffer you can just overwrite it
            end
            else if(valid) begin
            linebuffer_1[write_ptr] <= pixel_in;
            linebuffer_2[write_ptr] <= linebuffer_1[write_ptr];
            if(write_ptr == IMAGE_WIDTH - 1) 
            write_ptr <= 0;
            else 
            write_ptr <= write_ptr + 1; 
            prev_prev_row <= linebuffer_2[write_ptr];
            prev_row <= linebuffer_1[write_ptr];
            curr_row <= pixel_in;
            valid_out <=1;
            end
           
        end
    endmodule

