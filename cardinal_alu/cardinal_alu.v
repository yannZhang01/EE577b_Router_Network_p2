module cardinal_alu (
    input  wire [63:0] rA,
    input  wire [63:0] rB,
    input  wire [1:0]  ww,
    input  wire [5:0]  funct_6bit,
    output reg  [63:0] rD,
    output reg         valid
);

localparam [5:0] F_VAND   = 6'b000001;
localparam [5:0] F_VOR    = 6'b000010;
localparam [5:0] F_VXOR   = 6'b000011;
localparam [5:0] F_VNOT   = 6'b000100;
localparam [5:0] F_VMOV   = 6'b000101;
localparam [5:0] F_VADD   = 6'b000110;
localparam [5:0] F_VSUB   = 6'b000111;
localparam [5:0] F_VMULEU = 6'b001000;
localparam [5:0] F_VMULOU = 6'b001001;
localparam [5:0] F_VSLL   = 6'b001010;
localparam [5:0] F_VSRL   = 6'b001011;
localparam [5:0] F_VSRA   = 6'b001100;
localparam [5:0] F_VRTTH  = 6'b001101;
localparam [5:0] F_VDIV   = 6'b001110;
localparam [5:0] F_VMOD   = 6'b001111;
localparam [5:0] F_VSQEU  = 6'b010000;
localparam [5:0] F_VSQOU  = 6'b010001;
localparam [5:0] F_VSQRT  = 6'b010010;

integer i;

reg [7:0]  a8,  b8;
reg [15:0] a16, b16;
reg [31:0] a32, b32;
reg [63:0] a64, b64;

wire [63:0] sqrt_w8;
wire [63:0] sqrt_w16;
wire [63:0] sqrt_w32;
wire [63:0] sqrt_w64;

genvar g8, g16, g32;

generate
    for (g8 = 0; g8 < 8; g8 = g8 + 1) begin : GEN_SQRT8
        dw_sqrt_lane #(.W(8)) u_sqrt8 (
            .a(rA[63 - (g8*8) -: 8]),
            .y(sqrt_w8[63 - (g8*8) -: 8])
        );
    end

    for (g16 = 0; g16 < 4; g16 = g16 + 1) begin : GEN_SQRT16
        dw_sqrt_lane #(.W(16)) u_sqrt16 (
            .a(rA[63 - (g16*16) -: 16]),
            .y(sqrt_w16[63 - (g16*16) -: 16])
        );
    end

    for (g32 = 0; g32 < 2; g32 = g32 + 1) begin : GEN_SQRT32
        dw_sqrt_lane #(.W(32)) u_sqrt32 (
            .a(rA[63 - (g32*32) -: 32]),
            .y(sqrt_w32[63 - (g32*32) -: 32])
        );
    end

    dw_sqrt_lane #(.W(64)) u_sqrt64 (
        .a(rA),
        .y(sqrt_w64)
    );
endgenerate

wire [63:0] q8_bus;
wire [63:0] q16_bus;
wire [63:0] q32_bus;
wire [63:0] q64;

genvar d8, d16, d32;

generate
    for (d8 = 0; d8 < 8; d8 = d8 + 1) begin : GEN_DIV8
        dw_div_lane #(.W(8)) u_div8 (
            .a(rA[63 - (d8*8) -: 8]),
            .b(rB[63 - (d8*8) -: 8]),
            .q(q8_bus[63 - (d8*8) -: 8]),
            .div_by_0()
        );
    end

    for (d16 = 0; d16 < 4; d16 = d16 + 1) begin : GEN_DIV16
        dw_div_lane #(.W(16)) u_div16 (
            .a(rA[63 - (d16*16) -: 16]),
            .b(rB[63 - (d16*16) -: 16]),
            .q(q16_bus[63 - (d16*16) -: 16]),
            .div_by_0()
        );
    end

    for (d32 = 0; d32 < 2; d32 = d32 + 1) begin : GEN_DIV32
        dw_div_lane #(.W(32)) u_div32 (
            .a(rA[63 - (d32*32) -: 32]),
            .b(rB[63 - (d32*32) -: 32]),
            .q(q32_bus[63 - (d32*32) -: 32]),
            .div_by_0()
        );
    end

    dw_div_lane #(.W(64)) u_div64 (
        .a(rA),
        .b(rB),
        .q(q64),
        .div_by_0()
    );
endgenerate

wire [63:0] mod_w8;
wire [63:0] mod_w16;
wire [63:0] mod_w32;
wire [63:0] mod_w64;

genvar m8, m16, m32;

