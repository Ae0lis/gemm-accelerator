module MAC(a, b, valid, clk, clear, sum);
	input  logic signed 	[7:0] 	a, b; 					// Matrix cells
	input  logic 						valid, clk, clear; 	// Boring stuff
	output logic signed	[31:0] 	sum; 						// Total sum
	
	always_ff @(posedge clk) begin
		if (valid)
			sum <= (clear) ? a * b : (a * b) + sum;
	end
	
endmodule

module mac_testbench();
	parameter m = 3;
	parameter n = 5;
	parameter p = 2;
	logic signed [7:0] 	a, b;
	logic signed [7:0] 	A	[m - 1:0] [n - 1:0];
	logic signed [7:0] 	B	[n - 1:0] [p - 1:0];
	logic signed [31:0] 	C 	[m - 1:0] [p - 1:0];
	logic signed [31:0] 	sum;
	logic 					valid, clk, clear;
	
	initial begin
		$readmemh("C:/Users/benpr/Projects/Systolic Array/Python/vectors/rect_3x5x2_A.hex", A);
		$readmemh("C:/Users/benpr/Projects/Systolic Array/Python/vectors/rect_3x5x2_B.hex", B);
		$readmemh("C:/Users/benpr/Projects/Systolic Array/Python/vectors/rect_3x5x2_C.hex", C);
	end
	
	MAC dut (.a, .b, .valid, .clk, .clear, .sum);
	
	// Set up a simulated clock.
	parameter CLOCK_PERIOD=100;
	initial begin
		clk <= 0;
		forever #(CLOCK_PERIOD/2) clk <= ~clk; // Forever toggle the clock
	end

	integer i, j, k, errors;
	
	// Set up the inputs to the design. Each line is a clock cycle.
	initial begin
		errors = 0;
		assert(n >= 2)																			// IMPORTANT: This testbench only works for matricies where n >= 2
			else $fatal("Dimension n must be at least 2!");
		for(i = 0; i < m; i = i + 1) begin												// Check all vectors
			for(j = 0; j < p; j = j + 1) begin 	
				clear <= 1; a <= A[i][0]; b <= B[0][j];		@(posedge clk);   // Check valid
				valid <= 1;												@(posedge clk);   // Begin checking vector
				clear <= 0; a <= A[i][1]; b <= B[1][j];		@(posedge clk); 	// Assumes n >= 2
				for(k = 2; k < n; k = k + 1) begin										// Test the rest of the vector
					a <= A[i][k]; b <= B[k][j];					@(posedge clk); 
				end
				a <= A[i][0]; b <= B[0][j];	valid <= 0;		@(posedge clk);   // Check valid on the cycle it's driven high
				assert (sum === C[i][j])													// Does the calculation work?
					else begin
						$error("C does not match!");
						errors = errors + 1;
					end
					
																			@(posedge clk);
				repeat (3)												@(posedge clk);
				assert (sum === C[i][j])													// Does it properly hold until clear is driven to 1?
					else begin
						$error("C did not hold/match!");									
						errors = errors + 1;
					end
																			@(posedge clk);
			end
		end
		
		if(errors == 0)
			$display("All clear");
		else
			$display("WARNING! Caught %0d errors!", errors);
		$stop; // End the simulation.
	end
endmodule