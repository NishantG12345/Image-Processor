module window#(
    parameter IMAGE_WIDTH = 258
    )(
    input clk, 
    input reset,
    input valid_in,
    input [7:0] prev_prev_row,
    input [7:0] prev_row, 
    input [7:0] current_row,
    output reg [7:0]  pixel00, pixel01,pixel02,
    output reg [7:0]  pixel10, pixel11,pixel12,
    output reg [7:0]  pixel20, pixel21,pixel22,
    output reg valid_out
);
    reg [7:0] row1_d1, row1_d2;
    reg [7:0] row2_d1, row2_d2;
    reg [7:0] row3_d1, row3_d2;
    reg [8:0] row_count; 
    reg [8:0] col_count;
    
    always @(posedge clk) begin
        if(reset) begin
            row1_d1 <= 0;
            row1_d2 <= 0;

            row2_d1 <= 0;
            row2_d2 <= 0;

            row3_d1 <= 0;
            row3_d2 <= 0;

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
            row1_d2 <= row1_d1;
            row1_d1 <= prev_prev_row;

            row2_d2 <= row2_d1;
            row2_d1 <= prev_row;

            row3_d2 <= row3_d1;
            row3_d1 <= current_row;

            pixel00 <= row1_d2;
            pixel01 <= row1_d1;
            pixel02 <= prev_prev_row;

            pixel10 <= row2_d2;
            pixel11 <= row2_d1;
            pixel12 <= prev_row;

            pixel20 <= row3_d2;
            pixel21 <= row3_d1;
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