// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Modified to complete the testbench as per assignment instructions
`timescale 1ns/1ps

module core_tb;

parameter bw = 4;
parameter psum_bw = 16;
parameter len_kij = 9;
parameter len_onij = 16;
parameter col = 8;
parameter row = 8;
parameter len_nij = 36;

reg clk = 0;
reg reset = 1;

// Instruction bus (34 bits)
wire [33:0] inst_q; 

// Internal registers for control signals and data
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
reg [8*30:1] stringvar;
reg [8*30:1] w_file_name;
wire ofifo_valid;
wire [psum_bw*col-1:0] sfp_out; // Output from SFP

integer x_file, x_scan_file ; // File handlers for activation data
integer w_file, w_scan_file ; // File handlers for weight data
integer acc_file, acc_scan_file ; // File handlers for accumulation data
integer out_file, out_scan_file ; // File handlers for output data
integer captured_data; 
integer t, i, j, k, kij;
integer error;

// Assignments to construct the instruction bus `inst_q`
assign inst_q[33] = acc_q;           // Accumulation control
assign inst_q[32] = CEN_pmem_q;      // Psum memory chip enable
assign inst_q[31] = WEN_pmem_q;      // Psum memory write enable
assign inst_q[30:20] = A_pmem_q;     // Psum memory address
assign inst_q[19]   = CEN_xmem_q;    // X memory chip enable
assign inst_q[18]   = WEN_xmem_q;    // X memory write enable
assign inst_q[17:7] = A_xmem_q;      // X memory address
assign inst_q[6]   = ofifo_rd_q;     // OFIFO read enable
assign inst_q[5]   = ififo_wr_q;     // IFIFO write enable
assign inst_q[4]   = ififo_rd_q;     // IFIFO read enable
assign inst_q[3]   = l0_rd_q;        // L0 read enable
assign inst_q[2]   = l0_wr_q;        // L0 write enable
assign inst_q[1]   = execute_q;      // Execute signal
assign inst_q[0]   = load_q;         // Load signal

// Instantiate the core module
core  #(.bw(bw), .col(col), .row(row)) core_instance (
    .clk(clk), 
    .inst(inst_q),
    .ofifo_valid(ofifo_valid),
    .D_xmem(D_xmem_q), 
    .sfp_out(sfp_out), 
    .reset(reset)
); 

initial begin 

  // Initialize control signals and data
  inst_w   = 0; 
  D_xmem   = 0;
  CEN_xmem = 1; // Disable memory by default
  WEN_xmem = 1; // Disable writing by default
  A_xmem   = 0; // Initialize address
  ofifo_rd = 0;
  ififo_wr = 0;
  ififo_rd = 0;
  l0_rd    = 0;
  l0_wr    = 0;
  execute  = 0;
  load     = 0;

  $dumpfile("core_tb.vcd"); // VCD file for waveform viewing
  $dumpvars(0,core_tb);

  // Open the activation data file
  x_file = $fopen("activation_tile0.txt", "r");
  // Remove the first three comment lines from the file
  x_scan_file = $fscanf(x_file,"%s", captured_data);
  x_scan_file = $fscanf(x_file,"%s", captured_data);
  x_scan_file = $fscanf(x_file,"%s", captured_data);

  //////// Reset /////////
  #0.5 clk = 1'b0;   reset = 1;
  #0.5 clk = 1'b1; 

  // Wait for 10 clock cycles during reset
  for (i=0; i<10 ; i=i+1) begin
    #0.5 clk = 1'b0;
    #0.5 clk = 1'b1;  
  end

  #0.5 clk = 1'b0;   reset = 0;
  #0.5 clk = 1'b1; 

  // One additional clock cycle after reset
  #0.5 clk = 1'b0;   
  #0.5 clk = 1'b1;   
  /////////////////////////

  /////// Activation Data Writing to Memory ///////
  // Load activation data into X memory (xmem)
  for (t=0; t<len_nij; t=t+1) begin  
    #0.5 clk = 1'b0;  
    x_scan_file = $fscanf(x_file,"%32b", D_xmem); // Read 32-bit activation data
    WEN_xmem = 0; // Enable write
    CEN_xmem = 0; // Enable chip
    if (t>0) A_xmem = A_xmem + 1; // Increment address after the first write
    #0.5 clk = 1'b1;   
  end

  // Disable writing to xmem after loading activations
  #0.5 clk = 1'b0;  
  WEN_xmem = 1;  // Disable write
  CEN_xmem = 1;  // Disable chip
  A_xmem = 0;    // Reset address
  #0.5 clk = 1'b1; 

  $fclose(x_file); // Close activation data file
  /////////////////////////////////////////////////

  // Loop over kij (kernel index)
  for (kij=0; kij<9; kij=kij+1) begin  // kij loop

    // Determine weight file name based on kij
    case(kij)
     0: w_file_name = "weight_itile0_otile0_kij0.txt";
     1: w_file_name = "weight_itile0_otile0_kij1.txt";
     2: w_file_name = "weight_itile0_otile0_kij2.txt";
     3: w_file_name = "weight_itile0_otile0_kij3.txt";
     4: w_file_name = "weight_itile0_otile0_kij4.txt";
     5: w_file_name = "weight_itile0_otile0_kij5.txt";
     6: w_file_name = "weight_itile0_otile0_kij6.txt";
     7: w_file_name = "weight_itile0_otile0_kij7.txt";
     8: w_file_name = "weight_itile0_otile0_kij8.txt";
    endcase

    // Open the weight data file
    w_file = $fopen(w_file_name, "r");
    // Remove the first three comment lines from the file
    w_scan_file = $fscanf(w_file,"%s", captured_data);
    w_scan_file = $fscanf(w_file,"%s", captured_data);
    w_scan_file = $fscanf(w_file,"%s", captured_data);

    // Reset before loading weights
    #0.5 clk = 1'b0;   reset = 1;
    #0.5 clk = 1'b1; 

    // Wait for 10 clock cycles during reset
    for (i=0; i<10 ; i=i+1) begin
      #0.5 clk = 1'b0;
      #0.5 clk = 1'b1;  
    end

    #0.5 clk = 1'b0;   reset = 0;
    #0.5 clk = 1'b1; 

    // One additional clock cycle after reset
    #0.5 clk = 1'b0;   
    #0.5 clk = 1'b1;   

    /////// Kernel Data Writing to Memory ///////
    // Set the starting address for weights in xmem
    A_xmem = 11'b10000000000; // Starting address for weights

    // Load weights into xmem
    for (t=0; t<col; t=t+1) begin  
      #0.5 clk = 1'b0;  
      w_scan_file = $fscanf(w_file,"%32b", D_xmem); // Read 32-bit weight data
      WEN_xmem = 0; // Enable write
      CEN_xmem = 0; // Enable chip
      if (t>0) A_xmem = A_xmem + 1; // Increment address after the first write
      #0.5 clk = 1'b1;  
    end

    // Disable writing to xmem after loading weights
    #0.5 clk = 1'b0;  
    WEN_xmem = 1;  // Disable write
    CEN_xmem = 1;  // Disable chip
    A_xmem = 0;    // Reset address
    #0.5 clk = 1'b1; 

    /////////////////////////////////////

    /////// Kernel Data Writing to L0 ///////
    // Read weights from xmem and write to L0 via IFIFO

    // Start reading weights from xmem
    A_xmem = 11'b10000000000; // Starting address for weights
    for (t=0; t<col; t=t+1) begin  
      // Read weight data from xmem
      #0.5 clk = 1'b0;  
      WEN_xmem = 1; // Set to read mode
      CEN_xmem = 0; // Enable chip
      if (t>0) A_xmem = A_xmem + 1; // Increment address after the first read
      #0.5 clk = 1'b1;

      // Write data to IFIFO
      #0.5 clk = 1'b0;
      D_xmem = D_xmem_q; // Data read from xmem
      ififo_wr = 1; // Write to IFIFO
      WEN_xmem = 1; // Ensure xmem write is disabled
      CEN_xmem = 1; // Disable xmem
      #0.5 clk = 1'b1;

      // Disable IFIFO write
      #0.5 clk = 1'b0;
      ififo_wr = 0;
      #0.5 clk = 1'b1;
    end

    // Transfer data from IFIFO to L0
    for (t=0; t<col; t=t+1) begin
      #0.5 clk = 1'b0;
      ififo_rd = 1; // Read from IFIFO
      l0_wr = 1;    // Write to L0
      #0.5 clk = 1'b1;

      // Disable IFIFO read and L0 write
      #0.5 clk = 1'b0;
      ififo_rd = 0;
      l0_wr = 0;
      #0.5 clk = 1'b1;
    end

    /////////////////////////////////////

    /////// Kernel Loading to PEs ///////
    // Load kernels from L0 into the processing elements (PEs)
    #0.5 clk = 1'b0;  
    load = 1;   // Enable kernel loading
    l0_rd = 1;  // Read from L0
    execute = 0; // Ensure execute is disabled
    #0.5 clk = 1'b1;  

    // Wait for some cycles to ensure kernel loading completes
    for (i=0; i<10; i=i+1) begin
      #0.5 clk = 1'b0;
      #0.5 clk = 1'b1;
    end

    // Disable load and L0 read signals
    #0.5 clk = 1'b0;  
    load = 0;
    l0_rd = 0;
    #0.5 clk = 1'b1; 
    /////////////////////////////////////

    ////// Provide Intermission to Clear Up Kernel Loading ///
    #0.5 clk = 1'b0;  load = 0; l0_rd = 0;
    #0.5 clk = 1'b1;  

    for (i=0; i<10 ; i=i+1) begin
      #0.5 clk = 1'b0;
      #0.5 clk = 1'b1;  
    end
    /////////////////////////////////////

    /////// Activation Data Writing to L0 ///////
    // Read activation data from xmem and write to L0 via IFIFO

    // Reopen the activation data file
    x_file = $fopen("activation_tile0.txt", "r");
    // Remove the first three comment lines
    x_scan_file = $fscanf(x_file,"%s", captured_data);
    x_scan_file = $fscanf(x_file,"%s", captured_data);
    x_scan_file = $fscanf(x_file,"%s", captured_data);

    // Start reading from the beginning of xmem
    A_xmem = 0;

    // Read activation data from xmem and write to IFIFO
    for (t=0; t<len_nij; t=t+1) begin  
      // Read activation data from xmem
      #0.5 clk = 1'b0;  
      WEN_xmem = 1; // Set to read mode
      CEN_xmem = 0; // Enable chip
      if (t>0) A_xmem = A_xmem + 1; // Increment address after the first read
      #0.5 clk = 1'b1;

      // Write data to IFIFO
      #0.5 clk = 1'b0;
      D_xmem = D_xmem_q; // Data read from xmem
      ififo_wr = 1; // Write to IFIFO
      WEN_xmem = 1; // Ensure xmem write is disabled
      CEN_xmem = 1; // Disable xmem
      #0.5 clk = 1'b1;

      // Disable IFIFO write
      #0.5 clk = 1'b0;
      ififo_wr = 0;
      #0.5 clk = 1'b1;
    end

    $fclose(x_file); // Close activation data file

    // Transfer data from IFIFO to L0
    for (t=0; t<len_nij; t=t+1) begin
      #0.5 clk = 1'b0;
      ififo_rd = 1; // Read from IFIFO
      l0_wr = 1;    // Write to L0
      #0.5 clk = 1'b1;

      // Disable IFIFO read and L0 write
      #0.5 clk = 1'b0;
      ififo_rd = 0;
      l0_wr = 0;
      #0.5 clk = 1'b1;
    end

    /////////////////////////////////////

    /////// Execution ///////
    // Start the execution of PEs using activations from L0
    #0.5 clk = 1'b0;  
    execute = 1; // Enable execution
    l0_rd = 1;   // Read from L0
    load = 0;    // Ensure load is disabled
    #0.5 clk = 1'b1;  

    // Wait for execution to complete
    for (i=0; i<20; i=i+1) begin
      #0.5 clk = 1'b0;
      #0.5 clk = 1'b1;
    end

    // Disable execute and L0 read signals
    #0.5 clk = 1'b0;  
    execute = 0;
    l0_rd = 0;
    #0.5 clk = 1'b1; 
    /////////////////////////////////////

    //////// OFIFO Read ////////
    // Read data from OFIFO after execution
    #0.5 clk = 1'b0;
    ofifo_rd = 1; // Enable OFIFO read
    #0.5 clk = 1'b1;

    // Continue reading until OFIFO is empty
    while (ofifo_valid) begin
      #0.5 clk = 1'b0;
      #0.5 clk = 1'b1;
    end

    // Disable OFIFO read
    #0.5 clk = 1'b0;
    ofifo_rd = 0;
    #0.5 clk = 1'b1;
    /////////////////////////////////////

  end  // End of kij loop

  ////////// Accumulation and Verification /////////
  // Open the expected output file
  out_file = $fopen("out.txt", "r");  

  // Remove the first three comment lines
  out_scan_file = $fscanf(out_file,"%s", answer); 
  out_scan_file = $fscanf(out_file,"%s", answer); 
  out_scan_file = $fscanf(out_file,"%s", answer); 

  error = 0; // Initialize error counter

  $display("############ Verification Start during accumulation #############"); 

  // Loop over output features
  for (i=0; i<len_onij+1; i=i+1) begin 

    #0.5 clk = 1'b0; 
    #0.5 clk = 1'b1; 

    if (i>0) begin
     out_scan_file = $fscanf(out_file,"%128b", answer); // Read expected output
       if (sfp_out == answer)
         $display("%2d-th output featuremap Data matched! :D", i); 
       else begin
         $display("%2d-th output featuremap Data ERROR!!", i); 
         $display("sfpout: %128b", sfp_out);
         $display("answer: %128b", answer);
         error = 1;
       end
    end
   
    // Reset between outputs
    #0.5 clk = 1'b0; reset = 1;
    #0.5 clk = 1'b1;  
    #0.5 clk = 1'b0; reset = 0; 
    #0.5 clk = 1'b1;  

    // Accumulation phase (if applicable)
    for (j=0; j<len_kij+1; j=j+1) begin 

      #0.5 clk = 1'b0;   
        if (j<len_kij) begin 
            CEN_pmem = 0; WEN_pmem = 1; 
            acc_scan_file = $fscanf(acc_file,"%11b", A_pmem); 
        end
        else  begin 
            CEN_pmem = 1; WEN_pmem = 1; 
        end

        if (j>0)  acc = 1;  // Enable accumulation after the first cycle
      #0.5 clk = 1'b1;   
    end

    #0.5 clk = 1'b0; acc = 0;
    #0.5 clk = 1'b1; 
  end

  if (error == 0) begin
    $display("############ No error detected ##############"); 
    $display("########### Project Completed !! ############"); 
  end

  $fclose(acc_file); // Close accumulation file
  //////////////////////////////////

  // Wait for 10 cycles before finishing simulation
  for (t=0; t<10; t=t+1) begin  
    #0.5 clk = 1'b0;  
    #0.5 clk = 1'b1;  
  end

  #10 $finish; // End simulation

end

// Update registered control signals at each positive clock edge
always @ (posedge clk) begin
   inst_w_q   <= inst_w; 
   D_xmem_q   <= D_xmem;
   CEN_xmem_q <= CEN_xmem;
   WEN_xmem_q <= WEN_xmem;
   A_pmem_q   <= A_pmem;
   CEN_pmem_q <= CEN_pmem;
   WEN_pmem_q <= WEN_pmem;
   A_xmem_q   <= A_xmem;
   ofifo_rd_q <= ofifo_rd;
   acc_q      <= acc;
   ififo_wr_q <= ififo_wr;
   ififo_rd_q <= ififo_rd;
   l0_rd_q    <= l0_rd;
   l0_wr_q    <= l0_wr ;
   execute_q  <= execute;
   load_q     <= load;
end

endmodule
