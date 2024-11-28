module corelet #(
	parameter row = 8,
	parameter col = 8,
	parameter bw = 4,
	parameter psum_bw = 16
)(
	input  wire clk,
	input  wire reset,
	input  wire mac_array_en,
	// L0 interface
	input  wire [(row*bw)-1:0] l0_in,
	input  wire l0_rd,
	input  wire l0_wr,
	output wire l0_full,
	output wire l0_ready,
	// Activation interface
	input  wire [(col*bw)-1:0] act_in,
	// OFIFO interface
	input  wire ofifo_rd,
	output wire [(col*psum_bw)-1:0] ofifo_out,
	output wire ofifo_full,
	output wire ofifo_ready,
	output wire ofifo_valid,
	// SFP interface
	input  wire sfp_en,
	input  wire sfp_acc_clear,
	input  wire sfp_relu_en,
	output wire [(col*psum_bw)-1:0] sfp_out
);

	// Internal signals
	wire [(row*bw)-1:0] l0_to_array;
	wire [(psum_bw*col)-1:0] array_to_ofifo;
	wire [col-1:0] ofifo_wr;
	wire [31:0] sfp_in;
	wire sfp_in_valid;
	wire sfp_out_valid;

	// Width adjustment for SFP input
	reg [2:0] sfp_input_sel;
    
	always @(posedge clk) begin
    	if (reset)
        	sfp_input_sel <= 3'd0;
    	else if (ofifo_valid) begin
        	if (sfp_input_sel == col-1)
            	sfp_input_sel <= 3'd0;
        	else
            	sfp_input_sel <= sfp_input_sel + 1;
    	end
	end

	// Select 32-bit chunk from OFIFO output based on selector
	assign sfp_in = ofifo_out[sfp_input_sel*16 +: 16];
	assign sfp_in_valid = ofifo_valid;

	// Instantiate L0 FIFO
	l0 #(.row(row), .bw(bw)) l0_inst (
    	.clk(clk),
    	.in(l0_in),
    	.out(l0_to_array),
    	.rd(l0_rd),
    	.wr(l0_wr),
    	.o_full(l0_full),
    	.reset(reset),
    	.o_ready(l0_ready)
	);

	// Instantiate MAC array
	mac_array #(
    	.row(row),
    	.col(col),
    	.bw(bw),
    	.psum_bw(psum_bw)
	) mac_array_inst (
    	.clk(clk),
    	.reset(reset),
    	.in_w(l0_to_array),
    	.in_n({(psum_bw*col){1'b0}}),
    	.inst_w({mac_array_en, 1'b1}),
    	.out_s(array_to_ofifo),
    	.valid(ofifo_wr)
	);

	// Width adjustment for OFIFO input
	wire [(col*psum_bw)-1:0] ofifo_data;
	assign ofifo_data = array_to_ofifo;

	// Width adjustment for SFP output
	wire [31:0] sfp_out_temp;
	reg [(col*psum_bw)-1:0] sfp_out_reg;
    
	always @(posedge clk) begin
    	if (reset)
        	sfp_out_reg <= 0;
    	else if (sfp_out_valid)
        	sfp_out_reg[(sfp_input_sel*psum_bw) +: psum_bw] <= sfp_out_temp[15:0];
	end
    
	assign sfp_out = sfp_out_reg;

	// Instantiate SFP
	sfp sfp_inst (
    	.clk(clk),
    	.reset(reset),
    	.en(sfp_en),
    	.acc_clear(sfp_acc_clear),
    	.relu_en(sfp_relu_en),
    	.data_in(sfp_in),
    	.data_valid(sfp_in_valid),
    	.data_out(sfp_out_temp),
    	.out_valid(sfp_out_valid)
	);

	// Instantiate output FIFO
	ofifo #(.col(col), .bw(psum_bw)) ofifo_inst (
    	.clk(clk),
    	.in(ofifo_data),
    	.out(ofifo_out),
    	.rd(ofifo_rd),
    	.wr(ofifo_wr),
    	.o_full(ofifo_full),
    	.reset(reset),
    	.o_ready(ofifo_ready),
    	.o_valid(ofifo_valid)
	);

endmodule
