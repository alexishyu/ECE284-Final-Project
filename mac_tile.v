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

// Registers
reg [1:0] inst_q;
reg [bw-1:0] a_q;
reg [bw-1:0] b_q;
reg [psum_bw-1:0] c_q;
reg load_ready_q;
reg execute_valid_q;

// MAC output wire
wire [psum_bw-1:0] mac_out;

// Output assignments 
assign out_e = a_q;
assign inst_e = inst_q;
assign out_s = execute_valid_q ? mac_out : in_n;

always @(posedge clk) begin
    if (reset) begin
        inst_q <= 2'b0;
        a_q <= 'h0;
        b_q <= 'h0;
        c_q <= 'h0;
        load_ready_q <= 1'b1;
        execute_valid_q <= 1'b0;
    end
    else begin
        // Instruction handling
        inst_q <= inst_w;
        
        // Weight loading (inst_w[0] = load)
        if (inst_w[0] && load_ready_q) begin
            b_q <= in_w;
            load_ready_q <= 1'b0;
        end
        else if (!inst_w[0]) begin
            load_ready_q <= 1'b1;
        end
        
        // Activation loading (inst_w[1] = execute)
        if (inst_w[1]) begin
            a_q <= in_w;
            if (!execute_valid_q)
                c_q <= in_n;
            else 
                c_q <= mac_out;
            execute_valid_q <= 1'b1;
         end
        else begin
            execute_valid_q <= 1'b0;
        end
    end
end

// Instantiate MAC unit
mac #(.bw(bw), .psum_bw(psum_bw)) mac_instance (
    .a(a_q),
    .b(b_q),
    .c(c_q),
    .out(mac_out)
);

endmodule



