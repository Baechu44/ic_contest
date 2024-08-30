//`include 	"./cross_product_v2.v"
`define		state_wait		3'd0
`define		state_check1	3'd1
`define		state_check2	3'd2
`define		state_check3	3'd3
`define		state_check4	3'd4
`define		state_check5	3'd5
`define		state_check6	3'd6


module is_inside (clk, reset, finish_sort, Obj, new_G1, new_G2, new_G3, new_G4, new_G5, new_G6, valid, is_inside);
input			clk;
input			reset;
input			finish_sort;
input	[19:0]	Obj, new_G1, new_G2, new_G3, new_G4, new_G5, new_G6;

output			valid;
output			is_inside;

reg		[2:0]	cs, ns;

reg		[19:0]	A2, A3;

wire	[21:0]	S1, S2;

reg				is_inside;
wire			cloclwise;

wire			valid_1, valid;
reg				valid_2;


//*******************************************************************************  FSM
always @ (posedge clk or posedge reset)
	if (reset)
		cs <= `state_wait;
	else
		cs <= ns;

always @ (*)
	case (cs)
		`state_wait:	ns = (finish_sort)? `state_check1 : `state_wait;
		`state_check1: 	ns = (cloclwise)? 	`state_check2 : `state_wait;
		`state_check2:	ns = (cloclwise)?	`state_check3 : `state_wait;
		`state_check3:	ns = (cloclwise)? 	`state_check4 : `state_wait;
		`state_check4:	ns = (cloclwise)?   `state_check5 : `state_wait;
		`state_check5:	ns = (cloclwise)? 	`state_check6 : `state_wait;
		`state_check6:	ns = `state_wait;
		default:		ns = 3'dx;
	endcase
//*******************************************************************************  FSM

sub s1 (A2, Obj, S1);
sub s2 (A3, A2, S2);

cross_product c1 (S1[21:11], S1[10:0], S2[21:11], S2[10:0], cloclwise);

//*******************************************************************************  cross_product input
always @ (*)
	case (cs)
		`state_check1:
			begin
				A2 = new_G1;
				A3 = new_G2;
			end
		`state_check2:
			begin
				A2 = new_G2;
				A3 = new_G3;
			end
		`state_check3:
			begin
				A2 = new_G3;
				A3 = new_G4;
			end		
		`state_check4:
			begin
				A2 = new_G4;
				A3 = new_G5;
			end
		`state_check5:
			begin
				A2 = new_G5;
				A3 = new_G6;
			end
		`state_check6:
			begin
				A2 = new_G6;
				A3 = new_G1;
			end
		default:
			begin
				A2 = 20'dx;
				A3 = 20'dx;
			end	
	endcase
//*******************************************************************************  cross_product input


//*******************************************************************************  cross_product output
always @ (posedge clk)
	is_inside <= cloclwise;

assign valid_1 = (cs == `state_wait);

always @ (posedge clk)
	valid_2 <= ~valid_1;

assign valid = valid_1 & valid_2;


endmodule
