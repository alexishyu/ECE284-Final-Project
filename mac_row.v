// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module mac_row (clk, out_s, in_w, in_n, valid, inst_w, reset);

  parameter bw = 4;
  parameter psum_bw = 16;
  parameter col = 8;

  input  clk, reset;
  output [psum_bw*col-1:0] out_s;
  output [col-1:0] valid;
  input  [bw-1:0] in_w;
  input  [1:0] inst_w;
  input  [psum_bw*col-1:0] in_n;

  wire  [bw*(col+1)-1:0] temp;
  wire  [2*(col+1)-1:0] inst_temp;
  wire  [psum_bw*col-1:0] psum_out_s;

  assign temp[bw-1:0]       = in_w;
  assign inst_temp[1:0]     = inst_w;

  genvar i;
  generate
    for (i = 0; i < col; i = i + 1) begin : col_num
      mac_tile #(.bw(bw), .psum_bw(psum_bw)) mac_tile_instance (
         .clk(clk),
         .reset(reset),
         .in_w( temp[bw*i +: bw]),
         .out_e(temp[bw*(i+1) +: bw]),
         .inst_w(inst_temp[2*i +: 2]),
         .inst_e(inst_temp[2*(i+1) +: 2]),
         .in_n(in_n[psum_bw*i +: psum_bw]),
         .out_s(out_s[psum_bw*i +: psum_bw])
      );
      assign valid[i] = inst_temp[2*(i+1) + 1];
    end
  endgenerate

endmodule


