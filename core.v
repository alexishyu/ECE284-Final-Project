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
	output wire [col*16-1:0] sfp_out
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
	wire ififo_wr = inst[5];
	wire ififo_rd = inst[4];
	wire l0_rd = inst[3];
	wire l0_wr = inst[2];
	wire execute = inst[1];
	wire load = inst[0];

	// Internal signals
	wire [(row*bw)-1:0] l0_to_array;
	wire [(col*16)-1:0] array_to_ofifo;
	wire [31:0] act_sram_out;
	wire [31:0] weight_sram_out;
	wire [31:0] psum_sram_out;

	// Instantiate activation SRAM
	sram_32b_w2048 act_sram (
    	.CLK(clk),
    	.D(32'b0),
    	.Q(act_sram_out),
    	.CEN(CEN_xmem),
    	.WEN(WEN_xmem),
    	.A(A_xmem)
	);

	// Instantiate weight SRAM
	sram_32b_w2048 weight_sram (
    	.CLK(clk),
    	.D({{(32-bw*row){1'b0}}, D_xmem}),
    	.Q(weight_sram_out),
    	.CEN(CEN_xmem),
    	.WEN(WEN_xmem),
    	.A(A_xmem)
	);

	// Instantiate psum SRAM
	sram_32b_w2048 psum_sram (
    	.CLK(clk),
    	.D(32'b0),
    	.Q(psum_sram_out),
    	.CEN(CEN_pmem),
    	.WEN(WEN_pmem),
    	.A(A_pmem)
	);

	// Instantiate corelet
	corelet #(
    	.row(row),
    	.col(col),
    	.bw(bw),
    	.psum_bw(16)
	) corelet_inst (
    	.clk(clk),
    	.reset(reset),
    	.mac_array_en(execute),
    	.l0_in(weight_sram_out[(row*bw)-1:0]),
    	.l0_rd(l0_rd),
    	.l0_wr(l0_wr),
    	.l0_full(),
    	.l0_ready(),
    	.act_in(act_sram_out[(col*bw)-1:0]),
    	.ofifo_rd(ofifo_rd),
    	.ofifo_out(array_to_ofifo),
    	.ofifo_full(),
    	.ofifo_ready(),
    	.ofifo_valid(ofifo_valid),
    	.sfp_en(execute),
    	.sfp_acc_clear(~execute),
    	.sfp_relu_en(1'b1),
    	.sfp_out(sfp_out)
	);

endmodule
