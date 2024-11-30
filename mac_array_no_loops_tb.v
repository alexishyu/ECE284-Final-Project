`timescale 1ns / 1ps

module mac_array_tb;

parameter bw = 4;
parameter psum_bw = 16;
parameter col = 8;
parameter row = 8;

// Testbench signals
reg clk;
reg reset;
reg [row*bw-1:0] in_w;
reg [1:0] inst_w;
reg [psum_bw*col-1:0] in_n;

wire [psum_bw*col-1:0] out_s;
wire [col-1:0] valid;

// Instantiate the DUT (Device Under Test)
mac_array #(.bw(bw), .psum_bw(psum_bw), .col(col), .row(row)) dut (
    .clk(clk),
    .reset(reset),
    .in_w(in_w),
    .inst_w(inst_w),
    .in_n(in_n),
    .out_s(out_s),
    .valid(valid)
);

// Clock generation
initial begin
    clk = 0;
    forever #5 clk = ~clk; // 10ns clock period
end

// Test sequence
initial begin
    // Initialize inputs
    reset = 1;
    in_w = 0;
    inst_w = 2'b00;
    in_n = 0;

    // Apply reset
    #10;
    reset = 0;

    // Load weights into the array row by row
    inst_w = 2'b01; // Kernel loading mode
    in_n = {col{16'h0000}}; // Clear partial sums
    #10; in_w = {row{4'b0001}}; #80; // Load weights for Row 1
    #10; in_w = {row{4'b0010}}; #80; // Load weights for Row 2
    #10; in_w = {row{4'b0100}}; #80; // Load weights for Row 3
    #10; in_w = {row{4'b1000}}; #80; // Load weights for Row 4
    #10; in_w = {row{4'b1111}}; #80; // Load weights for Row 5
    #10; in_w = {row{4'b1010}}; #80; // Load weights for Row 6
    #10; in_w = {row{4'b1100}}; #80; // Load weights for Row 7
    #10; in_w = {row{4'b0011}}; #80; // Load weights for Row 8

    // Switch to idle mode
    inst_w = 2'b00;
    #20;

    // Perform MAC operations across all rows
    inst_w = 2'b10; // Execute mode
    in_n = {col{16'h0010}}; // Initial partial sums
    #10; in_w = {row{4'b0001}}; #80; // Execute for Row 1
    #10; in_w = {row{4'b0010}}; #80; // Execute for Row 2
    #10; in_w = {row{4'b0100}}; #80; // Execute for Row 3
    #10; in_w = {row{4'b1000}}; #80; // Execute for Row 4
    #10; in_w = {row{4'b1111}}; #80; // Execute for Row 5
    #10; in_w = {row{4'b1010}}; #80; // Execute for Row 6
    #10; in_w = {row{4'b1100}}; #80; // Execute for Row 7
    #10; in_w = {row{4'b0011}}; #80; // Execute for Row 8

    // Switch to idle mode
    inst_w = 2'b00;
    #20;

    // Observe outputs
    $display("Output South (out_s): %h", out_s);
    $display("Valid signals: %b", valid);

    // Check if `valid` signal is set correctly
    if (valid !== {col{1'b1}}) begin
        $display("TEST FAILED: Valid signal is incorrect.");
    end else begin
        $display("TEST PASSED: Valid signal is correct.");
    end

    // End simulation
    #10;
    $stop;
end

endmodule
