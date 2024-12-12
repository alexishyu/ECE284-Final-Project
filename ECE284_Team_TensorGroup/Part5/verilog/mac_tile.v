module mac_tile (clk, out_s, in_w, out_e, in_n, inst_w, inst_e, reset, mode);

parameter bw = 4;
parameter psum_bw = 16;

output [psum_bw-1:0] out_s;
input  [bw-1:0] in_w;      // inst[1]:execute, inst[0]: kernel loading
output [bw-1:0] out_e;     // latched version of in_w
input  [1:0] inst_w;
output [1:0] inst_e;       // latched version of inst_w
input  [psum_bw-1:0] in_n; // in_n is input psum
input  clk;
input  reset;
input mode; //0: WS, 1: OS

output [psum_bw-1:0] tile_out;//OS tile psum output 

reg [1:0] inst_q;          // connected to inst_e; latched from inst_w
reg [bw-1:0] a_q;         // connected to out_e; latched from in_w
reg signed [bw-1:0] b_q;   // weight register
reg signed [psum_bw-1:0] c_q;
reg load_ready_q;
wire signed [psum_bw-1:0] mac_out;

// Output assignments
assign out_e = a_q;
assign out_s = mode ? {{(psum_bw-bw){1'b0}}, b_q} : mac_out;
assign inst_e = inst_q;
assign tile_out = mode ? c_q : {psum_bw{1'b0}};

// Combined sequential logic
always @(posedge clk) begin
    if(reset) begin
        inst_q <= 'h0;
        load_ready_q <= 'b1;
        a_q <= 'b0;
        b_q <= 'b0;
        c_q <= 'b0;
    end
    else begin
        case(mode)
            0: begin
                inst_q[1] <= inst_w[1];
                c_q <= in_n;

                if(load_ready_q=='b0)
                    inst_q[0] <= inst_w[0];
                
                if(load_ready_q=='b1 && inst_w[0]=='b1)
                    load_ready_q <= 'b0;
                
                if(inst_w[0]=='b1 || inst_w[1]=='b1)
                    a_q <= in_w;
                    
                // Weight register
                if(inst_w[0]=='b1 && load_ready_q=='b1)
                    b_q <= in_w;
            end

            1: begin
                inst_q[1] <= inst_w[1];
                
                // Pass activation east
                if(inst_w[1]=='b1)
                    a_q <= in_w;
                
                // Pass weight south and accumulate psum
                if(inst_w[1]=='b1) begin
                    b_q <= in_n[bw-1:0];  // Weight is in lower bits
                    c_q <= mac_out;       // Accumulate result
                end
            end
        endcase
    end
end

// MAC unit instantiation
mac #(.bw(bw), .psum_bw(psum_bw)) mac_instance (
    .a(a_q),
    .b(b_q),
    .c(c_q),
    .out(mac_out)
);

endmodule



