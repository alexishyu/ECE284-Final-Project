// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission
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

wire [33:0] inst_q;

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
wire [col*psum_bw-1:0] sfp_out;

integer x_file, x_scan_file ; // file_handler
integer w_file, w_scan_file ; // file_handler
integer acc_file, acc_scan_file ; // file_handler
integer out_file, out_scan_file ; // file_handler
integer captured_data;
integer t, i, j, k, kij;
integer error;

reg [31:0] kernel_data [0:7];  // Array for 8 columns (col-1:0)
integer error_kernel;

reg [31:0] activation_data [0:len_nij-1];  // Array to store expected data
integer error_activation = 0;

assign inst_q[33] = acc_q;
assign inst_q[32] = CEN_pmem_q;
assign inst_q[31] = WEN_pmem_q;
assign inst_q[30:20] = A_pmem_q;
assign inst_q[19]   = CEN_xmem_q;
assign inst_q[18]   = WEN_xmem_q;
assign inst_q[17:7] = A_xmem_q;
assign inst_q[6]   = ofifo_rd_q;
assign inst_q[5]   = ififo_wr_q;
assign inst_q[4]   = ififo_rd_q;
assign inst_q[3]   = l0_rd_q;
assign inst_q[2]   = l0_wr_q;
assign inst_q[1]   = execute_q;
assign inst_q[0]   = load_q;


core  #(.bw(bw), .col(col), .row(row)) core_instance (
    .clk(clk),
    .inst(inst_q),
    .ofifo_valid(ofifo_valid),
    	.D_xmem(D_xmem_q),
    	.sfp_out(sfp_out),
    .reset(reset));


