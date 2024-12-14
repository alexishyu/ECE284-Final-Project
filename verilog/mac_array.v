module mac_array (clk, reset, out_s, in_w, in_n, inst_w, valid);

  parameter bw = 4;
  parameter psum_bw = 16;
  parameter col = 8;
  parameter row = 8;

  input  clk, reset;
  output wire [psum_bw*col-1:0] out_s;
  input  [row*bw-1:0] in_w;
  input  [1:0] inst_w;
  input  [bw*col-1:0] in_n;
  input mode;
  output wire [col-1:0] valid;

  input output_enable;
  output [psum_bw*col*row-1:0] tile_outputs;
  output [psum_bw*col-1:0] ofifo_input;
  wire [psum_bw*col-1:0] tile_outputs_row [0:row-1];
  reg [$clog2(row)-1:0] row_counter;
  reg valid_row;
  output row_valid;

  reg [2*row-1:0] inst_w_temp;
  wire [psum_bw*col*(row+1)-1:0] temp;
  wire [row*col-1:0] valid_temp;
 
  // Sequential logic for instruction propagation
  always @(posedge clk) begin
    if (reset) begin
      inst_w_temp <= 0;
    end
    else begin
      inst_w_temp[1:0]   <= inst_w;
      inst_w_temp[3:2]   <= inst_w_temp[1:0];
      inst_w_temp[5:4]   <= inst_w_temp[3:2];
      inst_w_temp[7:6]   <= inst_w_temp[5:4];
      inst_w_temp[9:8]   <= inst_w_temp[7:6];
      inst_w_temp[11:10] <= inst_w_temp[9:8];
      inst_w_temp[13:12] <= inst_w_temp[11:10];
      inst_w_temp[15:14] <= inst_w_temp[13:12];
    end
  end

  // Row counter for output-stationary mode
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      row_counter <= 0;
      valid_row <= 0;
    end else if (output_enable) begin
      if (row_counter == row - 1) begin
        row_counter <= 0;
      end else begin
        row_counter <= row_counter + 1;
      end
      valid_row <= 1;
    end else begin
      valid_row <= 0;
  end

  assign row_valid = valid_row;

  // Base case: first row gets zeros as input
  assign temp[psum_bw*col-1:0] = (mode == 1) ? {psum_bw*col{1'b0}} : in_n;

  // Generate MAC rows
  genvar i;
  generate
    for (i=0; i < row; i=i+1) begin : row_num
      mac_row #(.bw(bw), .psum_bw(psum_bw), .col(col)) mac_row_instance (
        .clk(clk),
        .reset(reset),
        .in_w(in_w[bw*(i+1)-1:bw*i]),
        .inst_w(inst_w_temp[2*i+1:2*i]),
        .in_n(temp[psum_bw*col*(i+1)-1:psum_bw*col*i]),
        .mode(mode),
        .out_s(temp[psum_bw*col*(i+2)-1:psum_bw*col*(i+1)]),
        .valid(valid_temp[col*(i+1)-1:col*i]),
        .output_enable(output_enable),
        .tile_outputs(tile_outputs_row[i])
      );
    end

    assign tile_outputs[psum_bw*col*(i+1)-1:psum_bw*col*i] = tile_outputs_row[i];
  endgenerate

  // Output assignments
  assign out_s = temp[psum_bw*col*(row+1)-1:psum_bw*col*row];
  assign valid = valid_temp[col*row-1:col*(row-1)];
  assign ofifo_input = tile_outputs_row[row_counter];

endmodule