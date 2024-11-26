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

    // Extract control signals from inst
    wire mac_array_en = inst[1];
    wire l0_rd = inst[3];
    wire l0_wr = inst[2];
    wire ofifo_rd = inst[6];
    wire sfp_en = inst[1];
    wire sfp_acc_clear = inst[33];
    wire sfp_relu_en = inst[0];

    // Internal signals
    wire [(row*bw)-1:0] l0_to_array;
    wire [(16*col)-1:0] array_to_ofifo;
    wire [col-1:0] ofifo_wr;
    wire l0_full, l0_ready, ofifo_full, ofifo_ready;

    // Instantiate L0 FIFO
    l0 #(.row(row), .bw(bw)) l0_inst (
        .clk(clk),
        .in(D_xmem),
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
        .psum_bw(16)
    ) mac_array_inst (
        .clk(clk),
        .reset(reset),
        .in_w(l0_to_array),
        .in_n({96'b0, D_xmem}),
        .inst_w({mac_array_en, 1'b1}),
        .out_s(array_to_ofifo),
        .valid(ofifo_wr)
    );

    // Instantiate output FIFO
    ofifo #(.col(col), .bw(16)) ofifo_inst (
        .clk(clk),
        .in(array_to_ofifo),
        .out(sfp_out),
        .rd(ofifo_rd),
        .wr(ofifo_wr),
        .o_full(ofifo_full),
        .reset(reset),
        .o_ready(ofifo_ready),
        .o_valid(ofifo_valid)
    );

endmodule 