initial begin

  inst_w   = 0;
  D_xmem   = 0;
  CEN_xmem = 1;
  WEN_xmem = 1;
  A_xmem   = 0;
  ofifo_rd = 0;
  ififo_wr = 0;
  ififo_rd = 0;
  l0_rd	= 0;
  l0_wr	= 0;
  execute  = 0;
  load 	= 0;

  $dumpfile("core_tb.vcd");
  $dumpvars(0,core_tb);

  x_file = $fopen("activation.txt", "r");
  // Following three lines are to remove the first three comment lines of the file
  x_scan_file = $fscanf(x_file,"%s", captured_data);
  x_scan_file = $fscanf(x_file,"%s", captured_data);
  x_scan_file = $fscanf(x_file,"%s", captured_data);

  //////// Reset /////////
  #0.5 clk = 1'b0;   reset = 1;
  $display("\n=== Starting Reset ===");
  #0.5 clk = 1'b1;

  for (i=0; i<10 ; i=i+1) begin
        #0.5 clk = 1'b0;
        #0.5 clk = 1'b1;  
  end

  #0.5 clk = 1'b0;   reset = 0;
  $display("=== Reset Complete ===\n");
  #0.5 clk = 1'b1;

  // Add some stabilization cycles after reset
  for (i=0; i<5; i=i+1) begin
        #0.5 clk = 1'b0;
        #0.5 clk = 1'b1;
  end

  /////// Activation data writing to memory ///////
  $display("\n=== Starting Activation Data Writing ===");
 
  // First write the data
  for (t=0; t<len_nij; t=t+1) begin  
	// Setup phase - Write
	#0.5 clk = 1'b0;  
	x_scan_file = $fscanf(x_file,"%32b", D_xmem);
	activation_data[t] = D_xmem;  // Store expected data
	WEN_xmem = 0;  // Enable write
	CEN_xmem = 0;  // Enable memory
	if (t>0) A_xmem = A_xmem + 1;
	$display("Writing to address %h: Data=%h", A_xmem, D_xmem);
    
	// Clock edge for write
	#0.5 clk = 1'b1;   
	#0.5 clk = 1'b0;

	// Immediate read-back verification
	WEN_xmem = 1;  // Switch to read mode
	CEN_xmem = 0;  // Keep memory enabled
    
	#0.5 clk = 1'b1;
	#0.5 clk = 1'b0;
    
    
	if (core_instance.xmem_out != D_xmem) begin
    	$display("  WRITE ERROR at address %h!", A_xmem);
	end
  end

  // Reset control signals
  WEN_xmem = 1;  
  CEN_xmem = 1;
  A_xmem = 0;
  #0.5 clk = 1'b1;
  #0.5 clk = 1'b0;

  $display("\n=== Write Phase Complete, Starting Full Verification ===\n");

  // Now verify the written data
  $display("\n=== Starting Memory Read Verification ===");
  A_xmem = 0;  // Reset address
 
  for (t=0; t<len_nij; t=t+1) begin  
	// Setup read address and control
	#0.5 clk = 1'b0;   
	CEN_xmem = 0;  // Enable read
	WEN_xmem = 1;  // Set to read mode
	$display("Read cycle %0d - Address: %h, CEN: %b, WEN: %b", t, A_xmem, CEN_xmem, WEN_xmem);
    
	// Clock edge to register address
	#0.5 clk = 1'b1;   
	#0.5 clk = 1'b0;
    
	// Read and verify data
	$display("  Current address: %h, xmem_out: %h, Expected: %h",
         	A_xmem, core_instance.xmem_out, activation_data[t]);
    
	if (core_instance.xmem_out == activation_data[t])
    	$display("  Activation data [%0d] matched", t);
	else begin
    	$display("  Activation data [%0d] ERROR!", t);
    	error_activation = error_activation + 1;
	end
    
	// Increment address for next cycle
	if (t < len_nij-1) A_xmem = A_xmem + 1;
    
	#0.5 clk = 1'b1;
  end

  // Reset control signals
  #0.5 clk = 1'b0;  
  CEN_xmem = 1;  
  WEN_xmem = 1;  
  A_xmem = 0;    
  #0.5 clk = 1'b1;

  if (error_activation == 0)
  	$display("All activation data verified successfully!");
  else
  	$display("Found %0d errors in activation data verification!", error_activation);

  $fclose(x_file);
  $display("=== Finished Activation Data Writing and Verification ===\n");
  /////////////////////////////////////////////////


  for (kij=0; kij<9; kij=kij+1) begin  // kij loop

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
    

	w_file = $fopen(w_file_name, "r");
	// Following three lines are to remove the first three comment lines of the file
	w_scan_file = $fscanf(w_file,"%s", captured_data);
	w_scan_file = $fscanf(w_file,"%s", captured_data);
	w_scan_file = $fscanf(w_file,"%s", captured_data);

	#0.5 clk = 1'b0;   reset = 1;
	#0.5 clk = 1'b1;

	for (i=0; i<10 ; i=i+1) begin
  	#0.5 clk = 1'b0;
  	#0.5 clk = 1'b1;  
	end

	#0.5 clk = 1'b0;   reset = 0;
	#0.5 clk = 1'b1;

	#0.5 clk = 1'b0;   
	#0.5 clk = 1'b1;   





	/////// Kernel data writing to memory ///////

	A_xmem = 11'b10000000000;

	for (t=0; t<col; t=t+1) begin  
  	#0.5 clk = 1'b0;  w_scan_file = $fscanf(w_file,"%32b", D_xmem); WEN_xmem = 0; CEN_xmem = 0; if (t>0) A_xmem = A_xmem + 1;
  	#0.5 clk = 1'b1;  
	end

	#0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0;
	#0.5 clk = 1'b1;
	/////////////////////////////////////




	/////// Kernel data writing to L0 ///////
	A_xmem = 11'b10000000000;
	#0.5 clk = 1'b0;  WEN_xmem = 1; CEN_xmem = 0;
	#0.5 clk = 1'b1;  

	for (t=0; t<col; t=t+1) begin
  	  #0.5 clk = 1'b0;  
  	  l0_wr = 1;
  	  if (t>0) A_xmem = A_xmem + 1;
  	  #0.5 clk = 1'b1;
	end

	// Add one more cycle to capture the last weight
	#0.5 clk = 1'b0;
	#0.5 clk = 1'b1;

	// Now disable signals
	#0.5 clk = 1'b0;  l0_wr = 0; CEN_xmem = 1;
	#0.5 clk = 1'b1;
	/////////////////////////////////////



	/////// Kernel loading to PEs ///////
	#0.5 clk = 1'b0;  
	load = 1; 
	l0_rd = 1;
	execute = 0;  // Ensure execute is off during loading
	#0.5 clk = 1'b1;

	// Wait for 8 cycles to ensure all weights are loaded to PEs
	repeat(8) begin  // One cycle per weight
	    #0.5 clk = 1'b0;
	    #0.5 clk = 1'b1;
	end

	// Add stabilization cycles after weight loading
	#0.5 clk = 1'b0;  
	load = 0;  // Disable load after weights are in PEs
	l0_rd = 0;  // Disable L0 read
	#0.5 clk = 1'b1;

	// Add more stabilization cycles
	repeat(4) begin
	    #0.5 clk = 1'b0;
	    #0.5 clk = 1'b1;
	end

	/////////////////////////////////////



	////// provide some intermission to clear up the kernel loading ///
	#0.5 clk = 1'b0;  load = 0; l0_rd = 0;
	#0.5 clk = 1'b1;  
 

	for (i=0; i<10 ; i=i+1) begin
  	#0.5 clk = 1'b0;
  	#0.5 clk = 1'b1;  
	end
	/////////////////////////////////////



	/////// Activation data writing to L0 ///////
	A_xmem = 0;
	#0.5 clk = 1'b0;  WEN_xmem = 1; CEN_xmem = 0;
	#0.5 clk = 1'b1;  

	// Modified to write row values at a time
	for (t=0; t<len_nij/row; t=t+1) begin  // Divide len_nij by row since we're writing row values at once
	    #0.5 clk = 1'b0;  
	    l0_wr = 1;
	    if (t>0) A_xmem = A_xmem + row;  // Increment by row to get next set of values
	    #0.5 clk = 1'b1;
	end

	#0.5 clk = 1'b0;  l0_wr = 0; CEN_xmem = 1;
	#0.5 clk = 1'b1;
	/////////////////////////////////////



	/////// Execution ///////
	#0.5 clk = 1'b0;  
	execute = 1;
	l0_rd = 1;     // Read from L0 during execution
	l0_wr = 1;     // Write activations to L0
	CEN_xmem = 0;  // Enable memory reads
	WEN_xmem = 1;  // Read mode
	A_xmem = 0;    // Start from first activation
	$display("=== Starting Execution ===");
	#0.5 clk = 1'b1;

	for (i=0; i<len_nij+1; i=i+1) begin
		#0.5 clk = 1'b0;
		
		if (i==len_nij) begin 
			execute = 0; 
			ififo_rd = 0;
			CEN_xmem = 1;  // Disable memory
			$display("Finished execution");
		end else begin
			A_xmem = i;  // Update address for next activation read
		end
		
		$display("Execution cycle %0d: A_xmem=%h, xmem_out=%h", i, A_xmem, core_instance.xmem_out);
		
		#0.5 clk = 1'b1;
	end
	/////////////////////////////////////



	//////// OFIFO READ ////////
	// Ideally, OFIFO should be read while execution, but we have enough ofifo
	// depth so we can fetch out after execution.
	for (i=0; i<len_onij; i=i+1) begin
  	  #0.5 clk = 1'b0;
  	  if (ofifo_valid) begin
  		  ofifo_rd = 1;
  		  #1;
  	  end
  	  #0.5 clk = 1'b1;
  	  #1;
	end

	#0.5 clk = 1'b0; ofifo_rd = 0;
	#0.5 clk = 1'b1;
	/////////////////////////////////////


  end  // end of kij loop


  ////////// Accumulation /////////
  out_file = $fopen("psum.txt", "r");  

  // Following three lines are to remove the first three comment lines of the file
  out_scan_file = $fscanf(out_file,"%s", answer);
  out_scan_file = $fscanf(out_file,"%s", answer);
  out_scan_file = $fscanf(out_file,"%s", answer);

  error = 0;



  $display("############ Verification Start during accumulation #############");

  for (i=0; i<len_onij+1; i=i+1) begin

	#0.5 clk = 1'b0;
	#0.5 clk = 1'b1;

	if (i>0) begin
     out_scan_file = $fscanf(out_file,"%128b", answer); // reading from out file to answer
       if (sfp_out == answer)
   	  $display("%2d-th output featuremap Data matched! :D", i);
       else begin
   	  $display("%2d-th output featuremap Data ERROR!!", i);
   	  $display("sfpout: %128b", sfp_out);
   	  $display("answer: %128b", answer);
   	  error = 1;
       end
	end
   
 
	#0.5 clk = 1'b0; reset = 1;
	#0.5 clk = 1'b1;  
	#0.5 clk = 1'b0; reset = 0;
	#0.5 clk = 1'b1;  

	for (j=0; j<len_kij+1; j=j+1) begin

  	#0.5 clk = 1'b0;   
  	  if (j<len_kij) begin CEN_pmem = 0; WEN_pmem = 1; A_pmem = j; end
         			  else  begin CEN_pmem = 1; WEN_pmem = 1; end

  	  if (j>0)  acc = 1;  
  	#0.5 clk = 1'b1;   
	end

	#0.5 clk = 1'b0; acc = 0;
	#0.5 clk = 1'b1;
  end


  if (error == 0) begin
      $display("############ No error detected ##############");
      $display("########### Project Completed !! ############");

  end

  for (t=0; t<10; t=t+1) begin  
	#0.5 clk = 1'b0;  
	#0.5 clk = 1'b1;  
  end

  #10 $finish;

end

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
   l0_rd_q	<= l0_rd;
   l0_wr_q	<= l0_wr ;
   execute_q  <= execute;
   load_q 	<= load;
end


endmodule









