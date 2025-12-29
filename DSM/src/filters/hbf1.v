module hbf1 (
    input clk,
    input rst,
    input signed [32:0] in,
    input valid_in,
    output reg signed [32:0] out,
    output reg valid_out
);

parameter SIZE = 15;

// Half-band coefficients Q1.15
localparam signed [SIZE:0] b0 = 16'sd991;
localparam signed [SIZE:0] b2 = -16'sd2642;
localparam signed [SIZE:0] b4 = 16'sd10127;
localparam signed [SIZE:0] b5 = 16'sd16384;

// Delay line: full 33-bit precision
reg signed [32:0] z0, z1, z2, z3, z4, z5, z6, z7, z8, z9, z10;

// Decimation toggle
reg sample;

// Products: 33 bits * 16 bits = 49 bits
wire signed [48:0] prod_b0_b10 = (z0 + z10) * b0;   // symmetry in coefficients
wire signed [48:0] prod_b2_b8 = (z2 + z8)  * b2;
wire signed [48:0] prod_b4_b6 = (z4 + z6)  * b4;
wire signed [48:0] prod_b5 = z5 * b5;

// Sum: 49 bits + log2(4) = 51 bits
reg signed [50:0] sum;

always @(posedge clk) begin
    if (rst) begin
        z0 <= 0; z1 <= 0; z2 <= 0; z3 <= 0; z4 <= 0;
        z5 <= 0; z6 <= 0; z7 <= 0; z8 <= 0; z9 <= 0; z10 <= 0;
        out <= 0;
        valid_out <= 0;
        sample <= 0;
        
    end else if (valid_in) begin
        // Shift delay line
        z10 <= z9; z9 <= z8; z8 <= z7; z7 <= z6; z6 <= z5;
        z5 <= z4; z4 <= z3; z3 <= z2; z2 <= z1; z1 <= z0;
        z0 <= in;
        sum = prod_b0_b10 + prod_b2_b8 + prod_b4_b6 + prod_b5;
        // Decimate by 2
        if (sample) begin
            out <= sum >>> 15;  // 51-15 = 36 bits
            valid_out <= 1;
        end else begin
            valid_out <= 0;
        end

        sample <= ~sample;
        
    end else begin
        valid_out <= 0;
    end
end

endmodule
