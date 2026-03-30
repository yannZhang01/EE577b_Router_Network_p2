`timescale 1ns/1ps

module tb_cardinal_alu;

    reg  [63:0] rA;
    reg  [63:0] rB;
    reg  [1:0]  ww;
    reg  [5:0]  funct_6bit;
    wire [63:0] rD;
    wire        valid;

    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------
    cardinal_alu dut (
        .rA(rA),
        .rB(rB),
        .ww(ww),
        .funct_6bit(funct_6bit),
        .rD(rD),
        .valid(valid)
    );

    // ------------------------------------------------------------
    // Opcode constants
    // ------------------------------------------------------------
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

    integer pass_cnt;
    integer fail_cnt;
    integer i;

    // ------------------------------------------------------------
    // Reference model helpers
    // ------------------------------------------------------------
    function [63:0] isqrt_u64;
        input [63:0] x;
        reg [31:0] lo;
        reg [31:0] hi;
        reg [31:0] mid;
        reg [63:0] sq;
        integer j;
        begin
            lo = 0;
            hi = 32'hFFFF_FFFF;
            isqrt_u64 = 0;

            for (j = 0; j < 32; j = j + 1) begin
                if (lo <= hi) begin
                    mid = lo + ((hi - lo) >> 1);
                    sq  = mid * mid;

                    if (sq <= x) begin
                        isqrt_u64 = mid;
                        lo = mid + 1;
                    end else if (mid == 0) begin
                        hi = 0;
                    end else begin
                        hi = mid - 1;
                    end
                end
            end
        end
    endfunction

    function [63:0] exp_bitwise;
        input [63:0] a;
        input [63:0] b;
        input [1:0]  w;
        input [1:0]  op; // 0=AND, 1=OR, 2=XOR
        integer j;
        reg [63:0] y;
        begin
            y = 64'h0;
            case (w)
                2'b00: begin
                    for (j = 0; j < 8; j = j + 1) begin
                        case (op)
                            2'd0: y[63 - (j*8)  -: 8] = a[63 - (j*8)  -: 8] & b[63 - (j*8)  -: 8];
                            2'd1: y[63 - (j*8)  -: 8] = a[63 - (j*8)  -: 8] | b[63 - (j*8)  -: 8];
                            2'd2: y[63 - (j*8)  -: 8] = a[63 - (j*8)  -: 8] ^ b[63 - (j*8)  -: 8];
                        endcase
                    end
                end
                2'b01: begin
                    for (j = 0; j < 4; j = j + 1) begin
                        case (op)
                            2'd0: y[63 - (j*16) -: 16] = a[63 - (j*16) -: 16] & b[63 - (j*16) -: 16];
                            2'd1: y[63 - (j*16) -: 16] = a[63 - (j*16) -: 16] | b[63 - (j*16) -: 16];
                            2'd2: y[63 - (j*16) -: 16] = a[63 - (j*16) -: 16] ^ b[63 - (j*16) -: 16];
                        endcase
                    end
                end
                2'b10: begin
                    for (j = 0; j < 2; j = j + 1) begin
                        case (op)
                            2'd0: y[63 - (j*32) -: 32] = a[63 - (j*32) -: 32] & b[63 - (j*32) -: 32];
                            2'd1: y[63 - (j*32) -: 32] = a[63 - (j*32) -: 32] | b[63 - (j*32) -: 32];
                            2'd2: y[63 - (j*32) -: 32] = a[63 - (j*32) -: 32] ^ b[63 - (j*32) -: 32];
                        endcase
                    end
                end
                2'b11: begin
                    case (op)
                        2'd0: y = a & b;
                        2'd1: y = a | b;
                        2'd2: y = a ^ b;
                    endcase
                end
            endcase
            exp_bitwise = y;
        end
    endfunction

    function [63:0] exp_not;
        input [63:0] a;
        input [1:0]  w;
        integer j;
        reg [63:0] y;
        begin
            y = 64'h0;
            case (w)
                2'b00: for (j = 0; j < 8; j = j + 1) y[63 - (j*8)  -: 8]  = ~a[63 - (j*8)  -: 8];
                2'b01: for (j = 0; j < 4; j = j + 1) y[63 - (j*16) -: 16] = ~a[63 - (j*16) -: 16];
                2'b10: for (j = 0; j < 2; j = j + 1) y[63 - (j*32) -: 32] = ~a[63 - (j*32) -: 32];
                2'b11: y = ~a;
            endcase
            exp_not = y;
        end
    endfunction

    function [63:0] exp_mov;
        input [63:0] a;
        exp_mov = a;
    endfunction

    function [63:0] exp_addsub;
        input [63:0] a;
        input [63:0] b;
        input [1:0]  w;
        input        sub; // 0=ADD, 1=SUB
        integer j;
        reg [63:0] y;
        begin
            y = 64'h0;
            case (w)
                2'b00: begin
                    for (j = 0; j < 8; j = j + 1) begin
                        if (sub) y[63 - (j*8)  -: 8] = a[63 - (j*8)  -: 8] - b[63 - (j*8)  -: 8];
                        else     y[63 - (j*8)  -: 8] = a[63 - (j*8)  -: 8] + b[63 - (j*8)  -: 8];
                    end
                end
                2'b01: begin
                    for (j = 0; j < 4; j = j + 1) begin
                        if (sub) y[63 - (j*16) -: 16] = a[63 - (j*16) -: 16] - b[63 - (j*16) -: 16];
                        else     y[63 - (j*16) -: 16] = a[63 - (j*16) -: 16] + b[63 - (j*16) -: 16];
                    end
                end
                2'b10: begin
                    for (j = 0; j < 2; j = j + 1) begin
                        if (sub) y[63 - (j*32) -: 32] = a[63 - (j*32) -: 32] - b[63 - (j*32) -: 32];
                        else     y[63 - (j*32) -: 32] = a[63 - (j*32) -: 32] + b[63 - (j*32) -: 32];
                    end
                end
                2'b11: begin
                    if (sub) y = a - b;
                    else     y = a + b;
                end
            endcase
            exp_addsub = y;
        end
    endfunction

    function [63:0] exp_vmuleu;
        input [63:0] a;
        input [63:0] b;
        input [1:0]  w;
        integer j;
        reg [63:0] y;
        begin
            y = 64'h0;
            case (w)
                2'b00: for (j = 0; j < 4; j = j + 1) y[63 - (j*16) -: 16] = a[63 - ((2*j)*8)  -: 8]  * b[63 - ((2*j)*8)  -: 8];
                2'b01: for (j = 0; j < 2; j = j + 1) y[63 - (j*32) -: 32] = a[63 - ((2*j)*16) -: 16] * b[63 - ((2*j)*16) -: 16];
                2'b10: y = a[63 -: 32] * b[63 -: 32];
                default: y = 64'h0;
            endcase
            exp_vmuleu = y;
        end
    endfunction

    function [63:0] exp_vmulou;
        input [63:0] a;
        input [63:0] b;
        input [1:0]  w;
        integer j;
        reg [63:0] y;
        begin
            y = 64'h0;
            case (w)
                2'b00: for (j = 0; j < 4; j = j + 1) y[63 - (j*16) -: 16] = a[63 - (((2*j)+1)*8)  -: 8]  * b[63 - (((2*j)+1)*8)  -: 8];
                2'b01: for (j = 0; j < 2; j = j + 1) y[63 - (j*32) -: 32] = a[63 - (((2*j)+1)*16) -: 16] * b[63 - (((2*j)+1)*16) -: 16];
                2'b10: y = a[31:0] * b[31:0];
                default: y = 64'h0;
            endcase
            exp_vmulou = y;
        end
    endfunction

    function [63:0] exp_shift;
        input [63:0] a;
        input [63:0] b;
        input [1:0]  w;
        input [1:0]  mode; // 0=SLL, 1=SRL, 2=SRA
        integer j;
        reg [7:0]  aa8,  bb8;
        reg [15:0] aa16, bb16;
        reg [31:0] aa32, bb32;
        reg [63:0] aa64, bb64;
        reg [63:0] y;
        begin
            y = 64'h0;
            case (w)
                2'b00: begin
                    for (j = 0; j < 8; j = j + 1) begin
                        aa8 = a[63 - (j*8) -: 8];
                        bb8 = b[63 - (j*8) -: 8];
                        case (mode)
                            2'd0: y[63 - (j*8) -: 8] = aa8 << bb8[2:0];
                            2'd1: y[63 - (j*8) -: 8] = aa8 >> bb8[2:0];
                            2'd2: y[63 - (j*8) -: 8] = $signed(aa8) >>> bb8[2:0];
                        endcase
                    end
                end
                2'b01: begin
                    for (j = 0; j < 4; j = j + 1) begin
                        aa16 = a[63 - (j*16) -: 16];
                        bb16 = b[63 - (j*16) -: 16];
                        case (mode)
                            2'd0: y[63 - (j*16) -: 16] = aa16 << bb16[3:0];
                            2'd1: y[63 - (j*16) -: 16] = aa16 >> bb16[3:0];
                            2'd2: y[63 - (j*16) -: 16] = $signed(aa16) >>> bb16[3:0];
                        endcase
                    end
                end
                2'b10: begin
                    for (j = 0; j < 2; j = j + 1) begin
                        aa32 = a[63 - (j*32) -: 32];
                        bb32 = b[63 - (j*32) -: 32];
                        case (mode)
                            2'd0: y[63 - (j*32) -: 32] = aa32 << bb32[4:0];
                            2'd1: y[63 - (j*32) -: 32] = aa32 >> bb32[4:0];
                            2'd2: y[63 - (j*32) -: 32] = $signed(aa32) >>> bb32[4:0];
                        endcase
                    end
                end
                2'b11: begin
                    aa64 = a;
                    bb64 = b;
                    case (mode)
                        2'd0: y = aa64 << bb64[5:0];
                        2'd1: y = aa64 >> bb64[5:0];
                        2'd2: y = $signed(aa64) >>> bb64[5:0];
                    endcase
                end
            endcase
            exp_shift = y;
        end
    endfunction

    function [63:0] exp_vrtth;
        input [63:0] a;
        input [1:0]  w;
        integer j;
        reg [63:0] y;
        begin
            y = 64'h0;
            case (w)
                2'b00: for (j = 0; j < 8; j = j + 1) y[63 - (j*8)  -: 8]  = {a[59 - (j*8) -: 4],  a[63 - (j*8) -: 4]};
                2'b01: for (j = 0; j < 4; j = j + 1) y[63 - (j*16) -: 16] = {a[55 - (j*16) -: 8], a[63 - (j*16) -: 8]};
                2'b10: for (j = 0; j < 2; j = j + 1) y[63 - (j*32) -: 32] = {a[47 - (j*32) -: 16], a[63 - (j*32) -: 16]};
                2'b11: y = {a[31:0], a[63:32]};
            endcase
            exp_vrtth = y;
        end
    endfunction

    function [63:0] exp_divmod;
        input [63:0] a;
        input [63:0] b;
        input [1:0]  w;
        input        mod_sel; // 0=DIV, 1=MOD
        integer j;
        reg [7:0]  aa8,  bb8;
        reg [15:0] aa16, bb16;
        reg [31:0] aa32, bb32;
        reg [63:0] aa64, bb64;
        reg [63:0] y;
        begin
            y = 64'h0;
            case (w)
                2'b00: begin
                    for (j = 0; j < 8; j = j + 1) begin
                        aa8 = a[63 - (j*8) -: 8];
                        bb8 = b[63 - (j*8) -: 8];
                        if (bb8 == 0) y[63 - (j*8) -: 8] = 8'h00;
                        else if (mod_sel) y[63 - (j*8) -: 8] = aa8 % bb8;
                        else y[63 - (j*8) -: 8] = aa8 / bb8;
                    end
                end
                2'b01: begin
                    for (j = 0; j < 4; j = j + 1) begin
                        aa16 = a[63 - (j*16) -: 16];
                        bb16 = b[63 - (j*16) -: 16];
                        if (bb16 == 0) y[63 - (j*16) -: 16] = 16'h0000;
                        else if (mod_sel) y[63 - (j*16) -: 16] = aa16 % bb16;
                        else y[63 - (j*16) -: 16] = aa16 / bb16;
                    end
                end
                2'b10: begin
                    for (j = 0; j < 2; j = j + 1) begin
                        aa32 = a[63 - (j*32) -: 32];
                        bb32 = b[63 - (j*32) -: 32];
                        if (bb32 == 0) y[63 - (j*32) -: 32] = 32'h0000_0000;
                        else if (mod_sel) y[63 - (j*32) -: 32] = aa32 % bb32;
                        else y[63 - (j*32) -: 32] = aa32 / bb32;
                    end
                end
                2'b11: begin
                    aa64 = a;
                    bb64 = b;
                    if (bb64 == 0) y = 64'h0;
                    else if (mod_sel) y = aa64 % bb64;
                    else y = aa64 / bb64;
                end
            endcase
            exp_divmod = y;
        end
    endfunction

    function [63:0] exp_sq;
        input [63:0] a;
        input [1:0]  w;
        input        odd_sel; // 0=even, 1=odd
        integer j;
        reg [63:0] y;
        begin
            y = 64'h0;
            case (w)
                2'b00: begin
                    for (j = 0; j < 4; j = j + 1)
                        if (odd_sel)
                            y[63 - (j*16) -: 16] = a[63 - (((2*j)+1)*8) -: 8] * a[63 - (((2*j)+1)*8) -: 8];
                        else
                            y[63 - (j*16) -: 16] = a[63 - ((2*j)*8) -: 8] * a[63 - ((2*j)*8) -: 8];
                end
                2'b01: begin
                    for (j = 0; j < 2; j = j + 1)
                        if (odd_sel)
                            y[63 - (j*32) -: 32] = a[63 - (((2*j)+1)*16) -: 16] * a[63 - (((2*j)+1)*16) -: 16];
                        else
                            y[63 - (j*32) -: 32] = a[63 - ((2*j)*16) -: 16] * a[63 - ((2*j)*16) -: 16];
                end
                2'b10: begin
                    if (odd_sel)
                        y = a[31:0] * a[31:0];
                    else
                        y = a[63 -: 32] * a[63 -: 32];
                end
            endcase
            exp_sq = y;
        end
    endfunction

    function [63:0] exp_sqrt;
        input [63:0] a;
        input [1:0]  w;
        integer j;
        reg [63:0] y;
        reg [63:0] tmp;
        begin
            y = 64'h0;
            case (w)
                2'b00: begin
                    for (j = 0; j < 8; j = j + 1) begin
                        tmp = isqrt_u64({56'b0, a[63 - (j*8) -: 8]});
                        y[63 - (j*8) -: 8] = tmp[7:0];
                    end
                end
                2'b01: begin
                    for (j = 0; j < 4; j = j + 1) begin
                        tmp = isqrt_u64({48'b0, a[63 - (j*16) -: 16]});
                        y[63 - (j*16) -: 16] = tmp[15:0];
                    end
                end
                2'b10: begin
                    for (j = 0; j < 2; j = j + 1) begin
                        tmp = isqrt_u64({32'b0, a[63 - (j*32) -: 32]});
                        y[63 - (j*32) -: 32] = tmp[31:0];
                    end
                end
                2'b11: y = isqrt_u64(a);
            endcase
            exp_sqrt = y;
        end
    endfunction

    // ------------------------------------------------------------
    // Check task
    // ------------------------------------------------------------
    task check;
        input [255:0] name;
        input [5:0]   funct;
        input [1:0]   w;
        input [63:0]  a;
        input [63:0]  b;
        input [63:0]  exp;
        begin
            rA = a;
            rB = b;
            ww = w;
            funct_6bit = funct;
            #1;

            if ((rD === exp) && (valid === 1'b1)) begin
                pass_cnt = pass_cnt + 1;
                $display("PASS %-24s rD=%h", name, rD);
            end else begin
                fail_cnt = fail_cnt + 1;
                $display("FAIL %-24s exp=%h got=%h valid=%b", name, exp, rD, valid);
            end
        end
    endtask

    // ------------------------------------------------------------
    // Main test sequence
    // ------------------------------------------------------------
    initial begin
        pass_cnt = 0;
        fail_cnt = 0;

        // Bitwise
        check("VAND w00", F_VAND, 2'b00,
              64'hFF00_FF00_FF00_FF00,
              64'h0F0F_0F0F_0F0F_0F0F,
              exp_bitwise(64'hFF00_FF00_FF00_FF00, 64'h0F0F_0F0F_0F0F_0F0F, 2'b00, 2'd0));

        check("VOR w01", F_VOR, 2'b01,
              64'h1234_5678_9ABC_DEF0,
              64'h00FF_00FF_00FF_00FF,
              exp_bitwise(64'h1234_5678_9ABC_DEF0, 64'h00FF_00FF_00FF_00FF, 2'b01, 2'd1));

        check("VXOR w10", F_VXOR, 2'b10,
              64'hFFFF_0000_AAAA_5555,
              64'h0F0F_F0F0_1234_5678,
              exp_bitwise(64'hFFFF_0000_AAAA_5555, 64'h0F0F_F0F0_1234_5678, 2'b10, 2'd2));

        check("VNOT w11", F_VNOT, 2'b11,
              64'h0123_4567_89AB_CDEF,
              64'h0,
              exp_not(64'h0123_4567_89AB_CDEF, 2'b11));

        check("VMOV", F_VMOV, 2'b11,
              64'hDEAD_BEEF_0123_4567,
              64'h0,
              exp_mov(64'hDEAD_BEEF_0123_4567));

        // Add/Sub
        check("VADD w00", F_VADD, 2'b00,
              64'h0102_0304_0506_0708,
              64'h0101_0101_0101_0101,
              exp_addsub(64'h0102_0304_0506_0708, 64'h0101_0101_0101_0101, 2'b00, 1'b0));

        check("VSUB w01", F_VSUB, 2'b01,
              64'h1111_2222_3333_4444,
              64'h0001_0002_0003_0004,
              exp_addsub(64'h1111_2222_3333_4444, 64'h0001_0002_0003_0004, 2'b01, 1'b1));

        // Multiplication
        check("VMULEU w00", F_VMULEU, 2'b00,
              64'h0203_0405_0607_0809,
              64'h0908_0706_0504_0302,
              exp_vmuleu(64'h0203_0405_0607_0809, 64'h0908_0706_0504_0302, 2'b00));

        check("VMULOU w01", F_VMULOU, 2'b01,
              64'h1111_2222_3333_4444,
              64'hAAAA_BBBB_CCCC_DDDD,
              exp_vmulou(64'h1111_2222_3333_4444, 64'hAAAA_BBBB_CCCC_DDDD, 2'b01));

        // Shifts
        check("VSLL w00", F_VSLL, 2'b00,
              64'h0102_0304_0506_0708,
              64'h0001_0203_0405_0607,
              exp_shift(64'h0102_0304_0506_0708, 64'h0001_0203_0405_0607, 2'b00, 2'd0));

        check("VSRL w01", F_VSRL, 2'b01,
              64'h8001_FF00_7F80_1234,
              64'h0001_0002_0003_0004,
              exp_shift(64'h8001_FF00_7F80_1234, 64'h0001_0002_0003_0004, 2'b01, 2'd1));

        check("VSRA w10", F_VSRA, 2'b10,
              64'h8000_0001_FFFF_0001,
              64'h0001_0002_0003_0004,
              exp_shift(64'h8000_0001_FFFF_0001, 64'h0001_0002_0003_0004, 2'b10, 2'd2));

        // Rotate half
        check("VRTTH w00", F_VRTTH, 2'b00,
              64'h1234_5678_9ABC_DEF0,
              64'h0,
              exp_vrtth(64'h1234_5678_9ABC_DEF0, 2'b00));

        // Division / Mod
        check("VDIV w00", F_VDIV, 2'b00,
              64'h140F_0806_0403_0201,
              64'h0201_0201_0201_0201,
              exp_divmod(64'h140F_0806_0403_0201, 64'h0201_0201_0201_0201, 2'b00, 1'b0));

        check("VMOD w01", F_VMOD, 2'b01,
              64'h0010_0021_0032_0043,
              64'h0003_0004_0005_0006,
              exp_divmod(64'h0010_0021_0032_0043, 64'h0003_0004_0005_0006, 2'b01, 1'b1));

        check("VDIV zero", F_VDIV, 2'b11,
              64'h1234_5678_9ABC_DEF0,
              64'h0000_0000_0000_0000,
              64'h0000_0000_0000_0000);

        // Squares
        check("VSQEU w00", F_VSQEU, 2'b00,
              64'h0102_0304_0506_0708,
              64'h0,
              exp_sq(64'h0102_0304_0506_0708, 2'b00, 1'b0));

        check("VSQOU w01", F_VSQOU, 2'b01,
              64'h1111_2222_3333_4444,
              64'h0,
              exp_sq(64'h1111_2222_3333_4444, 2'b01, 1'b1));

        // Square root
        check("VSQRT w00", F_VSQRT, 2'b00,
              64'h0001_0409_1019_2431,
              64'h0,
              exp_sqrt(64'h0001_0409_1019_2431, 2'b00));

        check("VSQRT w01", F_VSQRT, 2'b01,
              64'h0000_0001_0004_0009,
              64'h0,
              exp_sqrt(64'h0000_0001_0004_0009, 2'b01));

        check("VSQRT w10", F_VSQRT, 2'b10,
              64'h0000_0064_0001_0000,
              64'h0,
              exp_sqrt(64'h0000_0064_0001_0000, 2'b10));

        check("VSQRT w11", F_VSQRT, 2'b11,
              64'd15241578750190521, // 123456789^2
              64'h0,
              exp_sqrt(64'd15241578750190521, 2'b11));

        $display("--------------------------------------------------");
        $display("TOTAL PASS = %0d", pass_cnt);
        $display("TOTAL FAIL = %0d", fail_cnt);
        $display("--------------------------------------------------");

        #5;
        $finish;
    end

endmodule