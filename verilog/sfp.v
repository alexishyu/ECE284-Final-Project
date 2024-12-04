// sfp.v
// Special Function Processor for accumulation and ReLU
// Adjusted to match the interface in corelet.v

`timescale 1ns/1ps

module sfp #(
    parameter psum_bw = 16
)(
    input clk,
    input reset,
    input acc,
    input relu_en,
    input signed [psum_bw-1:0] data_in,
    output signed [psum_bw-1:0] data_out
);

    reg signed [psum_bw-1:0] psum_q;

    always @(posedge clk) begin
        if (reset)
            psum_q <= 0;
        else begin
            if (acc)
                psum_q <= psum_q + data_in;
            else if (relu_en)
                psum_q <= (psum_q > 0) ? psum_q : 0;
            else
                psum_q <= psum_q;
        end
    end

    assign data_out = psum_q;

endmodule




