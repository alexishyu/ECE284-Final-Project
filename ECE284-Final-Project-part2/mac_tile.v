// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
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

// Internal registers (latches)
reg [1:0] inst_q;
reg [bw-1:0] a_q;
reg [bw-1:0] b_q;
reg [psum_bw-1:0] c_q;
reg load_ready_q;

// Wire for MAC output
wire [psum_bw-1:0] mac_out;

// Connect outputs
assign out_e = a_q;
assign inst_e = inst_q;
assign out_s = mac_out;

// Instantiate MAC module
mac #(.bw(bw), .psum_bw(psum_bw)) mac_instance (
    .a(a_q),
    .b(b_q),
    .c(c_q),
    .out(mac_out)
);

// Sequential logic
always @(posedge clk) begin
    if (reset) begin
        inst_q <= 2'b00;
        load_ready_q <= 1'b1;
    end
    else begin
        // Handle instruction[1] (execution)
        inst_q[1] <= inst_w[1];
        
        // Handle activation input
        if (inst_w[0] || inst_w[1]) begin
            a_q <= in_w;
        end
        
        // Handle weight loading
        if (inst_w[0] && load_ready_q) begin
            b_q <= in_w;
            load_ready_q <= 1'b0;
        end
        
        // Handle instruction[0] propagation
        if (!load_ready_q) begin
            inst_q[0] <= inst_w[0];
        end
        
        // Handle psum input
        c_q <= in_n;
    end
end

endmodule