generate
    for (m8 = 0; m8 < 8; m8 = m8 + 1) begin : GEN_MOD8
        dw_mod_lane #(.W(8)) u_mod8 (
            .a(rA[63 - (m8*8) -: 8]),
            .b(rB[63 - (m8*8) -: 8]),
            .r(mod_w8[63 - (m8*8) -: 8]),
            .div_by_0()
        );
    end

    for (m16 = 0; m16 < 4; m16 = m16 + 1) begin : GEN_MOD16
        dw_mod_lane #(.W(16)) u_mod16 (
            .a(rA[63 - (m16*16) -: 16]),
            .b(rB[63 - (m16*16) -: 16]),
            .r(mod_w16[63 - (m16*16) -: 16]),
            .div_by_0()
        );
    end

    for (m32 = 0; m32 < 2; m32 = m32 + 1) begin : GEN_MOD32
        dw_mod_lane #(.W(32)) u_mod32 (
            .a(rA[63 - (m32*32) -: 32]),
            .b(rB[63 - (m32*32) -: 32]),
            .r(mod_w32[63 - (m32*32) -: 32]),
            .div_by_0()
        );
    end

    dw_mod_lane #(.W(64)) u_mod64 (
        .a(rA),
        .b(rB),
        .r(mod_w64),
        .div_by_0()
    );
endgenerate

