`timescale 1ns/1ps

module ofifo_tb;

  parameter col = 8;
  parameter bw = 4;

  reg clk = 0;
  reg reset = 1;
  reg [col-1:0] wr = 0;
  reg rd = 0;
  reg [col*bw-1:0] in = 0;

  wire [col*bw-1:0] out;
  wire o_full;
  wire o_ready;
  wire o_valid;

  integer i, j;
  reg [col*bw-1:0] expected_data [0:63]; // Store expected data for verification
  integer write_count = 0;
  integer read_count = 0;

  // Instantiate the DUT (Device Under Test)
  ofifo #(.col(col), .bw(bw)) dut (
    .clk(clk),
    .in(in),
    .out(out),
    .rd(rd),
    .wr(wr),
    .o_full(o_full),
    .reset(reset),
    .o_ready(o_ready),
    .o_valid(o_valid)
  );

  // Clock generation
  always #5 clk = ~clk;

  initial begin
    $dumpfile("ofifo_tb.vcd");
    $dumpvars(0, ofifo_tb);

    // Initialize signals
    wr = 0;
    rd = 0;
    in = 0;

    // Reset the FIFO
    $display("\n=== Resetting FIFO ===");
    #10 reset = 0;
    #10 reset = 1;
    #10 reset = 0;

    // Write data to FIFO
    $display("\n=== Starting Write Operations ===");
    for (i = 0; i < 64; i = i + 1) begin
      if (!o_full) begin
        wr = {col{1'b1}}; // Enable write for all columns
        in = $random;     // Generate random input data
        expected_data[write_count] = in; // Store the expected data
        write_count = write_count + 1;
        $display("Write %0d: Data=%h, Full=%b, Ready=%b", i, in, o_full, o_ready);
      end else begin
        $display("FIFO Full! Cannot write.");
      end
      #10 wr = 0; // Disable write
      #10;
    end

    // Add some stabilization cycles
    #50;

    // Read data from FIFO
    $display("\n=== Starting Read Operations ===");
    for (j = 0; j < 64; j = j + 1) begin
      if (o_valid) begin
        rd = 1;
        #10;
        $display("Read %0d: Data=%h, Expected=%h, Valid=%b", 
                 read_count, out, expected_data[read_count], o_valid);
        if (out != expected_data[read_count]) begin
          $display("  ERROR: Mismatch at read %0d!", read_count);
        end else begin
          $display("  SUCCESS: Data matched at read %0d.", read_count);
        end
        read_count = read_count + 1;
      end else begin
        $display("FIFO Empty! Cannot read.");
      end
      rd = 0;
      #10;
    end

    // Final verification
    if (write_count == read_count) begin
      $display("\n=== Test Completed Successfully ===");
    end else begin
      $display("\n=== Test Failed: Write/Read Mismatch ===");
    end

    #50 $finish;
  end

endmodule
