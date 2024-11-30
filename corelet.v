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
	wire [(col*psum_bw)-1:0] sfp_out_temp;  // One SFP per column

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

	// Instantiate one SFP per column
	genvar i;
	generate
    	for (i = 0; i < col; i = i + 1) begin : sfp_inst
        	sfp #(
            	.psum_bw(psum_bw)
        	) sfp_inst (
            	.clk(clk),
            	.reset(reset),
            	.en(sfp_en),
            	.acc_clear(sfp_acc_clear),
            	.relu_en(sfp_relu_en),
            	.data_in(ofifo_out[(i+1)*psum_bw-1:i*psum_bw]),
            	.data_valid(ofifo_valid),
            	.data_out(sfp_out_temp[(i+1)*psum_bw-1:i*psum_bw]),
            	.out_valid()  // Connect if needed
        	);
    	end
	endgenerate

	// Direct assignment of SFP outputs
	assign sfp_out = sfp_out_temp;

	// Debug signals
	always @(posedge clk) begin
    	if (mac_array_en) begin
        	$display("MAC Array: valid=%b", ofifo_wr);
        	$display("MAC Array out: %h", array_to_ofifo);
        	$display("OFIFO out: %h", ofifo_out);
        	$display("SFP out: %h", sfp_out);
    	end
	end

endmodule



