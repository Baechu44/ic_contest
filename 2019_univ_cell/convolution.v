`include 	"./multiplier.v"

`define		state_initial		4'd0	
`define		state_compute_1		4'd1		
`define		state_compute_2		4'd2
`define		state_compute_3		4'd3
`define		state_compute_4		4'd4
`define		state_compute_5		4'd5
`define		state_compute_6		4'd6
`define		state_compute_7		4'd7
`define		state_compute_8		4'd8
`define		state_compute_9		4'd9


module convolution (clk, reset, start, pixel, result_fixed, finish);
input				clk;
input				reset;
input				start;
input	[179:0]		pixel;
output	[19:0]		result_fixed;
output				finish;

reg		[3:0]		cs, ns;
reg		[19:0]		A, B;
reg		[39:0]		result, n_result;
wire	[39:0]		m, result_plus_m;
wire				finish_1, n_finish;
reg					finish_2, finish;

always @ (posedge clk or posedge reset)
	if (reset)
		cs <= `state_initial;
	else 
		cs <= ns;

always @ (*)
	case (cs)
		`state_initial: 	ns = (start)? `state_compute_1 : `state_initial;
		`state_compute_1:	ns = `state_compute_2;
		`state_compute_2:	ns = `state_compute_3;
		`state_compute_3:	ns = `state_compute_4;
		`state_compute_4:	ns = `state_compute_5;
		`state_compute_5:	ns = `state_compute_6;
		`state_compute_6:	ns = `state_compute_7;
		`state_compute_7:	ns = `state_compute_8;
		`state_compute_8:	ns = `state_compute_9;
		`state_compute_9:	ns = `state_initial;
	endcase

always @ (*)
	case (cs)
		`state_compute_1:
			begin
				A 		 = pixel[179:160];
				B 	 	 = 20'h0A89E;
				n_result = m;
			end
		`state_compute_2:
			begin
				A 		 = pixel[159:140];
				B 		 = 20'h092D5;
				n_result = result_plus_m;
			end
		`state_compute_3:
			begin
				A 		 = pixel[139:120];
				B 		 = 20'h06D43;
				n_result = result_plus_m;
			end
		`state_compute_4:
			begin
				A 		 = pixel[119:100];
				B 		 = 20'h01004;
				n_result = result_plus_m;
			end	
		`state_compute_5:
			begin
				A 		 = pixel[99:80];
				B 		 = 20'hF8F71;
				n_result = result_plus_m;
			end	
		`state_compute_6:
			begin
				A 	 	 = pixel[79:60];
				B 	 	 = 20'hF6E54;
				n_result = result_plus_m;
			end	
		`state_compute_7:
			begin
				A 		 = pixel[59:40];
				B 		 = 20'hFA6D7;
				n_result = result_plus_m;
			end	
		`state_compute_8:
			begin
				A 		 = pixel[39:20];
				B 		 = 20'hFC834;
				n_result = result_plus_m;
			end	
		`state_compute_9:
			begin
				A 		 = pixel[19:0];
				B 		 = 20'hFAC19;
				n_result = result_plus_m + 40'h0013100000;
			end	
		default:
			begin
				A 		 = 20'dx;
				B 		 = 20'dx;
				n_result = 40'dx;
			end	
	endcase

assign	result_fixed = (result[15] == 1'd1)? result[35:16] + 20'd1 : result[35:16];

always @ (posedge clk)
	if (cs == `state_initial) 
		result <= (result_fixed[19])? 40'h0 : result;
	else
		result <= n_result;

multiplier m1 (A, B, m);

assign result_plus_m = result + m;


assign finish_1 = (cs == `state_initial);

always @ (posedge clk)
	finish_2 <= ~finish_1; 
	
assign n_finish = finish_1 & finish_2;

always @ (posedge clk)
	finish <= n_finish;

endmodule


