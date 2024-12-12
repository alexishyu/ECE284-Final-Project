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
    output wire [psum_bw*col-1:0] data_out,
    input wire mode,
    input wire ififo_wr,
	input wire ififo_rd,
    output wire [psum_bw*col*row-1:0] tile_array_out
);

    wire [row*bw-1:0] data_out_l0;
    wire [col*bw-1:0] data_out_ififo;
    wire [row*bw-1:0] mac_array_in_w;
    wire [psum_bw*col-1:0] mac_out_psum;
    wire [col-1:0] mac_out_valid;
    wire [psum_bw*col-1:0] in_n;
    wire [psum_bw*col-1:0] sfp_out_temp;
    wire ififo_full;
    wire ififo_ready;
    wire ififo_valid;

    assign in_n = mode ? data_out_ififo : {(psum_bw*col){1'b0}};
    assign mac_array_in_w = data_out_l0;

    // Rest of the module remains the same with instance connections

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

	ififo #(.col(col), .bw(bw)) ififo_inst (
		.clk(clk),
		.reset(reset),
		.in(data_to_ififo),
		.out(data_out_ififo),
		.rd(ififo_rd),
		.wr(ififo_wr),
		.o_full(ififo_full),
		.o_ready(ififo_ready),
		.o_valid(ififo_valid)
	);

	assign mac_array_in_w = data_out_l0;

	ofifo #(.col(col), .bw(psum_bw)) ofifo_inst (
		.clk(clk),
		.reset(reset),
		.in(mode ? tile_array_out[psum_bw*col-1:0] : mac_out_psum),
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
		.in_w(mac_array_in_w),
		.in_n(in_n),
		.inst_w({execute, load}),
		.out_s(mac_out_psum),
		.valid(mac_out_valid),
		.mode(mode),
		.tile_array_out(tile_array_out)
	);

	assign mac_out = mode ? {{(psum_bw-bw){1'b0}}, mac_out_weight} : mac_out_psum;

	genvar i;
	generate
		for (i = 0; i < col; i = i + 1) begin : sfp_inst
			sfp #(.col(1), .bw(psum_bw)) sfp_instance (
				.clk(clk),
				.reset(reset),
				.acc(accumulate),
				.relu_en(relu),
				.data_in(sram_to_sfu[psum_bw*(i+1)-1:psum_bw*i]),
				.acc_data(sram_to_sfu[psum_bw*(i+1)-1:psum_bw*i]),
				.data_out(data_out[psum_bw*(i+1)-1:psum_bw*i]),
				.mode(mode)
			);
		end
	endgenerate

endmodule



