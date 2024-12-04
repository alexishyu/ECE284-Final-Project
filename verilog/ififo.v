// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module ififo (clk, in, out, rd, wr, i_full, reset, i_ready, i_valid);

  parameter col  = 8;
  parameter bw = 4;

  input  clk;
  input  [col-1:0] wr;
  input  rd;
  input  reset;
  input  [col*bw-1:0] in;
  output [col*bw-1:0] out;
  output i_full;
  output i_ready;
  output i_valid;

  wire [col-1:0] empty;
  wire [col-1:0] full;
  reg  rd_en;
  
  genvar i;

  assign i_ready = ~(|full);
  assign i_full  = |full;
  assign i_valid = ~(|empty);

  for (i=0; i<col ; i=i+1) begin : col_num
      fifo_depth64 #(.bw(bw)) fifo_instance (
        .rd_clk(clk),
	      .wr_clk(clk),
	      .rd(rd_en),
	      .wr(wr[i]),
        .o_empty(empty[i]),
        .o_full(full[i]),
	      .in(in[bw*(i+1)-1:bw*i]),
	      .out(out[bw*(i+1)-1:bw*i]),
        .reset(reset));
  end


  always @ (posedge clk) begin
   if (reset) begin
      rd_en <= 0;
   end
   else begin
       rd_en <= rd;
   end
  end


 

endmodule
