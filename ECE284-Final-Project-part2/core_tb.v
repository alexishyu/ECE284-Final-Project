// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
`timescale 1ns/1ps

module core_tb;

parameter bw = 4;           // Bit width for weights and activations
parameter psum_bw = 16;     // Partial sum bit width
parameter len_kij = 9;      // 3x3 kernel = 9 elements
parameter len_onij = 16;    // Output feature map size
parameter col = 8;          // Input channels
parameter row = 8;          // Output channels
parameter len_nij = 36;     // Input feature map size

reg clk = 0;
reg reset = 1;

wire [33:0] inst_q;

// Register declarations
reg [1:0]  inst_w_q = 0;
reg [bw*row-1:0] D_xmem_q = 0;
reg CEN_xmem = 1;
reg WEN_xmem = 1;
reg [10:0] A_xmem = 0;
reg CEN_xmem_q = 1;
reg WEN_xmem_q = 1;
reg [10:0] A_xmem_q = 0;
reg CEN_pmem = 1;
reg WEN_pmem = 1;
reg [10:0] A_pmem = 0;
reg CEN_pmem_q = 1;
reg WEN_pmem_q = 1;
reg [10:0] A_pmem_q = 0;
reg ofifo_rd_q = 0;
reg ififo_wr_q = 0;
reg ififo_rd_q = 0;
reg l0_rd_q = 0;
reg l0_wr_q = 0;
reg execute_q = 0;
reg load_q = 0;
reg acc_q = 0;
reg acc = 0;

// Activation memory signals
reg [31:0] D_act;
reg [31:0] D_act_q;
reg CEN_act, WEN_act;
reg CEN_act_q, WEN_act_q;
reg [10:0] A_act = 0;
reg [10:0] A_act_q = 0;

reg [1:0]  inst_w;
reg [bw*row-1:0] D_xmem;
reg [psum_bw*col-1:0] answer;

reg ofifo_rd;
reg ififo_wr;
reg ififo_rd;
reg l0_rd;
reg l0_wr;
reg execute;
reg load;

wire ofifo_valid;
wire [31:0] sfp_out;
wire [31:0] weight_sram_out;
wire [31:0] act_sram_out;
wire [31:0] psum_sram_out;

// File handling
integer x_file, x_scan_file;
integer w_file, w_scan_file;
integer acc_file, acc_scan_file;
integer out_file, out_scan_file;
integer captured_data;
integer t, i, j, kij;
integer error;

reg [8*50:1] w_file_name;

// Instruction assignments
assign inst_q[33] = acc_q;
assign inst_q[32] = CEN_pmem_q;
assign inst_q[31] = WEN_pmem_q;
assign inst_q[30:20] = A_pmem_q;
assign inst_q[19] = CEN_xmem_q;
assign inst_q[18] = WEN_xmem_q;
assign inst_q[17:7] = A_xmem_q;
assign inst_q[6] = ofifo_rd_q;
assign inst_q[5] = ififo_wr_q;
assign inst_q[4] = ififo_rd_q;
assign inst_q[3] = l0_rd_q;
assign inst_q[2] = l0_wr_q;
assign inst_q[1] = execute_q;
assign inst_q[0] = load_q;

core #(
    .BW(bw),
    .COL(col),
    .ROW(row),
    .PSUM_BW(psum_bw)
) core_instance (
    .clk(clk),
    .reset(reset),
    .mac_array_en(execute_q),
    .l0_rd(l0_rd_q),
    .l0_wr(l0_wr_q),
    .ofifo_rd(ofifo_rd_q),
    .act_sram_wen(WEN_act_q),
    .act_sram_cen(CEN_act_q),
    .weight_sram_wen(WEN_xmem_q),
    .weight_sram_cen(CEN_xmem_q),
    .psum_sram_wen(WEN_pmem_q),
    .psum_sram_cen(CEN_pmem_q),
    .act_data_in(D_act_q),
    .weight_data_in(D_xmem_q),
    .act_addr(A_act_q),
    .weight_addr(A_xmem_q),
    .psum_addr(A_pmem_q),
    .data_in(32'b0),
    .data_out(sfp_out),
    .l0_full(),
    .l0_ready(),
    .ofifo_full(),
    .ofifo_ready(),
    .ofifo_valid(ofifo_valid),
    .sfp_en(1'b1),
    .sfp_acc_clear(1'b0),
    .sfp_relu_en(1'b1)
);

initial begin
    // Initialize all signals
    inst_w = 0;
    D_xmem = 0;
    CEN_xmem = 1;
    WEN_xmem = 0;
    A_xmem = 0;
    ofifo_rd = 0;
    ififo_wr = 0;
    ififo_rd = 0;
    l0_rd = 0;
    l0_wr = 0;
    execute = 0;
    load = 0;
    acc = 0;
    D_act = 0;
    CEN_act = 0;
    WEN_act = 1;

    $dumpfile("core_tb.vcd");
    $dumpvars(0,core_tb);

    // Load activation data
    x_file = $fopen("activation.txt", "r");
    x_scan_file = $fscanf(x_file,"%s", captured_data);
    x_scan_file = $fscanf(x_file,"%s", captured_data);
    x_scan_file = $fscanf(x_file,"%s", captured_data);

    // Initial reset
    #0.5 clk = 1'b0; reset = 1;
    #0.5 clk = 1'b1;

    for (i=0; i<10; i=i+1) begin
        #0.5 clk = 1'b0;
        #0.5 clk = 1'b1;
    end

    #0.5 clk = 1'b0; reset = 0;
    #0.5 clk = 1'b1;

    // Load activation data to activation SRAM
    for (t=0; t<len_nij; t=t+1) begin
        #0.5 clk = 1'b0;
        x_scan_file = $fscanf(x_file,"%32b", D_act);
        WEN_act = 0;
        CEN_act = 0;
        A_act = t;
        #0.5 clk = 1'b1;
    end

    #0.5 clk = 1'b0; 
    WEN_act = 1; 
    CEN_act = 1;
    #0.5 clk = 1'b1;

    $fclose(x_file);

    // Process each kernel position (3x3)
    for (kij=0; kij<len_kij; kij=kij+1) begin
        $sformat(w_file_name, "weight_itile0_otile0_kij%0d.txt", kij);
        w_file = $fopen(w_file_name, "r");
        
        w_scan_file = $fscanf(w_file,"%s", captured_data);
        w_scan_file = $fscanf(w_file,"%s", captured_data);
        w_scan_file = $fscanf(w_file,"%s", captured_data);

        // Load weights to weight SRAM
        for (t=0; t<col; t=t+1) begin
            #0.5 clk = 1'b0;
            w_scan_file = $fscanf(w_file,"%32b", D_xmem);
            WEN_xmem = 0;
            CEN_xmem = 0;
            A_xmem = t;
            #0.5 clk = 1'b1;
        end

        #0.5 clk = 1'b0; 
        WEN_xmem = 1; 
        CEN_xmem = 1;
        #0.5 clk = 1'b1;

        // Load weights to L0
        #0.5 clk = 1'b0; l0_wr = 1;
        #0.5 clk = 1'b1;

        for (i=0; i<col+1; i=i+1) begin
            #0.5 clk = 1'b0;
            if (i==col) l0_wr = 0;
            #0.5 clk = 1'b1;
        end

        // Load weights from L0 to PEs
        #0.5 clk = 1'b0;
        load = 1; 
        l0_rd = 1;
        #0.5 clk = 1'b1;

        for (i=0; i<row+1; i=i+1) begin
            #0.5 clk = 1'b0;
            if (i==row) begin 
                load = 0; 
                l0_rd = 0; 
            end
            #0.5 clk = 1'b1;
        end

        // Execute MAC operations
        #0.5 clk = 1'b0; execute = 1; ififo_rd = 1;
        #0.5 clk = 1'b1;

        for (i=0; i<len_nij+1; i=i+1) begin
            #0.5 clk = 1'b0;
            if (i==len_nij) begin execute = 0; ififo_rd = 0; end
            #0.5 clk = 1'b1;
        end

        // Read results
        for (i=0; i<len_onij; i=i+1) begin
            #0.5 clk = 1'b0;
            if (ofifo_valid) begin
                ofifo_rd = 1;
            end
            #0.5 clk = 1'b1;
        end

        #0.5 clk = 1'b0; ofifo_rd = 0;
        #0.5 clk = 1'b1;

        $fclose(w_file);
    end

    // Verify results
    out_file = $fopen("psum.txt", "r");
    out_scan_file = $fscanf(out_file,"%s", captured_data);
    out_scan_file = $fscanf(out_file,"%s", captured_data);
    out_scan_file = $fscanf(out_file,"%s", captured_data);

    error = 0;
    $display("############ Verification Start #############");

    for (i=0; i<len_onij; i=i+1) begin
        out_scan_file = $fscanf(out_file,"%32b", answer);
        if (sfp_out == answer[31:0])
            $display("%2d-th output matched!", i);
        else begin
            $display("%2d-th output ERROR!", i);
            $display("Expected: %32b", answer[31:0]);
            $display("Got: %32b", sfp_out);
            error = error + 1;
        end
    end

    if (error == 0)
        $display("All outputs matched successfully!");
    else
        $display("Found %d errors", error);

    $fclose(out_file);
    #100 $finish;
end

always @ (posedge clk) begin
    inst_w_q <= inst_w;
    D_xmem_q <= D_xmem;
    CEN_xmem_q <= CEN_xmem;
    WEN_xmem_q <= WEN_xmem;
    A_xmem_q <= A_xmem;
    CEN_pmem_q <= CEN_pmem;
    WEN_pmem_q <= WEN_pmem;
    A_pmem_q <= A_pmem;
    ofifo_rd_q <= ofifo_rd;
    ififo_wr_q <= ififo_wr;
    ififo_rd_q <= ififo_rd;
    l0_rd_q <= l0_rd;
    l0_wr_q <= l0_wr;
    execute_q <= execute;
    load_q <= load;
    acc_q <= acc;
    D_act_q <= D_act;
    CEN_act_q <= CEN_act;
    WEN_act_q <= WEN_act;
    A_act_q <= A_act;
end

endmodule