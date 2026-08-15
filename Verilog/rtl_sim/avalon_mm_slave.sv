module avalon_mm_slave #(parameter N = 8, parameter [2:0] K = 7 /* Actually K - 1 */)( // Built for N = 8
	input  logic 			clk,
	input  logic 			reset,
	input  logic [6:0] 	address, // 0-15 is reg, 16-31 is A, 32-47 is B, 64-128 is C.
	input  logic 			read,
	input  logic 			write,
	input  logic [31:0] 	writedata,
	output logic [31:0] 	readdata);
	
	
	logic [31:0] register [15:0];  // 0 is ctrlwr, 1 is ctrlrd, 2 is ID, 3 is rwtest
											 // ctrlwr: 0 - start
											 // ctrlrd: 0 - done, 1- busy
	// Register words
	localparam ctrlwr = 0;
	localparam ctrlrd = 1;
	localparam ID = 2;
	localparam rwtest = 3;
	
	// Ctrlwr positions
	localparam start = 0;
	
	// Ctrlrd positions
	localparam done = 0;
	localparam busy = 1;
	
	logic wrena, wrenb;
	logic [31:0] C_val; // The currently read value of C
	logic [63:0] reada, readb;
	logic [31:0] breada, breadb;
	logic [7:0] a_col [7:0];
	logic [7:0] b_row [7:0];
	
	// Load the unpacked values from the RAM into packed values for the MAC
	always_comb begin
		for(int i = 0; i < 8; i = i + 1) begin
			a_col[i] = reada[i * 8 +: 8];
			b_row[i] = readb[i * 8 +: 8];
		end
	end
	
	// Down counter to select for mac array
	logic [2:0] k_counter;
	
	// Same counter, delayed a clock cycle
	logic [2:0] delayed_k;
	
	arr_ram a_ram (.clk, .wren(wrena), .wradr(address[3:0]), .rdadr (address[3:0]), .writedata, .busreaddata(breada), .index(K - k_counter), .readdata(reada /* A should be stored transposed */));
	arr_ram b_ram (.clk, .wren(wrenb), .wradr(address[3:0]), .rdadr (address[3:0]), .writedata, .busreaddata(breadb), .index(K - k_counter), .readdata(readb));
	
	
	// Clear logic for the mac array
	logic clear, enable;
	assign enable = register[ctrlrd][busy];
	assign clear = delayed_k == K;
				
	
	mac_arr c_arr (.clk, .clear, .enable, .col_index(/* For reading, row major order*/ address[2:0]), .row_index(address[5:3]), .a_col, .b_row, .C(C_val));
	
	// RAM controls
	always_comb begin
		wrena = 0;
		wrenb = 0;
		case(address[6:4])
			3'b001: wrena = (write) ? 1'b1 : 1'b0;
			3'b010: wrenb = (write) ? 1'b1 : 1'b0;	
			default:;
		endcase
	end
	
	logic [6:0] prev_addr; 	// registered address
	logic [31:0] delaydata; // registered readdata
	
	// Output mux
	always_comb begin
		case(prev_addr[6:4])
			3'b000: 	readdata = delaydata;
			3'b001: 	readdata = breada;
			3'b010: 	readdata = breadb;
			3'b100: 	readdata = C_val; // Could just use casex and that would be cleaner, but this ensures I don't miss a bug re: an actual X value
			3'b101: 	readdata = C_val;
			3'b110: 	readdata = C_val;
			3'b111: 	readdata = C_val;
			default: readdata = '0;
		endcase
	end
	
	logic k_finish;
	
	// Delayed (register) read data and writing, plus array driver registering
	always_ff @(posedge clk) begin
		if (reset) begin
			register <= '{default: '0};
			delaydata <= '0;
			prev_addr <= '0;
			k_counter <= '0;
			delayed_k <= '0;
			k_finish <= 0;
		end
		else begin
			delaydata <= '0;
			if (write) begin
				if(address == ctrlwr & writedata[0]) begin 	// If writing to ctrlwr with bit 0 on, start the calculation
					k_counter <= K;
					register[ctrlrd][busy] <= 1;
					register[ctrlrd][done] <= 0;
				end
				if(address == rwtest)
					register[rwtest] <= writedata;
			end
			if (read)
				if(address == ID) 	// If reading ID, give a fixed value (no need to store this in flip flops)
					delaydata <= 32'habcd0000;
				else if (address < 16)	 	// Otherwise actually read if in a reg
					delaydata <= register[address];
			prev_addr <= address;
			
			// Array driver stuff
			if(k_counter != 0) begin
				k_counter <= k_counter - 3'b1;
				k_finish <= 0;
			end
			delayed_k <= k_counter;
			if(delayed_k == 1)
				k_finish <= 1;
			if(delayed_k == 0 && k_finish) begin
				register[ctrlrd][busy] <= 0;
				register[ctrlrd][done] <= 1;
				k_finish <= 0;
			end
		end
	end
	
endmodule