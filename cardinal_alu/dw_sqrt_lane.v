`include "/usr/local/synopsys/Design_Compiler/K-2015.06-SP5-5/dw/sim_ver/DW_sqrt.v"

module dw_sqrt_lane #(
    parameter W = 8
)(
    input  wire [W-1:0] a,
    output wire [W-1:0] y
);
    wire [((W+1)/2)-1:0] root;

    DW_sqrt #(W, 0) U1 (
        .a    (a),
        .root (root)
    );

    assign y = {{(W-((W+1)/2)){1'b0}}, root};
endmodule

