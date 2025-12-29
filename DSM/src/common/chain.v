/* FIR filter implementation on FPGA
 * Module: Decimation Chain: CIC -> HBF1 -> HBF2 = 128x total decimation
 * Description:
 * Combines all three modules cic.v hbf1.v hbf2.v
 * Engineer: Dhruvi A
 * Date: 30/12/25
 */

module chain (
    input clk,
    input rst,
    input  signed [1:0] data_in,
    output signed [32:0] data_out,
    output valid_out
);

    // Intermediate signals between stages
    wire signed [32:0] cic_out;
    wire cic_valid;
    
    wire signed [32:0] hbf1_out;
    wire hbf1_valid;

    // === STAGE 1: CIC Decimator (x32) ===
    cic cic_inst (
        .in(data_in),
        .rst(rst),
        .clk(clk),
        .out(cic_out),
        .out_valid(cic_valid)
    );

    // === STAGE 2: HBF1 Halfband Decimator (x2) ===
    hbf1 hbf1_inst (
        .clk(clk),
        .rst(rst),
        .in(cic_out),
        .valid_in(cic_valid),
        .out(hbf1_out),
        .valid_out(hbf1_valid)
    );

    // === STAGE 3: HBF2 Halfband Decimator (x2) ===
    hbf2 hbf2_inst (
        .clk(clk),
        .rst(rst),
        .in(hbf1_out),
        .valid_in(hbf1_valid),
        .out(data_out),
        .valid_out(valid_out)
    );

endmodule
