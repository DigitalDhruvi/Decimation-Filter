`timescale 1ns / 1ps

module tb_hbf1;

reg clk, rst;
reg signed [32:0] in;
reg valid_in;
wire signed [32:0] out;
wire valid_out;

integer input_file, output_file;
reg signed [32:0] input_data [0:4096];
integer total_samples, output_count;
integer i;

// 8 MHz clock (period 125 ns)
always #62.5 clk = ~clk;

hbf1 uut (
    .clk(clk),
    .rst(rst),
    .in(in),
    .valid_in(valid_in),
    .out(out),
    .valid_out(valid_out)
);

initial begin
    clk = 0;
    rst = 1;
    in = 0;
    valid_in = 0;
    total_samples = 0;
    output_count = 0;

    input_file = $fopen("cic_output.txt", "r");
    output_file = $fopen("hbf1_output.txt", "w");

    if (input_file == 0) begin
        $display("ERROR: Could not open cic_output.txt");
        $finish;
    end

    // Load input data
    while (!$feof(input_file)) begin
        if ($fscanf(input_file, "%d", input_data[total_samples]) == 1)
            total_samples = total_samples + 1;
    end
    $fclose(input_file);

    $display("Loaded %0d samples", total_samples);

    // Release reset
    #200 rst = 0;
    @(posedge clk);

    // Apply input samples (one per valid_in)
    for (i = 0; i < total_samples; i++) begin
        @(negedge clk);
        in = input_data[i]; // use full 33 bits
        valid_in = 1;

        @(posedge clk);
        #1;

        if (i < 10)
        $display("Input[%0d]: %0d", i, $signed(in));
    end

    // Stop providing inputs
    @(negedge clk);
    valid_in = 0;
    in = 0;

    // Let pipeline drain for a while (no new inputs)
    repeat(100) @(posedge clk);

    $fclose(output_file);

    $display("Input samples:  %0d", total_samples);
    $display("Output samples: %0d (expected ~%0d)", output_count, total_samples/2);
    if (output_count != 0)
        $display("Decimation ratio: %0d", total_samples/output_count);
    $finish;
end

// Capture outputs
initial begin
    @(negedge rst);
    forever begin
        @(posedge clk);
        if (valid_out) begin
            $fwrite(output_file, "%0d\n", out);
            output_count++;

            if (output_count <= 10)
                $display("Output[%0d]: %0d", output_count-1,$signed (out));
        end
    end
end

initial begin
    $dumpfile("tb_hbf1.vcd");
    $dumpvars(0, tb_hbf1);
end

endmodule
