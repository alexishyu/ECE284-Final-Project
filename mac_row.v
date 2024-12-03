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

  wire  [(col+1)*bw-1:0] temp; // Internal connections for weights
  wire  [2*col-1:0] inst_temp; // Internal connections for control signals
  wire  [psum_bw*col-1:0] out_temp; // Intermediate psum connections
  wire  [col-1:0] valid_temp; // Valid signal for each tile

  assign temp[bw-1:0] = in_w; // Pass initial weight to the first tile
  assign out_s = out_temp; // Connect intermediate outputs to the final output
  assign valid = valid_temp; // Pass validity signals to the output

  genvar i;
  for (i = 1; i < col + 1; i = i + 1) begin : col_num
      mac_tile #(.bw(bw), .psum_bw(psum_bw)) mac_tile_instance (
         .clk(clk),
         .reset(reset),
         .in_w(temp[bw*i-1:bw*(i-1)]),
         .out_e(temp[bw*(i+1)-1:bw*i]),
         .inst_w(inst_w),
         .inst_e(inst_temp[2*i-1:2*(i-1)]),
         .in_n(in_n[psum_bw*i-1:psum_bw*(i-1)]),
         .out_s(out_temp[psum_bw*i-1:psum_bw*(i-1)])
      );
  end

endmodule