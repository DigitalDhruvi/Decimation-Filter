`timescale 1ns / 1fs
/* FIR filter implementation on FPGA
 * Module: common testbench for the combined filter
 * Description:
 * The input signal is the output of Delta Sigma Modulator from MATLAB provided in the form of a text file
 *
 * Engineer: Dhruvi A
 * Date: 30/12/25
 */

module tb_chain;

    // Clock, reset
    reg clk;
    reg rst;

    // DSM input to CIC
    reg  signed [1:0] dsm_in;

    // CIC output
    wire signed [32:0] cic_out;
    wire cic_valid;

    // HBF1 output
    wire signed [32:0] hbf1_out;
    wire hbf1_valid;

    // HBF2 output (final)
    wire signed [32:0] hbf2_out;
    wire hbf2_valid;

    // File I/O
    integer input_file, output_file;
    integer total_samples, output_count;
    integer i;

    // Input data 
    reg signed [31:0] input_data [0:200000];

    // 256 MHz clock: period 3.90625 ns so half-period 1.953125 ns
    always #1.953125 clk = ~clk;

    // Instantiate CIC (FIR)
    cic #(.SIZE(32)) cic_inst (
        .in(dsm_in),
        .rst(rst),
        .clk(clk),
        .out(cic_out),
        .out_valid(cic_valid)
    );

    // Instantiate HBF1
    hbf1 hbf1_inst (
        .clk(clk),
        .rst(rst),
        .in(cic_out),
        .valid_in(cic_valid),
        .out(hbf1_out),
        .valid_out(hbf1_valid)
    );

    // Instantiate HBF2
    hbf2 hbf2_inst (
        .clk(clk),
        .rst(rst),
        .in(hbf1_out),
        .valid_in(hbf1_valid),
        .out(hbf2_out),
        .valid_out(hbf2_valid)
    );

    // Stimulus and file handling
    initial begin
        clk = 0;
        rst = 1;
        dsm_in = 0;
        total_samples = 0;
        output_count = 0;

        // Open DSM output file from MATLAB
        input_file = $fopen("dsm_output.txt", "r");
        if (input_file == 0) begin
            $display("ERROR: Could not open dsm_output.txt");
            $finish;
        end

        // Read all DSM samples into memory
        while (!$feof(input_file)) begin
            if ($fscanf(input_file, "%d", input_data[total_samples]) == 1)
                total_samples = total_samples + 1;
        end
        $fclose(input_file);

        $display("Loaded %0d DSM samples", total_samples);

        // Open final output file
        output_file = $fopen("chain_output.txt", "w");
        if (output_file == 0) begin
            $display("ERROR: Could not open chain_output.txt");
            $finish;
        end

        // Release reset
        #50 rst = 0;
        @(posedge clk);

        // Feed DSM samples into CIC
        for (i = 0; i < total_samples; i++) begin
            @(negedge clk);
            dsm_in = input_data[i][1:0];   // DSM output is 2-bit signed

            @(posedge clk);
            // no direct write here; write only when hbf2_valid later
        end

        // After all inputs, stop driving and let pipeline drain
        @(negedge clk);
        dsm_in = 0;

        repeat (500) @(posedge clk);   // allow filters to flush

        $fclose(output_file);

        $display("Input DSM samples:  %0d", total_samples);
        $display("Final output samples (HBF2): %0d", output_count);

        $finish;
    end

    // Capture final chain output whenever HBF2 asserts valid_out
    initial begin
        @(negedge rst);          // wait for reset deassert
        forever begin
            @(posedge clk);
            if (hbf2_valid) begin
                $fwrite(output_file, "%0d\n", $signed(hbf2_out));
                output_count++;

                if (output_count <= 10)
                    $display("chain_out[%0d] = %0d", output_count-1, $signed(hbf2_out));
            end
        end
    end

    // Waveform dump
    initial begin
        $dumpfile("tb_chain.vcd");
        $dumpvars(0, tb_chain);
    end

endmodule
