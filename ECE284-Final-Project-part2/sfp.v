// Special Function Processor for accumulation and ReLU
module sfp (
    input  wire                 clk,
    input  wire                 reset,
    input  wire                 en,          // Enable processing
    input  wire                 acc_clear,   // Clear accumulator
    input  wire                 relu_en,     // Enable ReLU function
    input  wire signed [31:0]   data_in,    // Input data
    input  wire                 data_valid,  // Input data valid
    output reg  signed [31:0]   data_out,   // Output data
    output reg                  out_valid    // Output valid signal
);

    // Internal registers for accumulation
    reg signed [31:0] acc_reg;
    
    // ReLU function
    function [31:0] relu;
        input [31:0] value;
        begin
            relu = (value[31]) ? 32'd0 : value; // If MSB (sign bit) is 1, output 0
        end
    endfunction

    // Main processing logic
    always @(posedge clk) begin
        if (reset) begin
            acc_reg   <= 32'd0;
            data_out  <= 32'd0;
            out_valid <= 1'b0;
        end
        else if (en) begin
            // Handle accumulation clear
            if (acc_clear) begin
                acc_reg <= 32'd0;
            end
            // Process new data
            else if (data_valid) begin
                acc_reg <= acc_reg + data_in;
                data_out <= acc_reg + data_in;
                out_valid <= 1'b1;
            end
            else begin
                out_valid <= 1'b0;
            end
        end
        else begin
            out_valid <= 1'b0;
        end
    end

endmodule 