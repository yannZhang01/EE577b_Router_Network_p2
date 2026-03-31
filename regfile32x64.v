module regfile32x64 (
    input  wire        clk,
    input  wire        rst,      
    input  wire        wrEn,

    input  wire [4:0]  waddr,
    input  wire [63:0] wdata,

    input  wire [4:0]  raddr1,
    output wire [63:0] rdata1,

    input  wire [4:0]  raddr2,
    output wire [63:0] rdata2
);

    reg [63:0] regs [0:31];
    integer i;

    // Synchronous write, reset clears all registers
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 64'h0000_0000_0000_0000;
        end else begin
            if (wrEn && (waddr != 5'd0)) begin
                regs[waddr] <= wdata;
            end
            regs[0] <= 64'h0000_0000_0000_0000; // keep x0 hard-wired to zero
        end
    end

    // Asynchronous reads
    assign rdata1 = (raddr1 == 5'd0) ? 64'h0000_0000_0000_0000 : regs[raddr1];
    assign rdata2 = (raddr2 == 5'd0) ? 64'h0000_0000_0000_0000 : regs[raddr2];

endmodule