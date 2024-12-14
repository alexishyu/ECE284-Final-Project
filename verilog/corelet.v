module corelet #(
	parameter bw = 4,
	parameter psum_bw = 16,
	parameter col = 8,
	parameter row = 8
)(
	input wire clk,
	input wire reset,
	input wire execute,
	input wire load,
	input wire [bw*row-1:0] data_to_l0,
	input wire [bw*col-1:0] data_to_ififo,
	input wire l0_rd,
	input wire l0_wr,
	input wire ififo_rd,
	input wire ififo_wr,
	input wire output_enable,
	output wire l0_full,
	output wire l0_ready,
	input wire ofifo_rd,
	output wire ofifo_full,
	output wire ofifo_ready,
	output wire ofifo_valid,
	output wire [psum_bw*col-1:0] psum_out,
	input wire [psum_bw*col-1:0] sram_to_sfu,
	input wire accumulate,
	input wire relu,
	input wire mode,
	output wire [psum_bw*col-1:0] data_out
);

	wire [row*bw-1:0] data_out_l0;
	wire [psum_bw*col-1:0] mac_out;
	wire [col-1:0] mac_out_valid;
	wire [psum_bw*col-1:0] in_n;
	wire [psum_bw*col-1:0] sfp_out_temp;
	wire [bw*col-1:0] ififo_to_mac;
	wire [psum_bw*col*row-1:0] tile_outputs;
	wire [psum_bw*col-1:0] ofifo_input;
	wire row_valid;

	assign in_n = {(psum_bw*col){1'b0}};

	l0 #(.row(row), .bw(bw)) l0_inst (
		.clk(clk),
		.reset(reset),
		.in(data_to_l0),
		.out(data_out_l0),
		.rd(l0_rd),
		.wr(l0_wr),
		.o_full(l0_full),
		.o_ready(l0_ready)
	);

	ififo #(.col(col), .bw(psum_bw)) ififo_inst (
		.clk(clk),
		.reset(reset),
		.in(data_to_ififo),
		.out(ififo_to_mac),
		.rd(ififo_rd),
		.wr(ififo_wr),
		.i_full(ofifo_full),
		.i_ready(ofifo_ready),
		.i_valid(ofifo_valid)
	);

	ofifo #(.col(col), .bw(psum_bw)) ofifo_inst (
		.clk(clk),
		.reset(reset),
		.in(mac_out),
		.out(psum_out),
		.rd(ofifo_rd),
		.wr(mac_out_valid),
		.o_full(ofifo_full),
		.o_ready(ofifo_ready),
		.o_valid(ofifo_valid)
	);

	mac_array #(.bw(bw), .psum_bw(psum_bw), .col(col), .row(row)) mac_array_inst (
		.clk(clk),
		.reset(reset),
		.in_w(data_out_l0),
		.in_n(ififo_to_mac),
		.inst_w({execute, load}),
		.out_s(mac_out),
		.valid(mac_out_valid),
		.mode(mode),
		.output_enable(output_enable),
		.tile_outputs(tile_outputs),
		.ofifo_input(ofifo_input),
		.row_valid(row_valid)
	);



	genvar i;
	generate
		for (i = 0; i < col; i = i + 1) begin : sfp_inst
			sfp #(.psum_bw(psum_bw)) sfp_instance (
				.clk(clk),
				.reset(reset),
				.acc(accumulate),
				.relu_en(relu),
				.data_in(sram_to_sfu[psum_bw*(i+1)-1:psum_bw*i]),
				.data_out(sfp_out_temp[psum_bw*(i+1)-1:psum_bw*i])
			);
		end
	endgenerate

	assign data_out = sfp_out_temp;

endmodule



