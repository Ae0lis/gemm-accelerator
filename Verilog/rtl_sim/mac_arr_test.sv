module mac_arr_testbench #(parameter N = 2)();
	logic clk, clear;
	logic enable;
	logic [$clog2(N)-1:0] col_index;
	logic [$clog2(N)-1:0] row_index;
	logic [7:0] a_col [N - 1:0];
	logic [7:0] b_row [N - 1:0];
	logic signed [31:0] C;
	
	
	mac_arr #(.N(N)	) dut (.clk, .clear, .enable, .col_index, .row_index, .a_col, .b_row, .C);
	
	localparam CLOCK_PERIOD = 100;
	initial begin
		clk <= 0;
		forever #(CLOCK_PERIOD/2) clk <= ~clk;
	end
	
	task automatic reset_task();
	
		clear <= 1;
		enable <= 1;
		@(posedge clk);
		clear <= 0;
		enable <= '{default: 0};
		@(posedge clk);
		
	endtask
	
	task automatic arr_test();
		/* A:
				2 4
				3 5
			B:
				1 6
				7 8
					*/
		clear = 1;
		enable = 1;
		a_col[1] = 3;
		a_col[0] = 2;
		b_row[1] = 6;
		b_row[0] = 1;
		@(posedge clk);
		clear = 0;
		a_col[1] = 5;
		a_col[0] = 4;
		b_row[1] = 8;
		b_row[0] = 7;
		@(posedge clk);
		enable = 0;;
		col_index = 0;
		row_index = 0;
		@(posedge clk);
		col_index = 1;
		@(posedge clk)
		col_index = 0;
		row_index = 1;
		@(posedge clk)
		col_index = 1;
		@(posedge clk);
		@(posedge clk);
	endtask
	
	initial begin
		reset_task();
		arr_test();
		arr_test();
		arr_test();
		$stop;
	end
		
		
		
endmodule 