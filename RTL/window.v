module window#(
    IMAGE_WIDTH = 258
    )(
    input clk, 
    input reset,
    input valid_in,
    input [7:0] prev_prev_row,
    input [7:0] prev_row, 
    input [7:0] current_row,
    output [7:0] reg pixel00, pixel01,pixel02,
    output [7:0] reg pixel10, pixel11,pixel12,
    output [7:0] reg pixel20, pixel21,pixel22,
    output valid_out
)
    reg [7:0] shift_row1 [0:1];
    reg [7:0] shift_row2 [0:1];
    reg [7:0] shift_row3 [0:1];
    reg [8:0] row_count; 
    reg [8:0] col_count;
    always @(posedge clk) begin
        if(reset) begin
        shift_row1[1] <= 0; shift_row1[0] <= 0;
        shift_row2[1] <= 0; shift_row2[0] <= 0;
        shift_row3[1] <= 0; shift_row3[0] <= 0;
        valid_out <= 0; 
        row_count <= 0; col_count <= 0;
        pixel00 <= 0; pixel01 <=0; pixel02 <= 0;
        pixel10 <= 0; pixel11 <=0; pixel12 <= 0;
        pixel20 <= 0; pixel21 <=0; pixel22 <= 0;
        end
        else if(valid_in) begin
            if (col_count == IMAGE_WIDTH-1) begin
                col_count <= 0; 
                row_count <= row_count+1;
            end
            else begin
                col_count <= col_count+1;
            end
            shift_row1[1] <= shift_row1[0];
            shift_row2[1] <= shift_row2[0];
            shift_row3[1] <= shift_row3[0];

            shift_row1[0] <= prev_prev_row; 
            shift_row2[0] <= prev_row;
            shift_row3[0] <= current_row;
            pixel00 <= shift_row1[1];
            pixel01 <= shift_row1[0];
            pixel02 <= prev_prev_row;

            pixel10 <= shift_row2[1];
            pixel11 <= shift_row2[0];
            pixel12 <= prev_row;

            pixel20 <= shift_row3[1];
            pixel21 <= shift_row3[0];
            pixel22 <= current_row;
            if(row_count >= 2 && col_count >= 2) begin
                valid_out<=1;
            end
            else
                valid_out<=0;
        end
        else begin
        valid_out <= 0; 
        end
    end

endmodule