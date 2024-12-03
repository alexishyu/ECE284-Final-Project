module mac_tile (clk, out_s, in_w, out_e, in_n, inst_w, inst_e, reset);

  parameter bw = 4;
  parameter psum_bw = 16;

  output [psum_bw-1:0] out_s;
  input  [bw-1:0] in_w; 
  output [bw-1:0] out_e; 
  input  [1:0] inst_w;
  output [1:0] inst_e;
  input  [psum_bw-1:0] in_n;
  input  clk;
  input  reset;

  reg [bw-1:0] a_q; // Weight register
  reg [1:0] inst_q; // Instruction register

  wire [psum_bw-1:0] mac_out;

  // MAC operation
  mac #(.bw(bw), .psum_bw(psum_bw)) mac_instance (
        .a(a_q), 
        .b(in_w),
        .c(in_n), // Use incoming partial sum directly
        .out(mac_out)
  ); 

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      a_q <= 0;
      inst_q <= 0;
    end else begin
      inst_q <= inst_w; // Update instruction register
      
      if (inst_w[0]) begin
        // Weight-loading phase: load the new weight into a_q
        a_q <= in_w;
      end
      // No need for separate storage of partial sums
    end
  end

  assign out_s = mac_out; // Output updated psum
  assign out_e = in_w;    // Pass the input activation to the next tile
  assign inst_e = inst_q; // Pass the instruction signal to the next tile

endmodule