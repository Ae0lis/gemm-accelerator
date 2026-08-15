module slave_testbench();
	logic clk, reset, read, write;
	logic [6:0] address;
	logic [31:0] writedata;
	logic signed [31:0] readdata;
	
	avalon_mm_slave dut (.clk, .reset, .read, .write, .address, .writedata, .readdata(readdata));
	
	logic [31:0] mirror [127:0];
	integer errorcount;
	
	parameter CLOCK_PERIOD = 100;
	parameter n = 8;
	initial begin
		clk <= 0;
		forever #(CLOCK_PERIOD/2) clk <= ~clk;
	end
	
	logic signed [7:0] 	A	[n - 1:0] [n - 1:0];
	logic signed [7:0]   A_t[n - 1:0] [n - 1:0]; // Transposed
	logic signed [7:0] 	B	[n - 1:0] [n - 1:0];
	logic signed [31:0] 	C 	[n - 1:0] [n - 1:0];
	
	initial begin
		$readmemh("C:/Users/benpr/Projects/Systolic Array/Python/vectors/med_8x8_A.hex", A);
		for(int i = 0; i < n; i = i + 1)
			for(int j = 0; j < n; j = j + 1)
				A_t[j][i] = A[i][j];
		$readmemh("C:/Users/benpr/Projects/Systolic Array/Python/vectors/med_8x8_B.hex", B);
		$readmemh("C:/Users/benpr/Projects/Systolic Array/Python/vectors/med_8x8_C.hex", C);
	end

	
	task automatic loada();
		
		for(int i = 0; i < 8; i = i + 1) begin
		
			writedata <= {A_t[i][3], A_t[i][2], A_t[i][1], A_t[i][0]};
			address <= 16 + (i * 2);
			write <= 1;
			@(posedge clk);
			writedata <= {A_t[i][7], A_t[i][6], A_t[i][5], A_t[i][4]};
			address <= 17 + (i * 2);
			@(posedge clk);
			
		end
		
		write <= 0;
		@(posedge clk);
		
	endtask
	
	task automatic loadb();
		
		for(int i = 0; i < 8; i = i + 1) begin
			writedata <= {B[i][3], B[i][2], B[i][1], B[i][0]};
			address <= 32 + (i * 2);
			write <= 1;
			@(posedge clk);
			writedata <= {B[i][7], B[i][6], B[i][5], B[i][4]};
			address <= 33 + (i * 2);
			@(posedge clk);
		end
		
		write <= 0;
		@(posedge clk);
	endtask
	
	reg [2:0] ireg, jreg;
	
	task automatic checkc();
	
		// Start calculations
		write <= 1;
		read <= 0;
		address <= '0;
		writedata <= 32'b1;
		@(posedge clk);
		
		// Make sure start worked
		write <= 0;
		read <= 1;
		address <= 7'b1;
		@(posedge clk);
		@(posedge clk)
		if(readdata !== 32'b10)
			$error("Failed to start working! Got: %0d", readdata);
			
		while(~readdata[0]) begin
			@(posedge clk);
		end
		
		$display("System finished, beginning check");
		
		for(int i = 0; i < 8; i = i + 1) begin
			for(int j = 0; j < 8; j = j + 1) begin
				read <= 1;
				ireg = i;
				jreg = j;
				address <= { 1'b1, ireg, jreg };
				@(posedge clk)
				@(posedge clk)
				if(readdata !== C[i][j])
					$display("C did not match golden model at row %0d, column %0d. Got: %0d. Expected: %0d.", i, j, readdata, C[i][j]);
				else
					$display("All good at row %0d, column %0d", i, j);
			end
		end
		
	endtask
	
	
	task automatic write_task(input logic [6:0] addr, input logic [31:0] data);
	
		address <= addr;
		writedata <= data;
		write <= 1;
		if(!(addr < 3 || addr > 63))
			mirror[addr] = data;
		@(posedge clk);
		write <= 0;
		
	endtask
	
	task automatic read_task(input logic [6:0] addr);
		
		address <= addr;
		read <= 1;
		@(posedge clk);
		read <= 0;
		@(posedge clk);
		if(readdata !== mirror[addr] && addr !== 7'b1) begin
			$error("ERROR: Mirror check failed. Address: %h. Expected: %h. Got: %h.", addr, mirror[addr], readdata);
			errorcount = errorcount + 1;
		end
			
	endtask
	
	task automatic reset_task();
	
		mirror 		= '{default: '0};
		mirror[2] 	= 32'habcd0000;
		reset  		<= 1;
		read   		<= 0;
		write  		<= 0;
		address 		<= '0;
		writedata 	<= '0;
		@(posedge clk);
		reset 		<= 0;
	
	endtask
	
	// Depricated testing task
	
	/* integer counter, j;
	
	task automatic count_task();
		
		counter = $urandom;
		writedata <= counter;
		write <= 1;
		address <= 7'h1;
		@(posedge clk)
		writedata <= 1'h1;
		address <= 7'h0;
		@(posedge clk)
		write <= 0;
		for(j = 0; j < counter; j = j + 1)
			@(posedge clk);
			
		@(posedge clk);
		read <= 1;
		address <= 7'h2;
		@(posedge clk);
		read <= 0;
		@(posedge clk);
		if(readdata !== 32'h0)  begin
			$error("ERROR: Counter failed Expected: %h. Got: %h.", 0, readdata);
			errorcount = errorcount + 1;
		end
		
	endtask */ 
	
	integer i, roll, keep;
	logic [1:0] addr, prev_addr;
	
	initial begin
		reset_task();
		prev_addr = '0;
		errorcount = 0;
		for(i = 0; i < 1000; i = i + 1) begin
			roll = $urandom_range(10, 1);
			keep = $urandom_range(10, 1);
			addr = (keep > 7) ? $urandom_range(7, 0) : prev_addr;
			case(roll)
				1: reset_task();
				2: read_task(.addr(addr));
				3: read_task(.addr(addr));
				4: read_task(.addr(addr));
				5: write_task(.addr(addr), .data($urandom));
				6: write_task(.addr(addr), .data($urandom));
				7: write_task(.addr(addr), .data($urandom));
				8: @(posedge clk);
				9: @(posedge clk);
				10: @(posedge clk);
			endcase
			prev_addr = addr;
		end
		$display("Total error count: %0d", errorcount); 
		loada();
		loadb();
		checkc();
		$stop;
	end
endmodule
	
	