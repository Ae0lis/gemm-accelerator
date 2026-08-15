module arr_ram_testbench();

	localparam N = 8;
	localparam boxes = (N * N) / 4; 		// Number of 'boxes' - 4-byte locations to write to (each # is a byte, so we need N^2/4)
	localparam pile_depth = boxes / 2; 	// Number of boxes per 'pile'

	logic clk, wren;
	logic [$clog2(boxes) - 1:0] wradr;
	logic [$clog2(boxes) - 1:0] rdadr;
	logic [31:0] writedata; 	// Write 32 bits at a time
	logic [31:0] busreaddata; // Software read
	logic [$clog2(pile_depth) - 1:0] index;
	logic [63:0] readdata; 
	
	arr_ram #(.N(N)) dut (.clk, .wren, .wradr, .rdadr, .writedata, .busreaddata, .index, .readdata);
	
	parameter CLOCK_PERIOD = 100;
	initial begin
		clk <= 0;
		forever #(CLOCK_PERIOD/2) clk <= ~clk;
	end
	
	
	task automatic write(input logic [$clog2(boxes) - 1:0] addr, input logic [31:0] data);
		
		wren = 1;
		wradr = addr;
		writedata = data;
		@(posedge clk);
		wren = 0;
		@(posedge clk);
	
	endtask
	
	task automatic read(input logic [$clog2(boxes) - 1:0] addr);
	
		rdadr = addr;
		@(posedge clk);
		$display(busreaddata);
		@(posedge clk);
		
	endtask
	
	task automatic checkall(input logic [$clog2(boxes) - 1:0] addr, input logic [31:0] data);
	
		wren = 1;
		wradr = addr + 2;
		rdadr = addr;
		index = addr;
		writedata = data;
		@(posedge clk);
		$display(busreaddata);
		$display(readdata);
		wren = 0;
		@(posedge clk);
	
	endtask
	
	task automatic reset();
	
		wren = 0;
		wradr = 0;
		rdadr = 0;
		index = 0;
		writedata = '0;
		
	endtask
		
		
	initial begin
		reset();
		write(.addr(0), .data(32'h10));
		write(.addr(1), .data(32'h20));
		read(.addr(0));
		read(.addr(1));
		checkall(.addr(0), .data(32'h30));
		read(.addr(2));
		@(posedge clk);
		$stop;
	end
endmodule