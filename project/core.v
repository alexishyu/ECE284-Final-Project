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

    // Generate IFIFO write enable during execution
    wire ififo_wr = execute;  // Write to IFIFO during execution phase

    // Internal signals
    wire [(row*bw)-1:0] l0_to_array;
    wire [(col*16)-1:0] array_to_ofifo;
    wire [127:0] psum_sram_out;


    // Logic to select data for act_in and l0_in
    wire [(col*bw)-1:0] act_in;
    wire [(row*bw)-1:0] l0_in;

    reg [31:0] xmem_out_d1;
	always @(posedge clk) begin
		xmem_out_d1 <= xmem_out;
	end

	// Debug signals
	reg [(col*bw)-1:0] act_in_debug;
	reg [(row*bw)-1:0] l0_in_debug;

	always @(posedge clk) begin
		act_in_debug <= act_in;
		l0_in_debug <= l0_in;
		if (execute)
			$display("act_in=%h, xmem_out_d1=%h", act_in, xmem_out_d1);
		if (load)
			$display("l0_in=%h, xmem_out=%h", l0_in, xmem_out);
	end

	// Original assignments
	assign l0_in = (l0_wr || execute) ? xmem_out[(row*bw)-1:0] : {((row*bw)){1'b0}};
	
	// Instantiate xmem SRAM (for both activation and weight data)
	sram_32b_w2048 xmem (
		.CLK(clk),
		.D(D_xmem),
		.Q(xmem_out),
		.CEN(CEN_xmem),
		.WEN(WEN_xmem),
		.A(A_xmem)
	);
	
	sram_128b_w2048 psum (
		.CLK(clk),
		.D(ofifo_out),
		.Q(psum_sram_out),
		.CEN(CEN_pmem),
		.WEN(WEN_pmem),
		.A(A_xmem)
	);



    // Add IFIFO signals
    wire [(col*bw)-1:0] ififo_out;
    wire ififo_full, ififo_ready;
    wire [col-1:0] ififo_wr_vec;  // Individual write enables for each column

    // Generate write enable vector for IFIFO
    assign ififo_wr_vec = {col{ififo_wr}};  // Broadcast ififo_wr to all columns

    // Instantiate IFIFO
    ofifo #(
        .col(col),
        .bw(bw)
    ) ififo_inst (
        .clk(clk),
        .reset(reset),
        .in(act_in),           // Input from memory
        .out(ififo_out),       // Output to systolic array
        .wr(ififo_wr_vec),     // Write enable vector
        .rd(ififo_rd),         // Read enable
        .o_full(ififo_full),
        .o_ready(ififo_ready),
        .o_valid()             // Leave unconnected if not needed
    );

    // Modify corelet instantiation to use IFIFO output
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
        .act_in(ififo_out),    // Changed from act_in to ififo_out
        .ofifo_rd(ofifo_rd),
        .ofifo_out(array_to_ofifo),
        .ofifo_full(),
        .ofifo_ready(),
        .ofifo_valid(ofifo_valid),
        .sfp_en(execute),
        .sfp_acc_clear(~execute),
        .sfp_relu_en(1'b1),
        .sfp_out(sfp_out),
        .load(load),
        .execute(execute)
    );

endmodule






