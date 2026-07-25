module slave_testbench();
	logic clk, reset, read, write;
	logic [1:0] address;
	logic [31:0] writedata, readdata;
	
	avalon_mm_slave dut (.clk, .reset, .read, .write, .address, .writedata, .readdata);
	
	logic [31:0] mirror [4];
	integer errorcount;
	
	parameter CLOCK_PERIOD = 100;
	initial begin
		clk <= 0;
		forever #(CLOCK_PERIOD/2) clk <= ~clk;
	end
	
	task automatic write_task(input logic [1:0] addr, input logic [31:0] data);
	
		address <= addr;
		writedata <= data;
		write <= 1;
		if(addr != 2'b01)
			mirror[addr] = data;
		@(posedge clk);
		write <= 0;
		
	endtask
	
	task automatic read_task(input logic [1:0] addr);
		
		address <= addr;
		read <= 1;
		@(posedge clk);
		read <= 0;
		@(posedge clk);
		if(readdata !== mirror[addr]) begin
			$error("ERROR: Mirror check failed. Address: %h. Expected: %h. Got: %h.", addr, mirror[addr], readdata);
			errorcount = errorcount + 1;
		end
			
	endtask
	
	task automatic reset_task();
	
		mirror 		= '{default: '0};
		mirror[1] 	= 32'habcd0000;
		reset  		<= 1;
		read   		<= 0;
		write  		<= 0;
		address 		<= '0;
		writedata 	<= '0;
		@(posedge clk);
		reset 		<= 0;
	
	endtask
	
	integer i, roll, keep;
	logic [1:0] addr, prev_addr;
	
	initial begin
		reset_task();
		prev_addr = '0;
		errorcount = 0;
		for(i = 0; i < 1000; i = i + 1) begin
			roll = $urandom_range(10, 1);
			keep = $urandom_range(10, 1);
			addr = $urandom_range(3, 0);
			case(roll)
				1: reset_task();
				2: read_task(addr);
				3: read_task(addr);
				4: read_task(addr);
				5: write_task(.addr((keep > 7) ? addr : prev_addr), .data($urandom));
				6: write_task(.addr((keep > 7) ? addr : prev_addr), .data($urandom));
				7: write_task(.addr((keep > 7) ? addr : prev_addr), .data($urandom));
				8: @(posedge clk);
				9: @(posedge clk);
				10: @(posedge clk);
			endcase
			prev_addr = addr;
		end
		
		$display("Total error count: %0d", errorcount); 
		$stop;
	end
endmodule
	
	