/* FIR filter implementation on FPGA
 * Module: first cascaded integrator comb section
 * Description:
 * This module implements the the behaviour of the first stage (sinc filter) in our chain 
 * Cuttoff frequency of 2 MHz, with 40 dB stopband attenuation and 0.00135 dB ripple in the passband
 * The input signal is the output of Delta Sigma Modulator from MATLAB provided in the form of a text file
 *
 * Engineer: Dhruvi A
 * Date: 30/12/25
 */

module cic (
    input signed [1:0] in,
    input rst,
    input clk,
    output reg signed [32:0] out,
    output reg out_valid
);
 parameter SIZE = 32;
// Integrator stages  
reg signed [SIZE:0] int1, int2, int3, int4, int5;

// Comb stages
reg signed [SIZE:0] comb1, comb2, comb3, comb4, comb5;

// Delay lines (M=2)
reg signed [SIZE:0] comb1_delay0;
reg signed [SIZE:0] comb2_delay0;
reg signed [SIZE:0] comb3_delay0;
reg signed [SIZE:0] comb4_delay0;
reg signed [SIZE:0] comb5_delay0;
reg signed [SIZE:0] comb1_delay1;
reg signed [SIZE:0] comb2_delay1;
reg signed [SIZE:0] comb3_delay1;
reg signed [SIZE:0] comb4_delay1;
reg signed [SIZE:0] comb5_delay1;
reg [7:0] d_count;

parameter DECIMATION_FACTOR = 32;
integer i;
reg decimate_tick;

always @(posedge clk) begin
    if (rst) begin
        // Reset all integrators
        int1 <= 0; int2 <= 0; int3 <= 0; int4 <= 0; int5 <= 0;
        
        // Reset all combs
        comb1 <= 0; comb2 <= 0; comb3 <= 0; comb4 <= 0; comb5 <= 0;
        
        // Reset decimation
        d_count <= 0; decimate_tick <= 0;
        
        // Reset outputs
        out <= 0; out_valid <= 0;
        
        //Delay registers
        comb1_delay0 <= 0; comb1_delay1 <= 0;
        comb2_delay0 <= 0; comb2_delay1 <= 0;
        comb3_delay0 <= 0; comb3_delay1 <= 0;
        comb4_delay0 <= 0; comb4_delay1 <= 0;
        comb5_delay0 <= 0; comb5_delay1 <= 0;
    end 
    else begin
        // INTEGRATOR
        int1 <= int1 + in;
        int2 <= int2 + int1;
        int3 <= int3 + int2;
        int4 <= int4 + int3;
        int5 <= int5 + int4;
        
        if (d_count==DECIMATION_FACTOR-1) begin
                d_count <= 0;
                decimate_tick<=1;
        end else begin
                d_count <= d_count + 1;
                decimate_tick<=0;
        end
       
        // COMB SECTION
        if (decimate_tick) begin
            comb1 <= int5 - comb1_delay1;
            comb1_delay1 <= comb1_delay0;
            comb1_delay0 <= int5;
            
            comb2 <= comb1 - comb2_delay1;
            comb2_delay1 <= comb2_delay0;
            comb2_delay0 <= comb1;
            
            comb3 <= comb2 - comb3_delay1;
            comb3_delay1 <= comb3_delay0;
            comb3_delay0 <= comb2;
            
            comb4 <= comb3 - comb4_delay1;
            comb4_delay1 <= comb4_delay0;
            comb4_delay0 <= comb3;
            
            comb5 <= comb4 - comb5_delay1;
            comb5_delay1 <= comb5_delay0;
            comb5_delay0 <= comb4;
            
            out <= comb5;
            out_valid <= 1;
        end 
        else begin
            out_valid <= 0;
        end
    end
end
endmodule
