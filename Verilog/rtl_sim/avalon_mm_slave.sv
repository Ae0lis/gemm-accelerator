module avalon_mm_slave(
	input  logic 			clk,
	input  logic 			reset,
	input  logic [1:0] 	address,
	input  logic 			read,
	input  logic 			write,
	input  logic [31:0] 	writedata,
	output logic [31:0] 	readdata);
	
	
	logic [31:0] register [4];
	
	always_ff @(posedge clk) begin
		if (reset) begin
			register <= '{default: '0};
			readdata <= '0;
		end
		else begin
			readdata <= '0;
			if (write)
				if(address != 2'b01)
					register[address] <= writedata;
			if (read)
				if(address == 2'b01)
					readdata <= 32'habcd0000;
				else
					readdata <= register[address];
		end
			
	end
	
endmodule