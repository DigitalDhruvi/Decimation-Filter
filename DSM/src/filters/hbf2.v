/* FIR filter implementation on FPGA
 * Module: 6th Order Halfband Filter 
 * Description:
 * This module implements the structure of the second stage filter in our chain using coefficients generated in MATLAB
 * Cuttoff frequency of 2 MHz, with 25.5 dB stopband attenuation and 0.00251 dB ripple in the passband
 * The input signal is the output of first halfband filter generated in the form of a text file
 *
 * Engineer: Dhruvi A
 * Date: 30/12/25
 */

module hbf2 (
    input clk,
    input rst,
    input signed [32:0] in,
    input valid_in,   // = CIC out_valid (fs/32 rate)
    output reg signed [32:0] out,
    output reg valid_out   // fs/64 rate (decimate by 2)
);
parameter SIZE = 15;

// Half-band coefficients (Q1.15)
localparam signed [SIZE:0] b0_fixed = -16'sd2761;
localparam signed [SIZE:0] b2_fixed = 16'sd10053;
localparam signed [SIZE:0] b3_fixed = 16'sd16384;

// Delay registers for input (Q1.15 domain)
reg signed [32:0] input_x;
reg signed [32:0] z1, z2, z3, z4, z5, z6;

// For decimation by 2 
reg sample;

// Products (input is effectively truncated to Q1.15)
wire signed [50:0] prod_b0_b6 = (input_x+ z6) * b0_fixed;
wire signed [50:0] prod_b2_b4 = (z2 + z4) * b2_fixed;
wire signed [50:0] prod_b3 = z3 * b3_fixed;

reg signed [52:0] sum; 

always @(posedge clk) begin
    if (rst) begin
        input_x <= 0;
        z1 <= 0; z2 <= 0; z3 <= 0; z4 <= 0; z5 <= 0; z6 <= 0; 
        out <= 0;
        valid_out <= 0;
        sample <= 0;
        sum <= 0;
    end
    else if (valid_in) begin
        // Shift delay line at fs/32 
        input_x <= in;       
        z1 <= input_x;
        z2 <= z1;
        z3 <= z2;
        z4 <= z3;
        z5 <= z4;
        z6 <= z5;
        sum = prod_b0_b6 + prod_b2_b4 + prod_b3;
        // Decimate by 2: output on every second valid_in
        if (sample) begin
            // scale back from Q(1+15+log2(11)) to match 33-bit data
            out <= sum >>> 15;   // adjust shift if needed
            valid_out <= 1;
        end
        else begin
            valid_out <= 0;
        end
        sample <= ~sample;
    end
     else begin
        valid_out <= 0;
    end
end

endmodule
