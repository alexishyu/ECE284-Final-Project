// sfp.v
// Special Function Processor for accumulation and ReLU
// Adjusted to match the interface in corelet.v

`timescale 1ns/1ps

module sfp #(
    parameter psum_bw = 16,
    parameter col = 8
)(
    input clk,
    input reset,
    input en,                  // SFP enable signal
    input acc_clear,           // Clear accumulator signal
    input relu_en,             // ReLU enable signal
    input [psum_bw-1:0] data_in,   // Partial sum input (16 bits)
    input data_valid,          // Data valid signal
    output reg [psum_bw-1:0] data_out, // Output data after accumulation and ReLU
    output reg out_valid       // Output valid signal
);

    // Internal accumulator register
    reg signed [psum_bw-1:0] accumulator;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            accumulator <= 0;
            data_out <= 0;
            out_valid <= 0;
        end else if (en) begin
            if (acc_clear) begin
                accumulator <= 0;
            end else if (data_valid) begin
                accumulator <= accumulator + data_in;
            end

            // Apply ReLU if enabled
            if (relu_en) begin
                if (accumulator < 0)
                    data_out <= 0;
                else
                    data_out <= accumulator;
            end else begin
                data_out <= accumulator;
            end

            out_valid <= data_valid;
        end else begin
            // Hold outputs if not enabled
            data_out <= data_out;
            out_valid <= 0;
        end
    end

endmodule




