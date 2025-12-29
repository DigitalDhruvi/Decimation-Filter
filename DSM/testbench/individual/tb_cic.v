`timescale 1ns / 1ps

module tb_cic;

reg signed [1:0] in;
reg rst, clk;
wire signed [32:0] out;
wire out_valid;

integer input_file, output_file;
integer output_count;
reg [32:0] input_data [0:200000];
integer total_samples;
integer i;

always #1.953125 clk = ~clk;

cic #(.SIZE(32)) uut(
    .in(in), 
    .rst(rst), 
    .clk(clk), 
    .out(out), 
    .out_valid(out_valid)
);

initial begin
    clk = 0; 
    rst = 1; 
    in = 0;
    output_count = 0;
    total_samples = 0;
    
    input_file = $fopen("dsm_output.txt", "r");
    if (input_file == 0) begin
        $display("ERROR: Could not open dsm_output.txt");
        $finish;
    end
    
    while (!$feof(input_file)) begin
        if ($fscanf(input_file, "%d", input_data[total_samples]) == 1) begin
            total_samples = total_samples + 1;
        end
    end
    $fclose(input_file);
    
    output_file = $fopen("cic_output.txt", "w");
    
    #20 rst = 0;
    @(posedge clk);
    
    for (i = 0; i < total_samples; i++) begin
        @(negedge clk);
        in = input_data[i];
        
        @(posedge clk);
        #0.1;
        if(out_valid==1) begin
            $fwrite(output_file, "%d\n", $signed(out));
            output_count++;
            $display("d_count=%0d", output_count);
        end
    end
    
    $fclose(output_file);
    $display("Done! Processed %0d samples", output_count);
    $finish;
end

initial begin
    $dumpfile("tb_cic.vcd");
    $dumpvars(0, tb_cic);
end

endmodule 