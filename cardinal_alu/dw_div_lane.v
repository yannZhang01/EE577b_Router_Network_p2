`include "/usr/local/synopsys/Design_Compiler/K-2015.06-SP5-5/dw/sim_ver/DW_div.v"

module dw_div_lane #(
    parameter W = 8
)(
    input  wire [W-1:0] a,
    input  wire [W-1:0] b,
    output wire [W-1:0] q,
    output wire         div_by_0
);
    wire [W-1:0] quotient;
    wire [W-1:0] remainder;

    DW_div #(W, W, 0, 1) U1 (
        .a           (a),
        .b           (b),
        .quotient    (quotient),
        .remainder   (remainder),
        .divide_by_0 (div_by_0)
    );

    assign q = div_by_0 ? {W{1'b0}} : quotient;
endmodule