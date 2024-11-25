module core #(
    parameter ROW = 8,
    parameter COL = 8,
    parameter BW = 4
)(
    input  wire clk,
    input  wire reset,
    // Control signals
    input  wire mac_array_en,
    input  wire l0_rd,
    input  wire l0_wr,
    input  wire ofifo_rd,
    // Memory interface
    input  wire act_sram_wen,
    input  wire act_sram_cen,
    input  wire weight_sram_wen,
    input  wire weight_sram_cen,
    input  wire psum_sram_wen,
    input  wire psum_sram_cen,
    input  wire [31:0] act_data_in,
    input  wire [31:0] weight_data_in,
    input  wire [10:0] act_addr,
    input  wire [10:0] weight_addr,
    input  wire [10:0] psum_addr,
    // Data interface
    input  wire [31:0] data_in,
    output wire [31:0] data_out,
    // Status signals
    output wire l0_full,
    output wire l0_ready,
    output wire ofifo_full,
    output wire ofifo_ready,
    output wire ofifo_valid,
    // SFP control
    input  wire sfp_en,
    input  wire sfp_acc_clear,
    input  wire sfp_relu_en
);

    // Internal signals
    wire [(ROW*BW)-1:0] l0_to_array;
    wire [(COL*BW)-1:0] array_to_ofifo;
    wire [31:0] act_sram_out;
    wire [31:0] weight_sram_out;
    wire [31:0] psum_sram_out;

    // Instantiate activation SRAM
    sram_32b_w2048 act_sram (
        .CLK(clk),
        .D(act_data_in),
        .Q(act_sram_out),
        .CEN(act_sram_cen),
        .WEN(act_sram_wen),
        .A(act_addr)
    );

    // Instantiate weight SRAM
    sram_32b_w2048 weight_sram (
        .CLK(clk),
        .D(weight_data_in),
        .Q(weight_sram_out),
        .CEN(weight_sram_cen),
        .WEN(weight_sram_wen),
        .A(weight_addr)
    );

    // Instantiate psum SRAM
    sram_32b_w2048 psum_sram (
        .CLK(clk),
        .D(data_in),
        .Q(psum_sram_out),
        .CEN(psum_sram_cen),
        .WEN(psum_sram_wen),
        .A(psum_addr)
    );

    // Instantiate corelet
    corelet #(
        .row(ROW),
        .col(COL),
        .bw(BW),
        .psum_bw(16)
    ) corelet_inst (
        .clk(clk),
        .reset(reset),
        .mac_array_en(mac_array_en),
        .l0_in(weight_sram_out[(ROW*BW)-1:0]),
        .l0_rd(l0_rd),
        .l0_wr(l0_wr),
        .l0_full(l0_full),
        .l0_ready(l0_ready),
        .act_in(act_sram_out[(COL*BW)-1:0]),
        .ofifo_rd(ofifo_rd),
        .ofifo_out(array_to_ofifo),
        .ofifo_full(ofifo_full),
        .ofifo_ready(ofifo_ready),
        .ofifo_valid(ofifo_valid),
        .sfp_en(sfp_en),
        .sfp_acc_clear(sfp_acc_clear),
        .sfp_relu_en(sfp_relu_en)
    );

    // Connect output
    assign data_out = {{(32-COL*BW){1'b0}}, array_to_ofifo};

endmodule 