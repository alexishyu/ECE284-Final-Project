module pe_reconfigurable     (
    input  wire        clk,
    input  wire        reset,
    input  wire [15:0] in_data,    // Input activation
    input  wire [15:0] weight_in,  // Weight input from IFIFO
    input  wire        mode,       // Mode select: 0 for weight-stationary, 1 for output-stationary
    output reg  [31:0] out_data    // Output activation
);

    reg [15:0] input_reg;
    reg [15:0] weight_reg;
    reg [31:0] psum_reg;

    // Multiplexers to select dataflow based on mode
    wire [15:0] selected_input;
    wire [15:0] selected_weight;
    wire [31:0] next_psum;

    assign selected_input  = (mode == 1'b0) ? in_data    : input_reg;
    assign selected_weight = (mode == 1'b0) ? weight_reg : weight_in;

    // Compute partial sum
    assign next_psum = psum_reg + selected_input * selected_weight;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            input_reg  <= 16'd0;
            weight_reg <= 16'd0;
            psum_reg   <= 32'd0;
            out_data   <= 32'd0;
        end else begin
            // Update registers based on mode
            if (mode == 1'b0) begin
                // Weight-stationary mode
                input_reg  <= in_data;
                psum_reg   <= next_psum;
                out_data   <= psum_reg;
            end else begin
                // Output-stationary mode
                weight_reg <= weight_in;
                psum_reg   <= next_psum;
                out_data   <= psum_reg;
            end
        end
    end
endmodule
==