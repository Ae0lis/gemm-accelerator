module arr_ram #(
					parameter N = 8
					)(
					input logic clk,
					input logic wren,
					input logic [$clog2(boxes) - 1:0] wradr, // 3:0
					input logic [$clog2(boxes) - 1:0] rdadr, // 3:0
					input logic [31:0] writedata, 	// Write 32 bits at a time
					output logic [31:0] busreaddata, // Software read
					input logic [$clog2(pile_depth) - 1:0] index, // 2:0
					output logic [63:0] readdata); 	// read a full row (64 bits) at a time
			
	
	
	localparam boxes = (N * N) / 4; 		// Number of 'boxes' - 4-byte locations to write to (each # is a byte, so we need N^2/4)
													// @ N = 8, boxes = 16
	localparam pile_depth = boxes / 2; 	// Number of boxes per 'pile'
													// @ N = 8, pile_depth = 8
	
	// Splitting the boxes into odd and even 'piles', so write can write to any of them but read reads 2 at once
	logic [31:0] odd  [pile_depth - 1:0]; 
	logic [31:0] even [pile_depth - 1:0];
	
	always_ff @(posedge clk) begin
		// If write enable, write!
		if(wren)
			if(wradr[0])
				odd[wradr[$clog2(boxes) - 1:1]] <= writedata;
			else
				even[wradr[$clog2(boxes) - 1:1]] <= writedata;
			
		// Before it's written to, this will be X
		busreaddata <= (rdadr[0]) ? odd[rdadr[$clog2(boxes) - 1:1]] : even[rdadr[$clog2(boxes) - 1:1]];
		readdata <= { odd[index],  even[index] };
	end
	
	
		
endmodule