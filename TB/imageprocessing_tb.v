module image_processing_tb;

reg clk; 
reg valid;
reg rst; 
reg [7:0] pixel_in;
wire [7:0] pixel_out;
wire valid_out;
integer pix; 
integer expected;
integer pix_file; 
integer ex_file; 
integer errors; 
integer count;
integer res; 
integer drain_cycles;
integer out_file; 

image_processing dut(
    .clk(clk),
    .valid(valid),
    .rst(rst),
    .pixel_in(pixel_in),
    .pixel_out(pixel_out),
    .valid_out(valid_out)
); 

always #5 clk = ~clk;

initial begin
    clk = 0;
    valid = 0; 
    pixel_in = 0; 
    rst = 1;
    errors = 0; 
    count = 0; 

    #20 rst = 0;

    pix_file = $fopen("pixel.txt", "r");
    ex_file = $fopen("expected.txt", "r");
    out_file = $fopen("output.txt", "w");

    if(pix_file == 0 || ex_file == 0) begin
        $display("issue loading files");
        $finish;
    end
    
    res = $fscanf(pix_file, "%d", pix);
    pixel_in = pix;
    valid = 1;

    repeat(66564) begin

    @(posedge clk); 
    #1
    if(valid_out) begin 
        res = $fscanf(ex_file, "%d", expected); 
        count = count + 1;
        $fwrite(out_file, "%0d\n", pixel_out);
        if(pixel_out !== expected) begin
            $display("Pixel out(%0d) did NOT match expected(%0d)", pixel_out, expected);
            errors = errors + 1; 
        end
    end
    res = $fscanf(pix_file, "%d", pix);
    pixel_in = pix;
    end
    valid = 0;


    drain_cycles = 0;

    while (count < 65536 && drain_cycles < 200) begin
        @(posedge clk);
        #1;
        if(valid_out) begin 
            res = $fscanf(ex_file, "%d", expected); 
            count = count + 1;
            $fwrite(out_file, "%0d\n", pixel_out);
            if(pixel_out !== expected) begin
                $display("Pixel out(%0d) did NOT match expected(%0d)", pixel_out, expected);
                errors = errors + 1; 
            end
        end
        drain_cycles = drain_cycles + 1;
    end

    $fclose(pix_file);
    $fclose(ex_file);
    $fclose(out_file);
    if(errors > 0) begin
        $display("you did NOT pass all cases");
    end
    else
        $display("CONGRATS YOU PASSED");
    if(count != 65536)
    $display("Incorrect number of output pixels :%0d", count);
    else  
    $display("All good");
    $finish;
end
endmodule
