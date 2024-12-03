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
    output wire [(psum_bw*col)-1:0] ofifo_out,
    output wire ofifo_full,
    output wire ofifo_ready,
    output wire ofifo_valid,
    // SFP interface
    input  wire sfp_en,
    input  wire sfp_acc_clear,
    input  wire sfp_relu_en
);

    // Internal signals
    wire [(row*bw)-1:0] l0_to_array;
    wire [(psum_bw*col)-1:0] array_to_sfp;
    wire [(psum_bw*col)-1:0] sfp_to_ofifo;
    wire [col-1:0] sfp_valid;
    wire [col-1:0] ofifo_wr;

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
        .out_s(array_to_sfp),   // Output to SFU
        .valid(sfp_valid)       // Valid signal for SFU
    );

    // Instantiate SFUs for each column
    generate
        genvar i;
        for (i = 0; i < col; i = i + 1) begin : sfp_gen
            sfp sfp_inst (
                .clk(clk),
                .reset(reset),
                .en(sfp_en),
                .acc_clear(sfp_acc_clear),
                .relu_en(sfp_relu_en),
                .data_in(array_to_sfp[psum_bw*(i+1)-1:psum_bw*i]),  // Column-specific psum
                .data_valid(sfp_valid[i]),                         // Column-specific valid signal
                .data_out(sfp_to_ofifo[psum_bw*(i+1)-1:psum_bw*i]), // Output to OFIFO
                .out_valid(ofifo_wr[i])                            // Write enable for OFIFO
            );
        end
    endgenerate

    // Instantiate OFIFO
    ofifo #(.col(col), .bw(psum_bw)) ofifo_inst (
        .clk(clk),
        .in(sfp_to_ofifo),      // Input from SFU
        .out(ofifo_out),        // Output to psum memory
        .rd(ofifo_rd),
        .wr(ofifo_wr),          // Write enable from SFU
        .o_full(ofifo_full),
        .reset(reset),
        .o_ready(ofifo_ready),
        .o_valid(ofifo_valid)
    );

endmodule