`timescale 1ns/1ps
`default_nettype none

module instruction_decode (
    input  wire [31:0] instruction,

    output reg  [5:0]  alu_op,
    output wire [4:0]  rd_idx,
    output wire [4:0]  ra_idx,
    output wire [4:0]  rb_idx,
    output wire [15:0] imm16,
    output reg  [1:0]  ww,

    output reg         reg_write_en,
    output reg         mem_read_en,
    output reg         mem_write_en,

    output reg         branch_en,
    output reg         branch_eqz,
    output reg         branch_nez,

    output reg         use_ra,
    output reg         use_rb,
    output reg         use_rd_as_src,

    output reg         wb_sel,

    output reg         is_nop,
    output reg         illegal_insn
);

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

    localparam       WB_SEL_EX_RESULT = 1'b0;
    localparam       WB_SEL_MEM_DATA  = 1'b1;

    wire [5:0] opcode         = instruction[31:26];
    wire [5:0] func           = instruction[5:0];
    wire [2:0] rtype_reserved = instruction[10:8];
    wire [1:0] instr_ww       = instruction[7:6];

    assign rd_idx = instruction[25:21];
    assign ra_idx = instruction[20:16];
    assign rb_idx = instruction[15:11];
    assign imm16  = instruction[15:0];

    always @* begin
        alu_op        = ALU_OP_NONE;
        ww            = 2'b00;

        reg_write_en  = 1'b0;
        mem_read_en   = 1'b0;
        mem_write_en  = 1'b0;

        branch_en     = 1'b0;
        branch_eqz    = 1'b0;
        branch_nez    = 1'b0;

        use_ra        = 1'b0;
        use_rb        = 1'b0;
        use_rd_as_src = 1'b0;

        wb_sel        = WB_SEL_EX_RESULT;

        is_nop        = 1'b0;
        illegal_insn  = 1'b0;

        case (opcode)
            OPCODE_RTYPE: begin
                if (rtype_reserved != 3'b000) begin
                    illegal_insn = 1'b1;
                end
                else begin
                    case (func)
                        FUNC_VAND: begin
                            alu_op       = ALU_OP_VAND;
                            ww           = instr_ww;
                            reg_write_en = 1'b1;
                            use_ra       = 1'b1;
                            use_rb       = 1'b1;
                            wb_sel       = WB_SEL_EX_RESULT;
                        end

                        FUNC_VOR: begin
                            alu_op       = ALU_OP_VOR;
                            ww           = instr_ww;
                            reg_write_en = 1'b1;
                            use_ra       = 1'b1;
                            use_rb       = 1'b1;
                            wb_sel       = WB_SEL_EX_RESULT;
                        end

                        FUNC_VXOR: begin
                            alu_op       = ALU_OP_VXOR;
                            ww           = instr_ww;
                            reg_write_en = 1'b1;
                            use_ra       = 1'b1;
                            use_rb       = 1'b1;
                            wb_sel       = WB_SEL_EX_RESULT;
                        end

                        FUNC_VNOT: begin
                            if (rb_idx != 5'b00000) begin
                                illegal_insn = 1'b1;
                            end
                            else begin
                                alu_op       = ALU_OP_VNOT;
                                ww           = instr_ww;
                                reg_write_en = 1'b1;
                                use_ra       = 1'b1;
                                wb_sel       = WB_SEL_EX_RESULT;
                            end
                        end

                        FUNC_VMOV: begin
                            if (rb_idx != 5'b00000) begin
                                illegal_insn = 1'b1;
                            end
                            else begin
                                alu_op       = ALU_OP_VMOV;
                                ww           = instr_ww;
                                reg_write_en = 1'b1;
                                use_ra       = 1'b1;
                                wb_sel       = WB_SEL_EX_RESULT;
                            end
                        end

                        FUNC_VADD: begin
                            alu_op       = ALU_OP_VADD;
                            ww           = instr_ww;
                            reg_write_en = 1'b1;
                            use_ra       = 1'b1;
                            use_rb       = 1'b1;
                            wb_sel       = WB_SEL_EX_RESULT;
                        end

                        FUNC_VSUB: begin
                            alu_op       = ALU_OP_VSUB;
                            ww           = instr_ww;
                            reg_write_en = 1'b1;
                            use_ra       = 1'b1;
                            use_rb       = 1'b1;
                            wb_sel       = WB_SEL_EX_RESULT;
                        end

                        FUNC_VMULEU: begin
                            if (instr_ww == 2'b11) begin
                                illegal_insn = 1'b1;
                            end
                            else begin
                                alu_op       = ALU_OP_VMULEU;
                                ww           = instr_ww;
                                reg_write_en = 1'b1;
                                use_ra       = 1'b1;
                                use_rb       = 1'b1;
                                wb_sel       = WB_SEL_EX_RESULT;
                            end
                        end

                        FUNC_VMULOU: begin
                            if (instr_ww == 2'b11) begin
                                illegal_insn = 1'b1;
                            end
                            else begin
                                alu_op       = ALU_OP_VMULOU;
                                ww           = instr_ww;
                                reg_write_en = 1'b1;
                                use_ra       = 1'b1;
                                use_rb       = 1'b1;
                                wb_sel       = WB_SEL_EX_RESULT;
                            end
                        end

                        FUNC_VSLL: begin
                            alu_op       = ALU_OP_VSLL;
                            ww           = instr_ww;
                            reg_write_en = 1'b1;
                            use_ra       = 1'b1;
                            use_rb       = 1'b1;
                            wb_sel       = WB_SEL_EX_RESULT;
                        end

                        FUNC_VSRL: begin
                            alu_op       = ALU_OP_VSRL;
                            ww           = instr_ww;
                            reg_write_en = 1'b1;
                            use_ra       = 1'b1;
                            use_rb       = 1'b1;
                            wb_sel       = WB_SEL_EX_RESULT;
                        end

                        FUNC_VSRA: begin
                            alu_op       = ALU_OP_VSRA;
                            ww           = instr_ww;
                            reg_write_en = 1'b1;
                            use_ra       = 1'b1;
                            use_rb       = 1'b1;
                            wb_sel       = WB_SEL_EX_RESULT;
                        end

                        FUNC_VRTTH: begin
                            if (rb_idx != 5'b00000) begin
                                illegal_insn = 1'b1;
                            end
                            else begin
                                alu_op       = ALU_OP_VRTTH;
                                ww           = instr_ww;
                                reg_write_en = 1'b1;
                                use_ra       = 1'b1;
                                wb_sel       = WB_SEL_EX_RESULT;
                            end
                        end

                        FUNC_VDIV: begin
                            alu_op       = ALU_OP_VDIV;
                            ww           = instr_ww;
                            reg_write_en = 1'b1;
                            use_ra       = 1'b1;
                            use_rb       = 1'b1;
                            wb_sel       = WB_SEL_EX_RESULT;
                        end

                        FUNC_VMOD: begin
                            alu_op       = ALU_OP_VMOD;
                            ww           = instr_ww;
                            reg_write_en = 1'b1;
                            use_ra       = 1'b1;
                            use_rb       = 1'b1;
                            wb_sel       = WB_SEL_EX_RESULT;
                        end

                        FUNC_VSQEU: begin
                            if (rb_idx != 5'b00000) begin
                                illegal_insn = 1'b1;
                            end
                            else if (instr_ww == 2'b11) begin
                                illegal_insn = 1'b1;
                            end
                            else begin
                                alu_op       = ALU_OP_VSQEU;
                                ww           = instr_ww;
                                reg_write_en = 1'b1;
                                use_ra       = 1'b1;
                                wb_sel       = WB_SEL_EX_RESULT;
                            end
                        end

                        FUNC_VSQOU: begin
                            if (rb_idx != 5'b00000) begin
                                illegal_insn = 1'b1;
                            end
                            else if (instr_ww == 2'b11) begin
                                illegal_insn = 1'b1;
                            end
                            else begin
                                alu_op       = ALU_OP_VSQOU;
                                ww           = instr_ww;
                                reg_write_en = 1'b1;
                                use_ra       = 1'b1;
                                wb_sel       = WB_SEL_EX_RESULT;
                            end
                        end

                        FUNC_VSQRT: begin
                            if (rb_idx != 5'b00000) begin
                                illegal_insn = 1'b1;
                            end
                            else begin
                                alu_op       = ALU_OP_VSQRT;
                                ww           = instr_ww;
                                reg_write_en = 1'b1;
                                use_ra       = 1'b1;
                                wb_sel       = WB_SEL_EX_RESULT;
                            end
                        end

                        default: begin
                            illegal_insn = 1'b1;
                        end
                    endcase
                end
            end

            OPCODE_VLD: begin
                if (ra_idx != 5'b00000) begin
                    illegal_insn = 1'b1;
                end
                else begin
                    alu_op       = ALU_OP_NONE;
                    reg_write_en = 1'b1;
                    mem_read_en  = 1'b1;
                    wb_sel       = WB_SEL_MEM_DATA;
                end
            end

            OPCODE_VSD: begin
                if (ra_idx != 5'b00000) begin
                    illegal_insn = 1'b1;
                end
                else begin
                    alu_op        = ALU_OP_NONE;
                    mem_write_en  = 1'b1;
                    use_rd_as_src = 1'b1;
                end
            end

            OPCODE_VBEZ: begin
                if (ra_idx != 5'b00000) begin
                    illegal_insn = 1'b1;
                end
                else begin
                    alu_op        = ALU_OP_NONE;
                    branch_en     = 1'b1;
                    branch_eqz    = 1'b1;
                    use_rd_as_src = 1'b1;
                end
            end

            OPCODE_VBNEZ: begin
                if (ra_idx != 5'b00000) begin
                    illegal_insn = 1'b1;
                end
                else begin
                    alu_op        = ALU_OP_NONE;
                    branch_en     = 1'b1;
                    branch_nez    = 1'b1;
                    use_rd_as_src = 1'b1;
                end
            end

            OPCODE_VNOP: begin
                if (instruction == 32'b111100_00000_00000_00000_00000_000000) begin
                    alu_op = ALU_OP_NONE;
                    is_nop = 1'b1;
                end
                else begin
                    illegal_insn = 1'b1;
                end
            end

            default: begin
                illegal_insn = 1'b1;
            end
        endcase
    end

endmodule

`default_nettype wire