module sfp (
	input  wire             	clk,
	input  wire             	reset,
	input  wire             	en,     	 
	input  wire             	acc_clear,   
	input  wire             	relu_en,	 
	input  wire signed [31:0]   data_in,    
	input  wire             	data_valid,  
	output reg  signed [31:0]   data_out,   
	output reg              	out_valid    
);

	// Internal registers
	reg signed [31:0] acc_reg;
	reg           	valid_pipe;

	// ReLU function
	function [31:0] relu;
    	input [31:0] value;
    	begin
        	relu = (value[31]) ? 32'd0 : value;
    	end
	endfunction

	// Accumulation logic with proper reset
	always @(posedge clk) begin
    	if (reset) begin
        	acc_reg <= 32'd0;
        	valid_pipe <= 1'b0;
        	data_out <= 32'd0;
        	out_valid <= 1'b0;
    	end
    	else if (en) begin
        	if (acc_clear) begin
            	acc_reg <= data_valid ? data_in : 32'd0;
            	valid_pipe <= data_valid;
        	end
        	else if (data_valid) begin
            	acc_reg <= acc_reg + data_in;
            	valid_pipe <= 1'b1;
        	end
       	 
        	// Output stage
        	if (valid_pipe) begin
            	data_out <= relu_en ? relu(acc_reg) : acc_reg;
            	out_valid <= 1'b1;
        	end
        	else begin
            	out_valid <= 1'b0;
        	end
    	end
    	else begin
        	valid_pipe <= 1'b0;
        	out_valid <= 1'b0;
    	end
	end

endmodule
