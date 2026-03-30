`timescale 1ns/1ps
`default_nettype none

module tb_instruction_decode;

    localparam [5:0] OPCODE_RTYPE = 6'b101010;
    localparam [5:0] OPCODE_VLD   = 6'b100000;
    localparam [5:0] OPCODE_VSD   = 6'b100001;
    localparam [5:0] OPCODE_VBEZ  = 6'b100010;
    localparam [5:0] OPCODE_VBNEZ = 6'b100011;
    localparam [5:0] OPCODE_VNOP  = 6'b111100;

    localparam [5:0] FUNC_VAND   = 6'b000001;
    localparam [5:0] FUNC_VOR    = 6'b000010;
    localparam [5:0] FUNC_VXOR   = 6'b000011;
    localparam [5:0] FUNC_VNOT   = 6'b000100;
    localparam [5:0] FUNC_VMOV   = 6'b000101;
    localparam [5:0] FUNC_VADD   = 6'b000110;
    localparam [5:0] FUNC_VSUB   = 6'b000111;
    localparam [5:0] FUNC_VMULEU = 6'b001000;
    localparam [5:0] FUNC_VMULOU = 6'b001001;
    localparam [5:0] FUNC_VSLL   = 6'b001010;
    localparam [5:0] FUNC_VSRL   = 6'b001011;
    localparam [5:0] FUNC_VSRA   = 6'b001100;
    localparam [5:0] FUNC_VRTTH  = 6'b001101;
    localparam [5:0] FUNC_VDIV   = 6'b001110;
    localparam [5:0] FUNC_VMOD   = 6'b001111;
    localparam [5:0] FUNC_VSQEU  = 6'b010000;
    localparam [5:0] FUNC_VSQOU  = 6'b010001;
    localparam [5:0] FUNC_VSQRT  = 6'b010010;

    localparam [5:0] ALU_OP_NONE   = 6'd0;
    localparam [5:0] ALU_OP_VAND   = 6'd1;
    localparam [5:0] ALU_OP_VOR    = 6'd2;
    localparam [5:0] ALU_OP_VXOR   = 6'd3;
    localparam [5:0] ALU_OP_VNOT   = 6'd4;
    localparam [5:0] ALU_OP_VMOV   = 6'd5;
    localparam [5:0] ALU_OP_VADD   = 6'd6;
    localparam [5:0] ALU_OP_VSUB   = 6'd7;
    localparam [5:0] ALU_OP_VMULEU = 6'd8;
    localparam [5:0] ALU_OP_VMULOU = 6'd9;
    localparam [5:0] ALU_OP_VSLL   = 6'd10;
    localparam [5:0] ALU_OP_VSRL   = 6'd11;
    localparam [5:0] ALU_OP_VSRA   = 6'd12;
    localparam [5:0] ALU_OP_VRTTH  = 6'd13;
    localparam [5:0] ALU_OP_VDIV   = 6'd14;
    localparam [5:0] ALU_OP_VMOD   = 6'd15;
    localparam [5:0] ALU_OP_VSQEU  = 6'd16;
    localparam [5:0] ALU_OP_VSQOU  = 6'd17;
    localparam [5:0] ALU_OP_VSQRT  = 6'd18;
    localparam [5:0] ALU_OP_VLD    = 6'd19;
    localparam [5:0] ALU_OP_VSD    = 6'd20;
    localparam [5:0] ALU_OP_VBEZ   = 6'd21;
    localparam [5:0] ALU_OP_VBNEZ  = 6'd22;
    localparam [5:0] ALU_OP_VNOP   = 6'd23;

    localparam [1:0] WB_SEL_NONE      = 2'b00;
    localparam [1:0] WB_SEL_EX_RESULT = 2'b01;
    localparam [1:0] WB_SEL_MEM_DATA  = 2'b10;

    reg  [31:0] instruction;

    wire [5:0]  alu_op;
    wire [4:0]  rd_idx;
    wire [4:0]  ra_idx;
    wire [4:0]  rb_idx;
    wire [15:0] imm16;
    wire [1:0]  ww;

    wire        reg_write_en;
    wire        mem_read_en;
    wire        mem_write_en;

    wire        branch_en;
    wire        branch_eqz;
    wire        branch_nez;

    wire        use_ra;
    wire        use_rb;
    wire        use_rd_as_src;

    wire [1:0]  wb_sel;

    wire        is_nop;
    wire        illegal_insn;

    integer total_cases;
    integer fail_cases;

    instruction_decode dut (
        .instruction   (instruction),
        .alu_op        (alu_op),
        .rd_idx        (rd_idx),
        .ra_idx        (ra_idx),
        .rb_idx        (rb_idx),
        .imm16         (imm16),
        .ww            (ww),
        .reg_write_en  (reg_write_en),
        .mem_read_en   (mem_read_en),
        .mem_write_en  (mem_write_en),
        .branch_en     (branch_en),
        .branch_eqz    (branch_eqz),
        .branch_nez    (branch_nez),
        .use_ra        (use_ra),
        .use_rb        (use_rb),
        .use_rd_as_src (use_rd_as_src),
        .wb_sel        (wb_sel),
        .is_nop        (is_nop),
        .illegal_insn  (illegal_insn)
    );

    function [31:0] make_r_binary;
        input [4:0] rd;
        input [4:0] ra;
        input [4:0] rb;
        input [1:0] ww_val;
        input [5:0] func;
        begin
            make_r_binary = {OPCODE_RTYPE, rd, ra, rb, 3'b000, ww_val, func};
        end
    endfunction

    function [31:0] make_r_unary;
        input [4:0] rd;
        input [4:0] ra;
        input [1:0] ww_val;
        input [5:0] func;
        begin
            make_r_unary = {OPCODE_RTYPE, rd, ra, 5'b00000, 3'b000, ww_val, func};
        end
    endfunction

    function [31:0] make_imm;
        input [5:0] opcode;
        input [4:0] rd;
        input [15:0] imm_val;
        begin
            make_imm = {opcode, rd, 5'b00000, imm_val};
        end
    endfunction

    task check_instruction;
        input [31:0] instr;
        input [5:0]  exp_alu_op;
        input [1:0]  exp_ww;
        input        exp_reg_write_en;
        input        exp_mem_read_en;
        input        exp_mem_write_en;
        input        exp_branch_en;
        input        exp_branch_eqz;
        input        exp_branch_nez;
        input        exp_use_ra;
        input        exp_use_rb;
        input        exp_use_rd_as_src;
        input [1:0]  exp_wb_sel;
        input        exp_is_nop;
        input        exp_illegal_insn;
        begin
            instruction = instr;
            #1;
            total_cases = total_cases + 1;

            if ((alu_op        !== exp_alu_op)          ||
                (rd_idx        !== instr[25:21])        ||
                (ra_idx        !== instr[20:16])        ||
                (rb_idx        !== instr[15:11])        ||
                (imm16         !== instr[15:0])         ||
                (ww            !== exp_ww)              ||
                (reg_write_en  !== exp_reg_write_en)    ||
                (mem_read_en   !== exp_mem_read_en)     ||
                (mem_write_en  !== exp_mem_write_en)    ||
                (branch_en     !== exp_branch_en)       ||
                (branch_eqz    !== exp_branch_eqz)      ||
                (branch_nez    !== exp_branch_nez)      ||
                (use_ra        !== exp_use_ra)          ||
                (use_rb        !== exp_use_rb)          ||
                (use_rd_as_src !== exp_use_rd_as_src)   ||
                (wb_sel        !== exp_wb_sel)          ||
                (is_nop        !== exp_is_nop)          ||
                (illegal_insn  !== exp_illegal_insn)) begin
                fail_cases = fail_cases + 1;
                $display("FAIL case %0d", total_cases);
                $display("  instr        = %h", instr);
                $display("  alu_op       = %0d expected %0d", alu_op, exp_alu_op);
                $display("  rd_idx       = %0d expected %0d", rd_idx, instr[25:21]);
                $display("  ra_idx       = %0d expected %0d", ra_idx, instr[20:16]);
                $display("  rb_idx       = %0d expected %0d", rb_idx, instr[15:11]);
                $display("  imm16        = %h expected %h", imm16, instr[15:0]);
                $display("  ww           = %b expected %b", ww, exp_ww);
                $display("  reg_write_en = %b expected %b", reg_write_en, exp_reg_write_en);
                $display("  mem_read_en  = %b expected %b", mem_read_en, exp_mem_read_en);
                $display("  mem_write_en = %b expected %b", mem_write_en, exp_mem_write_en);
                $display("  branch_en    = %b expected %b", branch_en, exp_branch_en);
                $display("  branch_eqz   = %b expected %b", branch_eqz, exp_branch_eqz);
                $display("  branch_nez   = %b expected %b", branch_nez, exp_branch_nez);
                $display("  use_ra       = %b expected %b", use_ra, exp_use_ra);
                $display("  use_rb       = %b expected %b", use_rb, exp_use_rb);
                $display("  use_rd_as_src= %b expected %b", use_rd_as_src, exp_use_rd_as_src);
                $display("  wb_sel       = %b expected %b", wb_sel, exp_wb_sel);
                $display("  is_nop       = %b expected %b", is_nop, exp_is_nop);
                $display("  illegal_insn = %b expected %b", illegal_insn, exp_illegal_insn);
            end
            else begin
                $display("PASS case %0d: instr=%h", total_cases, instr);
            end
        end
    endtask

    task check_valid_r_binary;
        input [5:0] func;
        input [1:0] ww_val;
        input [5:0] exp_alu_op;
        reg   [31:0] instr;
        begin
            instr = make_r_binary(5'd3, 5'd4, 5'd5, ww_val, func);
            check_instruction(
                instr,
                exp_alu_op,
                ww_val,
                1'b1,
                1'b0,
                1'b0,
                1'b0,
                1'b0,
                1'b0,
                1'b1,
                1'b1,
                1'b0,
                WB_SEL_EX_RESULT,
                1'b0,
                1'b0
            );
        end
    endtask

    task check_valid_r_unary;
        input [5:0] func;
        input [1:0] ww_val;
        input [5:0] exp_alu_op;
        reg   [31:0] instr;
        begin
            instr = make_r_unary(5'd6, 5'd7, ww_val, func);
            check_instruction(
                instr,
                exp_alu_op,
                ww_val,
                1'b1,
                1'b0,
                1'b0,
                1'b0,
                1'b0,
                1'b0,
                1'b1,
                1'b0,
                1'b0,
                WB_SEL_EX_RESULT,
                1'b0,
                1'b0
            );
        end
    endtask

    task check_illegal;
        input [31:0] instr;
        begin
            check_instruction(
                instr,
                ALU_OP_NONE,
                2'b00,
                1'b0,
                1'b0,
                1'b0,
                1'b0,
                1'b0,
                1'b0,
                1'b0,
                1'b0,
                1'b0,
                WB_SEL_NONE,
                1'b0,
                1'b1
            );
        end
    endtask

    initial begin
        total_cases = 0;
        fail_cases  = 0;
        instruction = 32'h0000_0000;

        check_valid_r_binary(FUNC_VAND,   2'b00, ALU_OP_VAND);
        check_valid_r_binary(FUNC_VAND,   2'b01, ALU_OP_VAND);
        check_valid_r_binary(FUNC_VAND,   2'b10, ALU_OP_VAND);
        check_valid_r_binary(FUNC_VAND,   2'b11, ALU_OP_VAND);

        check_valid_r_binary(FUNC_VOR,    2'b00, ALU_OP_VOR);
        check_valid_r_binary(FUNC_VOR,    2'b01, ALU_OP_VOR);
        check_valid_r_binary(FUNC_VOR,    2'b10, ALU_OP_VOR);
        check_valid_r_binary(FUNC_VOR,    2'b11, ALU_OP_VOR);

        check_valid_r_binary(FUNC_VXOR,   2'b00, ALU_OP_VXOR);
        check_valid_r_binary(FUNC_VXOR,   2'b01, ALU_OP_VXOR);
        check_valid_r_binary(FUNC_VXOR,   2'b10, ALU_OP_VXOR);
        check_valid_r_binary(FUNC_VXOR,   2'b11, ALU_OP_VXOR);

        check_valid_r_unary (FUNC_VNOT,   2'b00, ALU_OP_VNOT);
        check_valid_r_unary (FUNC_VNOT,   2'b01, ALU_OP_VNOT);
        check_valid_r_unary (FUNC_VNOT,   2'b10, ALU_OP_VNOT);
        check_valid_r_unary (FUNC_VNOT,   2'b11, ALU_OP_VNOT);

        check_valid_r_unary (FUNC_VMOV,   2'b00, ALU_OP_VMOV);
        check_valid_r_unary (FUNC_VMOV,   2'b01, ALU_OP_VMOV);
        check_valid_r_unary (FUNC_VMOV,   2'b10, ALU_OP_VMOV);
        check_valid_r_unary (FUNC_VMOV,   2'b11, ALU_OP_VMOV);

        check_valid_r_binary(FUNC_VADD,   2'b00, ALU_OP_VADD);
        check_valid_r_binary(FUNC_VADD,   2'b01, ALU_OP_VADD);
        check_valid_r_binary(FUNC_VADD,   2'b10, ALU_OP_VADD);
        check_valid_r_binary(FUNC_VADD,   2'b11, ALU_OP_VADD);

        check_valid_r_binary(FUNC_VSUB,   2'b00, ALU_OP_VSUB);
        check_valid_r_binary(FUNC_VSUB,   2'b01, ALU_OP_VSUB);
        check_valid_r_binary(FUNC_VSUB,   2'b10, ALU_OP_VSUB);
        check_valid_r_binary(FUNC_VSUB,   2'b11, ALU_OP_VSUB);

        check_valid_r_binary(FUNC_VMULEU, 2'b00, ALU_OP_VMULEU);
        check_valid_r_binary(FUNC_VMULEU, 2'b01, ALU_OP_VMULEU);
        check_valid_r_binary(FUNC_VMULEU, 2'b10, ALU_OP_VMULEU);

        check_valid_r_binary(FUNC_VMULOU, 2'b00, ALU_OP_VMULOU);
        check_valid_r_binary(FUNC_VMULOU, 2'b01, ALU_OP_VMULOU);
        check_valid_r_binary(FUNC_VMULOU, 2'b10, ALU_OP_VMULOU);

        check_valid_r_binary(FUNC_VSLL,   2'b00, ALU_OP_VSLL);
        check_valid_r_binary(FUNC_VSLL,   2'b01, ALU_OP_VSLL);
        check_valid_r_binary(FUNC_VSLL,   2'b10, ALU_OP_VSLL);
        check_valid_r_binary(FUNC_VSLL,   2'b11, ALU_OP_VSLL);

        check_valid_r_binary(FUNC_VSRL,   2'b00, ALU_OP_VSRL);
        check_valid_r_binary(FUNC_VSRL,   2'b01, ALU_OP_VSRL);
        check_valid_r_binary(FUNC_VSRL,   2'b10, ALU_OP_VSRL);
        check_valid_r_binary(FUNC_VSRL,   2'b11, ALU_OP_VSRL);

        check_valid_r_binary(FUNC_VSRA,   2'b00, ALU_OP_VSRA);
        check_valid_r_binary(FUNC_VSRA,   2'b01, ALU_OP_VSRA);
        check_valid_r_binary(FUNC_VSRA,   2'b10, ALU_OP_VSRA);
        check_valid_r_binary(FUNC_VSRA,   2'b11, ALU_OP_VSRA);

        check_valid_r_unary (FUNC_VRTTH,  2'b00, ALU_OP_VRTTH);
        check_valid_r_unary (FUNC_VRTTH,  2'b01, ALU_OP_VRTTH);
        check_valid_r_unary (FUNC_VRTTH,  2'b10, ALU_OP_VRTTH);
        check_valid_r_unary (FUNC_VRTTH,  2'b11, ALU_OP_VRTTH);

        check_valid_r_binary(FUNC_VDIV,   2'b00, ALU_OP_VDIV);
        check_valid_r_binary(FUNC_VDIV,   2'b01, ALU_OP_VDIV);
        check_valid_r_binary(FUNC_VDIV,   2'b10, ALU_OP_VDIV);
        check_valid_r_binary(FUNC_VDIV,   2'b11, ALU_OP_VDIV);

        check_valid_r_binary(FUNC_VMOD,   2'b00, ALU_OP_VMOD);
        check_valid_r_binary(FUNC_VMOD,   2'b01, ALU_OP_VMOD);
        check_valid_r_binary(FUNC_VMOD,   2'b10, ALU_OP_VMOD);
        check_valid_r_binary(FUNC_VMOD,   2'b11, ALU_OP_VMOD);

        check_valid_r_unary (FUNC_VSQEU,  2'b00, ALU_OP_VSQEU);
        check_valid_r_unary (FUNC_VSQEU,  2'b01, ALU_OP_VSQEU);
        check_valid_r_unary (FUNC_VSQEU,  2'b10, ALU_OP_VSQEU);

        check_valid_r_unary (FUNC_VSQOU,  2'b00, ALU_OP_VSQOU);
        check_valid_r_unary (FUNC_VSQOU,  2'b01, ALU_OP_VSQOU);
        check_valid_r_unary (FUNC_VSQOU,  2'b10, ALU_OP_VSQOU);

        check_valid_r_unary (FUNC_VSQRT,  2'b00, ALU_OP_VSQRT);
        check_valid_r_unary (FUNC_VSQRT,  2'b01, ALU_OP_VSQRT);
        check_valid_r_unary (FUNC_VSQRT,  2'b10, ALU_OP_VSQRT);
        check_valid_r_unary (FUNC_VSQRT,  2'b11, ALU_OP_VSQRT);

        check_instruction(
            make_imm(OPCODE_VLD, 5'd8, 16'h1234),
            ALU_OP_VLD,
            2'b00,
            1'b1,
            1'b1,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            WB_SEL_MEM_DATA,
            1'b0,
            1'b0
        );

        check_instruction(
            make_imm(OPCODE_VSD, 5'd9, 16'h2345),
            ALU_OP_VSD,
            2'b00,
            1'b0,
            1'b0,
            1'b1,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b1,
            WB_SEL_NONE,
            1'b0,
            1'b0
        );

        check_instruction(
            make_imm(OPCODE_VBEZ, 5'd10, 16'h3456),
            ALU_OP_VBEZ,
            2'b00,
            1'b0,
            1'b0,
            1'b0,
            1'b1,
            1'b1,
            1'b0,
            1'b0,
            1'b0,
            1'b1,
            WB_SEL_NONE,
            1'b0,
            1'b0
        );

        check_instruction(
            make_imm(OPCODE_VBNEZ, 5'd11, 16'h4567),
            ALU_OP_VBNEZ,
            2'b00,
            1'b0,
            1'b0,
            1'b0,
            1'b1,
            1'b0,
            1'b1,
            1'b0,
            1'b0,
            1'b1,
            WB_SEL_NONE,
            1'b0,
            1'b0
        );

        check_instruction(
            32'b111100_00000_00000_00000_00000_000000,
            ALU_OP_VNOP,
            2'b00,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            WB_SEL_NONE,
            1'b1,
            1'b0
        );

        check_illegal({6'b000000, 26'h0000000});
        check_illegal({OPCODE_RTYPE, 5'd1, 5'd2, 5'd3, 3'b001, 2'b00, FUNC_VAND});
        check_illegal({OPCODE_RTYPE, 5'd1, 5'd2, 5'd3, 3'b000, 2'b00, FUNC_VNOT});
        check_illegal({OPCODE_RTYPE, 5'd1, 5'd2, 5'd3, 3'b000, 2'b11, FUNC_VMULEU});
        check_illegal({OPCODE_RTYPE, 5'd1, 5'd2, 5'd3, 3'b000, 2'b11, FUNC_VMULOU});
        check_illegal({OPCODE_RTYPE, 5'd1, 5'd2, 5'd3, 3'b000, 2'b11, FUNC_VSQEU});
        check_illegal({OPCODE_RTYPE, 5'd1, 5'd2, 5'd3, 3'b000, 2'b11, FUNC_VSQOU});
        check_illegal({OPCODE_VLD,   5'd1, 5'd2, 16'h1111});
        check_illegal({OPCODE_VSD,   5'd1, 5'd2, 16'h2222});
        check_illegal({OPCODE_VBEZ,  5'd1, 5'd2, 16'h3333});
        check_illegal({OPCODE_VBNEZ, 5'd1, 5'd2, 16'h4444});
        check_illegal({OPCODE_VNOP, 26'h000001});

        if (fail_cases == 0) begin
            $display("========================================");
            $display("All %0d instruction_decode tests passed.", total_cases);
            $display("========================================");
        end
        else begin
            $display("========================================");
            $display("%0d out of %0d instruction_decode tests failed.", fail_cases, total_cases);
            $display("========================================");
        end

        $finish;
    end

endmodule

`default_nettype wire