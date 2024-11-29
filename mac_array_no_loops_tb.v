
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

// Test sequence without loops
initial begin
    // Initialize inputs
    reset = 1;
    in_w = 0;
    inst_w = 2'b00;
    in_n = 0;

    // Apply reset
    #10;
    reset = 0;

    // Manually load weights into each row
    #10; inst_w = 2'b01; in_w = {row{4'b1010}}; in_n = {col{16'h0000}}; // Load for Row 1
    #10; inst_w = 2'b01; in_w = {row{4'b1010}}; in_n = {col{16'h0000}}; // Load for Row 2
    #10; inst_w = 2'b01; in_w = {row{4'b1010}}; in_n = {col{16'h0000}}; // Load for Row 3
    #10; inst_w = 2'b01; in_w = {row{4'b1010}}; in_n = {col{16'h0000}}; // Load for Row 4
    #10; inst_w = 2'b01; in_w = {row{4'b1010}}; in_n = {col{16'h0000}}; // Load for Row 5
    #10; inst_w = 2'b01; in_w = {row{4'b1010}}; in_n = {col{16'h0000}}; // Load for Row 6
    #10; inst_w = 2'b01; in_w = {row{4'b1010}}; in_n = {col{16'h0000}}; // Load for Row 7
    #10; inst_w = 2'b01; in_w = {row{4'b1010}}; in_n = {col{16'h0000}}; // Load for Row 8

    #10; inst_w = 2'b00; // Disable instructions

    // Manually execute MAC operations across all rows
    #10; inst_w = 2'b10; in_w = {row{4'b0101}}; in_n = {col{16'h000A}}; // Execute for Row 1
    #10; inst_w = 2'b10; in_w = {row{4'b0101}}; in_n = {col{16'h000A}}; // Execute for Row 2
    #10; inst_w = 2'b10; in_w = {row{4'b0101}}; in_n = {col{16'h000A}}; // Execute for Row 3
    #10; inst_w = 2'b10; in_w = {row{4'b0101}}; in_n = {col{16'h000A}}; // Execute for Row 4
    #10; inst_w = 2'b10; in_w = {row{4'b0101}}; in_n = {col{16'h000A}}; // Execute for Row 5
    #10; inst_w = 2'b10; in_w = {row{4'b0101}}; in_n = {col{16'h000A}}; // Execute for Row 6
    #10; inst_w = 2'b10; in_w = {row{4'b0101}}; in_n = {col{16'h000A}}; // Execute for Row 7
    #10; inst_w = 2'b10; in_w = {row{4'b0101}}; in_n = {col{16'h000A}}; // Execute for Row 8

    #10; inst_w = 2'b00; // Disable instructions

    // Observe outputs
    #20;
    $display("Output South (out_s): %h", out_s);
    $display("Valid signals: %b", valid);

    // Check the `valid` signal
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
