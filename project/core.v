module core #(
    parameter bw = 4,
    parameter col = 8,
    parameter row = 8
)(
    input  wire clk,
    input  wire reset,
    input  wire [33:0] inst,
    input  wire [bw*row-1:0] D_xmem,
    output wire ofifo_valid,
    output wire [col*16-1:0] sfp_out,
    output wire [31:0] xmem_out
);

    // Extract control signals from instruction
    wire acc = inst[33];
    wire CEN_pmem = inst[32];
    wire WEN_pmem = inst[31];
    wire [10:0] A_pmem = inst[30:20];
    wire CEN_xmem = inst[19];
    wire WEN_xmem = inst[18];
    wire [10:0] A_xmem = inst[17:7];
    wire ofifo_rd = inst[6];
    wire ififo_rd = inst[4];
    wire l0_rd = inst[3];
    wire l0_wr = inst[2];
    wire execute = inst[1];
    wire load = inst[0];

    // Internal signals
    wire [(row*bw)-1:0] l0_to_array;
    wire [(col*16)-1:0] array_to_ofifo;
    wire [col*16-1:0] ofifo_out;
    wire [col*16-1:0] sfp_to_psum;
    wire [127:0] psum_sram_out;
    wire [col-1:0] ofifo_wr;
    wire ofifo_full;
    wire ofifo_ready;
    wire [(col*bw)-1:0] act_in;
    wire [(row*bw)-1:0] l0_in;

    // Generate IFIFO write enable during execution
    wire ififo_wr = execute;

    // Synchronize psum SRAM control signals
    reg CEN_pmem_d, WEN_pmem_d;
    reg [10:0] A_pmem_d;

    always @(posedge clk) begin
        CEN_pmem_d <= CEN_pmem;
        WEN_pmem_d <= WEN_pmem;
        A_pmem_d <= A_pmem;
    end

    // Original assignments
    assign l0_in = (l0_wr || execute) ? xmem_out[(row*bw)-1:0] : {((row*bw)){1'b0}};

    // Instantiate xmem SRAM
    sram_32b_w2048 xmem (
        .CLK(clk),
        .D(D_xmem),
        .Q(xmem_out),
        .CEN(CEN_xmem),
        .WEN(WEN_xmem),
        .A(A_xmem)
    );

    // Instantiate psum SRAM with SFP output
    sram_128b_w2048 psum (
        .CLK(clk),
        .D(sfp_to_psum),    // Changed to use SFP output
        .Q(psum_sram_out),
        .CEN(CEN_pmem_d),
        .WEN(WEN_pmem_d),
        .A(A_pmem_d)
    );

    // Corelet instantiation
    corelet #(
        .row(row),
        .col(col),
        .bw(bw),
        .psum_bw(16)
    ) corelet_inst (
        .clk(clk),
        .reset(reset),
        .mac_array_en(execute),
        .l0_in(l0_in),
        .l0_rd(l0_rd),
        .l0_wr(l0_wr),
        .l0_full(),
        .l0_ready(),
        .act_in(ififo_out),
        .ofifo_rd(ofifo_rd),
        .ofifo_out(ofifo_out),
        .ofifo_full(ofifo_full),
        .ofifo_ready(ofifo_ready),
        .ofifo_valid(ofifo_valid),
        .sfp_en(execute),
        .sfp_acc_clear(~execute),
        .sfp_relu_en(1'b1),
        .sfp_out(sfp_to_psum),  // Connect to new wire
        .load(load),
        .execute(execute)
    );

    // Keep sfp_out as separate output for testbench
    assign sfp_out = sfp_to_psum;

    // Debug signals
    always @(posedge clk) begin
        if (execute) begin
            $display("OFIFO out: %h", ofifo_out);
            $display("SFP out: %h", sfp_to_psum);
        end
        if (!CEN_pmem_d && !WEN_pmem_d)
            $display("PSUM write: addr=%h data=%h", A_pmem_d, sfp_to_psum);
    end

endmodule