module tb_pe;
    reg         clk;
    reg         reset;
    reg  [15:0] in_data;
    reg  [15:0] weight_in;
    reg         mode;
    wire [31:0] out_data;

    pe uut (
        .clk(clk),
        .reset(reset),
        .in_data(in_data),
        .weight_in(weight_in),
        .mode(mode),
        .out_data(out_data)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 100MHz clock

    initial begin
        // Initialize signals
        reset = 1;
        in_data = 0;
        weight_in = 0;
        mode = 0;
        #10;
        reset = 0;

        // Weight-stationary mode
        mode = 0;
        weight_in = 16'h0002; // Load weight
        #10;
        in_data = 16'h0003;   // Input activation
        #10;
        in_data = 16'h0004;
        #10;

        // Output-stationary mode
        mode = 1;
        weight_in = 16'h0005; // Load new weight
        #10;
        in_data = 16'h0006;   // Input activation
        #10;
        in_data = 16'h0007;
        #10;

        $finish;
    end
endmodule
