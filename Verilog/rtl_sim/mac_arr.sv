/* An array of MACs. Size is NxN. Clear only works if enable is high. Outputs 1 32 bit number at a time, based on the 
indexes provided by the caller.  */
module mac_arr #(
					parameter N = 8
					)(
					input logic clk,
					input logic clear,
					input logic enable,
					input logic [$clog2(N)-1:0] col_index, // 2:0
					input logic [$clog2(N)-1:0] row_index, // 2:0
					input logic [7:0] a_col [N - 1:0], 		// 7:0
					input logic [7:0] b_row [N - 1:0],
					output logic signed [31:0] C);

	logic signed [31:0] C_internal [N - 1:0][N - 1:0];
	

	genvar i, j;
	generate
		for(i = 0; i < N; i = i + 1) begin: row
			for(j = 0; j < N; j = j + 1) begin: column
				// Note: Clear will not go through unless valid is high
				MAC pe (.a(a_col[i]), .b(b_row[j]), .valid(enable), .clk, .clear, .sum(C_internal[i][j]) );
			end
		end
	endgenerate
	
	always_ff @(posedge clk) begin
		C <= C_internal[row_index][col_index];
	end

endmodule 