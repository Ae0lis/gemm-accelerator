module MacDriver(clk, reset, done, array);
	parameter m = 3;
	parameter n = 5;
	parameter p = 2;
	
	input logic 						clk, reset;
	output logic signed [31:0] 	array [m - 1:0] [p - 1:0];
	output logic 						done;
	
	logic valid, clear;
	
	logic signed [7:0] 	a, b;
	logic signed [7:0] 	A	[m - 1:0] [n - 1:0];
	logic signed [7:0] 	B	[n - 1:0] [p - 1:0];
	
	initial begin
			$readmemh("C:/Users/benpr/Projects/Systolic Array/Python/vectors/rect_3x5x2_A.hex", A);
			$readmemh("C:/Users/benpr/Projects/Systolic Array/Python/vectors/rect_3x5x2_B.hex", B);
	end
	
	logic signed [31:0] 	sum;
	logic			 [12:0]  mps, mns;
	logic			 [12:0]  nps, nns;
	logic			 [12:0]  pps, pns;
	
	
	MAC calculator (.a, .b, .valid, .clk, .clear, .sum);
	
	always_comb begin
		if(nps == n) begin	/* WARNING: This *will* read into uninitialized memory. This is done to pad out one cycle.
										As the resulting unknown sum is cleared immediately, this doesn't actually matter here.
										There are safer ways to do this, but this was an easy band-aid fix and this isn't meant
										to be a final product, just a test run. Still, watch out! */
			nns = 0;
			if(pps == p - 1) begin
				pns = 0;
				mns = mps + 1;
			end
			else begin
				pns = pps + 1;
				mns = mps;
			end
		end
		else begin
			nns = nps + 1;
			pns = pps;
			mns = mps;
		end
		
		a = A[mps][nps];
		b = B[nps][pps];
	end
		
	
	always_ff @(posedge clk) begin
		if(reset) begin
			valid 	<= 0;
			clear 	<= 0;
			done		<= 0;
			array 	<= '{default: '0};
			mps 		<= 0;
			nps		<= 0;
			pps 		<= 0;
		end
		else if(done) begin
			valid <= 0;
			done 	<= 1;
		end
		else if (mps == m) begin
			done 	<= 1;
			valid <= 0;
		end
		else if(nps == 0) begin
			valid <= 1;
			if(clear == 0) begin
				clear <= 1;
			end
			else begin
				clear <= 0;
				mps <= mns;
				nps <= nns;
				pps <= pns;
			end
		end
		else begin
			valid <= 1;
			clear <= 0;
			mps <= mns;
			nps <= nns;
			pps <= pns;
		end
		
		if(!reset && !done && nps == n)
			array[mps][pps] <= sum;
	end
	
endmodule 


module macdriver_testbench();
	parameter m = 3;
	parameter n = 5;
	parameter p = 2;
	
	logic clk, reset, done;
	logic signed [31:0] array [m - 1:0] [p - 1:0];
	
	logic signed [31:0] 	C 	[m - 1:0] [p - 1:0];
	
	initial begin
		$readmemh("C:/Users/benpr/Projects/Systolic Array/Python/vectors/rect_3x5x2_C.hex", C);
	end
	
	MacDriver dut(.clk, .reset, .done, .array);

	// Set up a simulated clock.
	parameter CLOCK_PERIOD=100;
	initial begin
		clk <= 0;
		forever #(CLOCK_PERIOD/2) clk <= ~clk; // Forever toggle the clock
	end
	
	integer i, j, errors;
	initial begin
		errors = 0;
						@(posedge clk);
		reset <= 1;	@(posedge clk);
		reset <= 0; @(posedge clk);
						@(posedge done);
		repeat(5)	@(posedge clk);
		for(i = 0; i < m; i = i + 1) begin
			for(j = 0; j < p; j = j + 1) begin
				if(!(array[i][j] === C[i][j])) begin
					errors = errors + 1;
					$error("Mismatch at [%0d][%0d]!", i, j);
				end
			end
		end
		
		if(errors == 0)
			$display("All clear");
		else
			$display("WARNING! Caught %0d errors!", errors);
		$stop;
	end
endmodule