always @(*) begin
    rD    = 64'h0;
    valid = 1'b1;

    case (funct_6bit)
        F_VAND: begin
            case (ww)
                2'b00: for (i = 0; i < 8; i = i + 1)  
                    rD[63 - (i*8)  -: 8]  = rA[63 - (i*8)  -: 8]  & rB[63 - (i*8)  -: 8];
                    // rD[63:56] = rA[63:56] & rB[63:56];
                    // rD[55:48] = rA[55:48] & rB[55:48];
                    // rD[47:40] = rA[47:40] & rB[47:40];
                    // rD[39:32] = rA[39:32] & rB[39:32];
                    // rD[31:24] = rA[31:24] & rB[31:24];
                    // rD[23:16] = rA[23:16] & rB[23:16];
                    // rD[15:8]  = rA[15:8]  & rB[15:8];
                    // rD[7:0]   = rA[7:0]   & rB[7:0];
                2'b01: for (i = 0; i < 4; i = i + 1)  
                    rD[63 - (i*16) -: 16] = rA[63 - (i*16) -: 16] & rB[63 - (i*16) -: 16];
                2'b10: for (i = 0; i < 2; i = i + 1)  
                    rD[63 - (i*32) -: 32] = rA[63 - (i*32) -: 32] & rB[63 - (i*32) -: 32];
                2'b11: 
                    rD = rA & rB;
                default: valid = 1'b0;
            endcase
        end

        F_VOR: begin
            case (ww)
                2'b00: for (i = 0; i < 8; i = i + 1)  
                    rD[63 - (i*8)  -: 8]  = rA[63 - (i*8)  -: 8]  | rB[63 - (i*8)  -: 8];
                2'b01: for (i = 0; i < 4; i = i + 1)  
                    rD[63 - (i*16) -: 16] = rA[63 - (i*16) -: 16] | rB[63 - (i*16) -: 16];
                2'b10: for (i = 0; i < 2; i = i + 1)  
                    rD[63 - (i*32) -: 32] = rA[63 - (i*32) -: 32] | rB[63 - (i*32) -: 32];
                2'b11: 
                    rD = rA | rB;
                default: valid = 1'b0;
            endcase
        end

        F_VXOR: begin
            case (ww)
                2'b00: for (i = 0; i < 8; i = i + 1)  
                    rD[63 - (i*8)  -: 8]  = rA[63 - (i*8)  -: 8]  ^ rB[63 - (i*8)  -: 8];
                2'b01: for (i = 0; i < 4; i = i + 1)  
                    rD[63 - (i*16) -: 16] = rA[63 - (i*16) -: 16] ^ rB[63 - (i*16) -: 16];
                2'b10: for (i = 0; i < 2; i = i + 1)  
                    rD[63 - (i*32) -: 32] = rA[63 - (i*32) -: 32] ^ rB[63 - (i*32) -: 32];
                2'b11: 
                    rD = rA ^ rB;
                default: valid = 1'b0;
            endcase
        end

        F_VNOT: begin
            case (ww)
                2'b00: for (i = 0; i < 8; i = i + 1)  
                    rD[63 - (i*8)  -: 8]  = ~rA[63 - (i*8)  -: 8];
                2'b01: for (i = 0; i < 4; i = i + 1)  
                    rD[63 - (i*16) -: 16] = ~rA[63 - (i*16) -: 16];
                2'b10: for (i = 0; i < 2; i = i + 1)  
                    rD[63 - (i*32) -: 32] = ~rA[63 - (i*32) -: 32];
                2'b11: 
                    rD = ~rA;
                default: valid = 1'b0;
            endcase
        end

        F_VMOV: begin
            rD = rA;
        end

        F_VADD: begin
            case (ww)
                2'b00: for (i = 0; i < 8; i = i + 1)  
                    rD[63 - (i*8)  -: 8]  = rA[63 - (i*8)  -: 8]  + rB[63 - (i*8)  -: 8];
                2'b01: for (i = 0; i < 4; i = i + 1)  
                    rD[63 - (i*16) -: 16] = rA[63 - (i*16) -: 16] + rB[63 - (i*16) -: 16];
                2'b10: for (i = 0; i < 2; i = i + 1)  
                    rD[63 - (i*32) -: 32] = rA[63 - (i*32) -: 32] + rB[63 - (i*32) -: 32];
                2'b11: 
                    rD = rA + rB;
                default: valid = 1'b0;
            endcase
        end

        F_VSUB: begin
            case (ww)
                2'b00: for (i = 0; i < 8; i = i + 1)  
                    rD[63 - (i*8)  -: 8]  = rA[63 - (i*8)  -: 8]  - rB[63 - (i*8)  -: 8];
                2'b01: for (i = 0; i < 4; i = i + 1)  
                    rD[63 - (i*16) -: 16] = rA[63 - (i*16) -: 16] - rB[63 - (i*16) -: 16];
                2'b10: for (i = 0; i < 2; i = i + 1)  
                    rD[63 - (i*32) -: 32] = rA[63 - (i*32) -: 32] - rB[63 - (i*32) -: 32];
                2'b11: 
                    rD = rA - rB;
                default: valid = 1'b0;
            endcase
        end

        F_VMULEU: begin
            case (ww)
                2'b00: begin
                    for (i = 0; i < 4; i = i + 1)
                        rD[63 - (i*16) -: 16] = rA[63 - ((2*i)*8) -: 8] * rB[63 - ((2*i)*8) -: 8];
                end
                2'b01: begin
                    for (i = 0; i < 2; i = i + 1)
                        rD[63 - (i*32) -: 32] = rA[63 - ((2*i)*16) -: 16] * rB[63 - ((2*i)*16) -: 16];
                end
                2'b10: begin
                    rD = rA[63 -: 32] * rB[63 -: 32];
                end
                default: begin
                    valid = 1'b0;
                    rD = 64'h0;
                end
            endcase
        end

        F_VMULOU: begin
            case (ww)
                2'b00: begin
                    for (i = 0; i < 4; i = i + 1)
                        rD[63 - (i*16) -: 16] = rA[63 - (((2*i)+1)*8) -: 8] * rB[63 - (((2*i)+1)*8) -: 8];
                end
                2'b01: begin
                    for (i = 0; i < 2; i = i + 1)
                        rD[63 - (i*32) -: 32] = rA[63 - (((2*i)+1)*16) -: 16] * rB[63 - (((2*i)+1)*16) -: 16];
                end
                2'b10: begin
                    rD = rA[31:0] * rB[31:0];
                end
                default: begin
                    valid = 1'b0;
                    rD = 64'h0;
                end
            endcase
        end

        F_VSLL: begin
            case (ww)
                2'b00: begin
                    for (i = 0; i < 8; i = i + 1) begin
                        a8 = rA[63 - (i*8) -: 8];
                        b8 = rB[63 - (i*8) -: 8];
                        rD[63 - (i*8) -: 8] = a8 << b8[2:0];
                    end
                end
                2'b01: begin
                    for (i = 0; i < 4; i = i + 1) begin
                        a16 = rA[63 - (i*16) -: 16];
                        b16 = rB[63 - (i*16) -: 16];
                        rD[63 - (i*16) -: 16] = a16 << b16[3:0];
                    end
                end
                2'b10: begin
                    for (i = 0; i < 2; i = i + 1) begin
                        a32 = rA[63 - (i*32) -: 32];
                        b32 = rB[63 - (i*32) -: 32];
                        rD[63 - (i*32) -: 32] = a32 << b32[4:0];
                    end
                end
                2'b11: begin
                    a64 = rA;
                    b64 = rB;
                    rD = a64 << b64[5:0];
                end
                default: valid = 1'b0;
            endcase
        end

        F_VSRL: begin
            case (ww)
                2'b00: begin
                    for (i = 0; i < 8; i = i + 1) begin
                        a8 = rA[63 - (i*8) -: 8];
                        b8 = rB[63 - (i*8) -: 8];
                        rD[63 - (i*8) -: 8] = a8 >> b8[2:0];
                    end
                end
                2'b01: begin
                    for (i = 0; i < 4; i = i + 1) begin
                        a16 = rA[63 - (i*16) -: 16];
                        b16 = rB[63 - (i*16) -: 16];
                        rD[63 - (i*16) -: 16] = a16 >> b16[3:0];
                    end
                end
                2'b10: begin
                    for (i = 0; i < 2; i = i + 1) begin
                        a32 = rA[63 - (i*32) -: 32];
                        b32 = rB[63 - (i*32) -: 32];
                        rD[63 - (i*32) -: 32] = a32 >> b32[4:0];
                    end
                end
                2'b11: begin
                    a64 = rA;
                    b64 = rB;
                    rD = a64 >> b64[5:0];
                end
                default: valid = 1'b0;
            endcase
        end

        F_VSRA: begin
            case (ww)
                2'b00: begin
                    for (i = 0; i < 8; i = i + 1) begin
                        a8 = rA[63 - (i*8) -: 8];
                        b8 = rB[63 - (i*8) -: 8];
                        rD[63 - (i*8) -: 8] = $signed(a8) >>> b8[2:0];
                    end
                end
                2'b01: begin
                    for (i = 0; i < 4; i = i + 1) begin
                        a16 = rA[63 - (i*16) -: 16];
                        b16 = rB[63 - (i*16) -: 16];
                        rD[63 - (i*16) -: 16] = $signed(a16) >>> b16[3:0];
                    end
                end
                2'b10: begin
                    for (i = 0; i < 2; i = i + 1) begin
                        a32 = rA[63 - (i*32) -: 32];
                        b32 = rB[63 - (i*32) -: 32];
                        rD[63 - (i*32) -: 32] = $signed(a32) >>> b32[4:0];
                    end
                end
                2'b11: begin
                    a64 = rA;
                    b64 = rB;
                    rD = $signed(a64) >>> b64[5:0];
                end
                default: valid = 1'b0;
            endcase
        end

        F_VRTTH: begin
            case (ww)
                2'b00: for (i = 0; i < 8; i = i + 1)  
                    rD[63 - (i*8)  -: 8]  = {rA[59 - (i*8) -: 4],  rA[63 - (i*8) -: 4]};
                2'b01: for (i = 0; i < 4; i = i + 1)  
                    rD[63 - (i*16) -: 16] = {rA[55 - (i*16) -: 8], rA[63 - (i*16) -: 8]};
                2'b10: for (i = 0; i < 2; i = i + 1)  
                    rD[63 - (i*32) -: 32] = {rA[47 - (i*32) -: 16], rA[63 - (i*32) -: 16]};
                2'b11: 
                    rD = {rA[31:0], rA[63:32]};
                default: valid = 1'b0;
            endcase
        end

        F_VDIV: begin
            case (ww)
                2'b00: rD = q8_bus;
                2'b01: rD = q16_bus;
                2'b10: rD = q32_bus;
                2'b11: rD = q64;
                default: begin
                    valid = 1'b0;
                    rD    = 64'h0;
                end
            endcase
        end

        F_VMOD: begin
            case (ww)
                2'b00: rD = mod_w8;
                2'b01: rD = mod_w16;
                2'b10: rD = mod_w32;
                2'b11: rD = mod_w64;
                default: begin
                    valid = 1'b0;
                    rD    = 64'h0;
                end
            endcase
        end

        F_VSQEU: begin
            case (ww)
                2'b00: begin
                    for (i = 0; i < 4; i = i + 1)
                        rD[63 - (i*16) -: 16] = rA[63 - ((2*i)*8) -: 8] * rA[63 - ((2*i)*8) -: 8];
                end
                2'b01: begin
                    for (i = 0; i < 2; i = i + 1)
                        rD[63 - (i*32) -: 32] = rA[63 - ((2*i)*16) -: 16] * rA[63 - ((2*i)*16) -: 16];
                end
                2'b10: begin
                    rD = rA[63 -: 32] * rA[63 -: 32];
                end
                default: begin
                    valid = 1'b0;
                    rD = 64'h0;
                end
            endcase
        end

        F_VSQOU: begin
            case (ww)
                2'b00: begin
                    for (i = 0; i < 4; i = i + 1)
                        rD[63 - (i*16) -: 16] = rA[63 - (((2*i)+1)*8) -: 8] * rA[63 - (((2*i)+1)*8) -: 8];
                end
                2'b01: begin
                    for (i = 0; i < 2; i = i + 1)
                        rD[63 - (i*32) -: 32] = rA[63 - (((2*i)+1)*16) -: 16] * rA[63 - (((2*i)+1)*16) -: 16];
                end
                2'b10: begin
                    rD = rA[31:0] * rA[31:0];
                end
                default: begin
                    valid = 1'b0;
                    rD = 64'h0;
                end
            endcase
        end

       F_VSQRT: begin
            case (ww)
                2'b00: rD = sqrt_w8;
                2'b01: rD = sqrt_w16;
                2'b10: rD = sqrt_w32;
                2'b11: rD = sqrt_w64;
                default: begin
                    rD    = 64'h0;
                    valid = 1'b0;
                end
            endcase
        end

        default: begin
            valid = 1'b0;
            rD = 64'h0;
        end
    endcase
end

endmodule