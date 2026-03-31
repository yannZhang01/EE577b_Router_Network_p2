`timescale 1ns/1ps
`default_nettype none

module cardinal_cpu (
    input  wire        clk,
    input  wire        reset,
    input  wire [0:31] inst_in,
    input  wire [0:63] d_in,
    output wire [0:31] pc_out,
    output wire [0:31] addr_out,
    output wire        memEn,
    output wire        memWrEn,
    output wire [0:63] d_out
);

    // Virtual NOP used when IF/ID is invalid or flushed
    localparam [31:0] INST_VNOP = 32'b111100_00000_00000_00000_00000_000000;

    // Write-back data source selection
    localparam        WB_SEL_EX_RESULT = 1'b0;
    localparam        WB_SEL_MEM_DATA  = 1'b1;

    // ============================================================
    // IF stage
    // - Hold current PC
    // - Select next PC from sequential path or branch target
    // - Freeze PC when decode detects a hazard stall
    // ============================================================
    reg  [31:0] if_pc_reg;
    wire [31:0] if_instruction_in;
    wire [31:0] if_pc_plus_4;
    wire [31:0] if_pc_next;
    wire        id_hazard_stall;
    wire        id_branch_taken;
    wire [31:0] id_branch_target_pc;

    assign if_instruction_in = inst_in;

    // Instruction address is byte addressed, so normal step is +4
    assign if_pc_plus_4 = if_pc_reg + 32'd4;

    // Branch redirect has priority over sequential fetch
    assign if_pc_next = id_branch_taken ? id_branch_target_pc : if_pc_plus_4;

    // Expose current fetch PC to instruction memory
    assign pc_out = if_pc_reg;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            if_pc_reg <= 32'h0000_0000;
        end else if (!id_hazard_stall) begin
            if_pc_reg <= if_pc_next;
        end
    end

    // ============================================================
    // IF/ID register
    // - Latch fetched instruction
    // - Hold state during hazard stall
    // - Invalidate on taken branch to flush wrong-path instruction
    // ============================================================
    reg        ifid_valid;
    reg [31:0] ifid_instruction;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ifid_valid <= 1'b0;
            ifid_instruction <= 32'h0000_0000;
        end else if (id_hazard_stall) begin
            // Hold IF/ID contents when decode cannot issue
            ifid_valid <= ifid_valid;
            ifid_instruction <= ifid_instruction;
        end else if (id_branch_taken) begin
            // Flush the instruction already fetched after branch resolves
            ifid_valid <= 1'b0;
            ifid_instruction <= 32'h0000_0000;
        end else begin
            ifid_valid <= 1'b1;
            ifid_instruction <= if_instruction_in;
        end
    end

    // ============================================================
    // ID stage
    // - Decode instruction fields and control signals
    // - Read register file operands
    // - Detect RAW hazard against ID/EX-MEM stage
    // - Resolve branch in ID stage
    // - Generate direct data memory control for load/store
    // ============================================================
    wire [31:0] id_instruction;
    wire [4:0]  id_rd_idx;
    wire [4:0]  id_ra_idx;
    wire [4:0]  id_rb_idx;
    wire [15:0] id_imm16;
    wire [1:0]  id_ww;
    wire [5:0]  id_alu_op;

    wire        id_reg_write_en;
    wire        id_mem_read_en;
    wire        id_mem_write_en;
    wire        id_branch_en;
    wire        id_branch_eqz;
    wire        id_branch_nez;

    wire        id_use_ra;
    wire        id_use_rb;
    wire        id_use_rd_as_src;

    wire        id_wb_sel;
    wire        id_is_nop;
    wire        id_illegal_insn;

    wire [4:0]  id_regfile_raddr1;
    wire [4:0]  id_regfile_raddr2;
    wire [63:0] id_regfile_rdata1;
    wire [63:0] id_regfile_rdata2;

    wire [63:0] id_operand_a;
    wire [63:0] id_operand_b;
    wire [63:0] id_store_data;
    wire [63:0] id_branch_data;
    wire        id_issue_valid;
    
    wire        id_dmem_mem_en;
    wire        id_dmem_mem_wr_en;
    wire [31:0] id_dmem_addr;
    wire [63:0] id_dmem_data_out;

    // When IF/ID is invalid, decode a virtual NOP to simplify control
    assign id_instruction = ifid_valid ? ifid_instruction : INST_VNOP;

    // Read port 1 always maps to ra
    assign id_regfile_raddr1 = id_ra_idx;

    // Read port 2 maps to rb normally, or rd for instructions that reuse rd as a source
    assign id_regfile_raddr2 = id_use_rd_as_src ? id_rd_idx : id_rb_idx;

    // Unused sources are forced to zero to keep downstream logic clean
    assign id_operand_a = id_use_ra ? id_regfile_rdata1 : 64'h0000_0000_0000_0000;
    assign id_operand_b = id_use_rb ? id_regfile_rdata2 : 64'h0000_0000_0000_0000;

    // Store and branch source data both come from the second read port in rd-as-src mode
    assign id_store_data  = id_use_rd_as_src ? id_regfile_rdata2 : 64'h0000_0000_0000_0000;
    assign id_branch_data = id_use_rd_as_src ? id_regfile_rdata2 : 64'h0000_0000_0000_0000;

    reg        idexmem_valid;
    reg        idexmem_reg_write_en;
    reg [4:0]  idexmem_rd_idx;
    // Simple RAW hazard detection against the single in-flight EX/MEM writeback destination
    assign id_hazard_stall = ifid_valid && idexmem_valid && idexmem_reg_write_en && (idexmem_rd_idx != 5'd0) && (
                             (id_use_ra        && (id_ra_idx == idexmem_rd_idx)) ||
                             (id_use_rb        && (id_rb_idx == idexmem_rd_idx)) ||
                             (id_use_rd_as_src && (id_rd_idx == idexmem_rd_idx)));

    // Branch target is formed directly from zero-extended imm16
    assign id_branch_target_pc = {16'h0000, id_imm16};

    // Branch resolves in ID stage after operand read and hazard check
    assign id_branch_taken = ifid_valid && !id_hazard_stall && !id_illegal_insn && id_branch_en &&
                             ((id_branch_eqz && (id_branch_data == 64'h0000_0000_0000_0000)) ||
                              (id_branch_nez && (id_branch_data != 64'h0000_0000_0000_0000)));

    // Instruction can issue only when it is valid and not blocked or filtered out
    assign id_issue_valid = ifid_valid && !id_hazard_stall && !id_branch_taken && !id_illegal_insn && !id_is_nop;

    // This design drives data memory directly from ID stage for load/store operations
    assign id_dmem_mem_en    = id_issue_valid && (id_mem_read_en || id_mem_write_en);
    assign id_dmem_mem_wr_en = id_issue_valid && id_mem_write_en;
    assign id_dmem_addr      = id_dmem_mem_en ? {16'h0000, id_imm16} : 32'h0000_0000;
    assign id_dmem_data_out  = id_dmem_mem_wr_en ? id_store_data : 64'h0000_0000_0000_0000;

    instruction_decode u_instruction_decode (
        .instruction   (id_instruction),
        .alu_op        (id_alu_op),
        .rd_idx        (id_rd_idx),
        .ra_idx        (id_ra_idx),
        .rb_idx        (id_rb_idx),
        .imm16         (id_imm16),
        .ww            (id_ww),
        .reg_write_en  (id_reg_write_en),
        .mem_read_en   (id_mem_read_en),
        .mem_write_en  (id_mem_write_en),
        .branch_en     (id_branch_en),
        .branch_eqz    (id_branch_eqz),
        .branch_nez    (id_branch_nez),
        .use_ra        (id_use_ra),
        .use_rb        (id_use_rb),
        .use_rd_as_src (id_use_rd_as_src),
        .wb_sel        (id_wb_sel),
        .is_nop        (id_is_nop),
        .illegal_insn  (id_illegal_insn)
    );

    // External data memory interface
    assign memEn    = id_dmem_mem_en;
    assign memWrEn  = id_dmem_mem_wr_en;
    assign addr_out = id_dmem_addr;
    assign d_out    = id_dmem_data_out;

    // ============================================================
    // ID/EX-MEM register
    // - Carry execution and write-back control into EX-MEM stage
    // - Insert bubble when ID cannot issue
    // ============================================================
    reg [5:0]  idexmem_alu_op;
    reg [1:0]  idexmem_ww;
    reg        idexmem_wb_sel;
    reg [63:0] idexmem_operand_a;
    reg [63:0] idexmem_operand_b;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            idexmem_valid <= 1'b0;
            idexmem_rd_idx <= 5'd0;
            idexmem_alu_op <= 6'd0;
            idexmem_ww <= 2'b00;
            idexmem_reg_write_en <= 1'b0;
            idexmem_wb_sel <= WB_SEL_EX_RESULT;
            idexmem_operand_a <= 64'h0000_0000_0000_0000;
            idexmem_operand_b <= 64'h0000_0000_0000_0000;
        end else if (id_issue_valid) begin
            idexmem_valid <= 1'b1;
            idexmem_rd_idx <= id_rd_idx;
            idexmem_alu_op <= id_alu_op;
            idexmem_ww <= id_ww;
            idexmem_reg_write_en <= id_reg_write_en;
            idexmem_wb_sel <= id_wb_sel;
            idexmem_operand_a <= id_operand_a;
            idexmem_operand_b <= id_operand_b;
        end else begin
            // Clear the stage when no instruction is issued
            idexmem_valid <= 1'b0;
            idexmem_rd_idx <= 5'd0;
            idexmem_alu_op <= 6'd0;
            idexmem_ww <= 2'b00;
            idexmem_reg_write_en <= 1'b0;
            idexmem_wb_sel <= WB_SEL_EX_RESULT;
            idexmem_operand_a <= 64'h0000_0000_0000_0000;
            idexmem_operand_b <= 64'h0000_0000_0000_0000;
        end
    end

    // ============================================================
    // EX-MEM stage
    // - Execute ALU operation
    // - Receive load data from external memory input
    // - Select final write-back data with a mux
    // - No extra register exists between this stage and WB
    // ============================================================
    wire [63:0] exmem_alu_result;
    wire        exmem_alu_valid;
    wire [63:0] exmem_dmem_data;
    wire [63:0] exmem_wb_data;
    wire        exmem_wb_write_en;

    // Load data returns from data memory input directly into EX-MEM/WB mux path
    assign exmem_dmem_data = d_in;

    // Final write-back source: memory data for loads, ALU result otherwise
    assign exmem_wb_data = (idexmem_wb_sel == WB_SEL_MEM_DATA) ? exmem_dmem_data : exmem_alu_result;

    // A write-back is allowed for valid instructions with reg write enabled
    // For memory path, data is assumed valid on d_in
    // For ALU path, the ALU valid signal must be asserted
    assign exmem_wb_write_en = idexmem_valid && idexmem_reg_write_en &&
                               ((idexmem_wb_sel == WB_SEL_MEM_DATA) || exmem_alu_valid);

    cardinal_alu u_cardinal_alu (
        .rA         (idexmem_operand_a),
        .rB         (idexmem_operand_b),
        .ww         (idexmem_ww),
        .funct_6bit (idexmem_alu_op),
        .rD         (exmem_alu_result),
        .valid      (exmem_alu_valid)
    );

    // ============================================================
    // WB stage
    // - Drive register file write port directly from EX-MEM stage output
    // - No dedicated WB register in this implementation
    // ============================================================
    wire [4:0]  wb_regfile_waddr;
    wire [63:0] wb_regfile_wdata;
    wire        wb_regfile_wr_en;

    assign wb_regfile_waddr = idexmem_rd_idx;
    assign wb_regfile_wdata = exmem_wb_data;
    assign wb_regfile_wr_en = exmem_wb_write_en;

    regfile32x64 u_regfile32x64 (
        .clk    (clk),
        .rst    (reset),
        .wrEn   (wb_regfile_wr_en),
        .waddr  (wb_regfile_waddr),
        .wdata  (wb_regfile_wdata),
        .raddr1 (id_regfile_raddr1),
        .rdata1 (id_regfile_rdata1),
        .raddr2 (id_regfile_raddr2),
        .rdata2 (id_regfile_rdata2)
    );

endmodule

`default_nettype wire