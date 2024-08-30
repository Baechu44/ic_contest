`include 	"./cross_product_v2.v"

`define		state_load_Obj		5'd0
`define		state_load_G1		5'd1
`define		state_load_G2		5'd2
`define		state_load_G3		5'd3
`define		state_load_G4		5'd4
`define		state_load_G5		5'd5
`define		state_load_G6		5'd6

`define		state_change1_1		5'd7
`define		state_change1_2		5'd8
`define		state_change2_1		5'd9
`define		state_change2_2		5'd10

`define		state_check1		5'd11
`define		state_check2		5'd12
`define		state_check3		5'd13
`define		state_check4		5'd14
`define		state_check5		5'd15
`define		state_check6		5'd16

`define		state_wait			5'd17

module geofence ( clk,reset,X,Y,valid,is_inside);
input 			clk;
input 			reset;
input 	[9:0]	X;
input 	[9:0]	Y;
output 			valid;
output 			is_inside;

reg		[4:0]	cs, ns;

reg		[1:0]	count;

reg		[19:0]	Obj, G1, G2, G3, G4, G5, G6, n_Obj, n_G1, n_G2, n_G3, n_G4, n_G5, n_G6, A1, A2, B1, B2;

wire	[21:0]	S1, S2;

wire			cloclwise, valid_1, valid;

reg				is_inside, valid_2;

///////////////////////////////////////////////////////////
//				FSM
///////////////////////////////////////////////////////////
always @ (posedge clk or posedge reset)
	if (reset)
		cs <= `state_load_Obj;
	else
		cs <= ns;

always @ (*)
	case (cs)
		`state_load_Obj:		ns = `state_load_G1;
		`state_load_G1:			ns = `state_load_G2;
		`state_load_G2:			ns = `state_load_G3;
		`state_load_G3:			ns = `state_load_G4;
		`state_load_G4:			ns = `state_load_G5;
		`state_load_G5:			ns = `state_load_G6;
		`state_load_G6:			ns = `state_change1_1;
		
		`state_change1_1:		ns = `state_change1_2;
		`state_change1_2:		ns = `state_change2_1;
		`state_change2_1:		ns = `state_change2_2;
		`state_change2_2:		ns = (count == 2'd3)? `state_check1 : `state_change1_1;
		
		`state_check1: 			ns = (cloclwise)? 	`state_check2 : `state_wait;
		`state_check2:			ns = (cloclwise)?	`state_check3 : `state_wait;
		`state_check3:			ns = (cloclwise)? 	`state_check4 : `state_wait;
		`state_check4:			ns = (cloclwise)?   `state_check5 : `state_wait;
		`state_check5:			ns = (cloclwise)? 	`state_check6 : `state_wait;
		`state_check6:			ns = `state_wait;
		
		`state_wait:			ns = (valid)? 	`state_load_Obj : `state_wait;
		default:				ns = 5'dx;
	endcase
	
always @ (posedge clk)
	if (cs == `state_load_G6)
		count <= 2'd0;
	else  
		count <= (cs == `state_change1_1)? count + 2'd1 : count;


///////////////////////////////////////////////////////////
//				DFF
///////////////////////////////////////////////////////////
always @ (posedge clk) begin
	Obj <= n_Obj;
	G1  <= n_G1;
	G2  <= n_G2;
	G3  <= n_G3;
	G4  <= n_G4;
	G5  <= n_G5;
	G6	<= n_G6;
end

always @ (*)
	case (cs)
		`state_load_Obj:
			begin
				n_Obj = {X, Y};
				n_G1  = 20'dx;
				n_G2  = 20'dx;
				n_G3  = 20'dx;
				n_G4  = 20'dx;
				n_G5  = 20'dx;
				n_G6  = 20'dx;
			end
		`state_load_G1:	
			begin
				n_Obj = Obj;
				n_G1  = {X, Y};
				n_G2  = 20'dx;
				n_G3  = 20'dx;
				n_G4  = 20'dx;
				n_G5  = 20'dx;
				n_G6  = 20'dx;
			end
		`state_load_G2:
			begin
				n_Obj = Obj;
				n_G1  = G1;
				n_G2  = {X, Y};
				n_G3  = 20'dx;
				n_G4  = 20'dx;
				n_G5  = 20'dx;
				n_G6  = 20'dx;
			end
		`state_load_G3:
			begin
				n_Obj = Obj;
				n_G1  = G1;
				n_G2  = G2;
				n_G3  = {X, Y};
				n_G4  = 20'dx;
				n_G5  = 20'dx;
				n_G6  = 20'dx;
			end	
		`state_load_G4:
			begin
				n_Obj = Obj;
				n_G1  = G1;
				n_G2  = G2;
				n_G3  = G3;
				n_G4  = {X, Y};
				n_G5  = 20'dx;
				n_G6  = 20'dx;
			end	
		`state_load_G5:
			begin
				n_Obj = Obj;
				n_G1  = G1;
				n_G2  = G2;
				n_G3  = G3;
				n_G4  = G4;
				n_G5  = {X, Y};
				n_G6  = 20'dx;
			end	
		`state_load_G6:
			begin
				n_Obj = Obj;
				n_G1  = G1;
				n_G2  = G2;
				n_G3  = G3;
				n_G4  = G4;
				n_G5  = G5;
				n_G6  = {X, Y};
			end	
		
		`state_change1_1:
			begin
				n_Obj = Obj;
				n_G1  = G1;
				n_G2  = (cloclwise)? G2 : G3;
				n_G3  = (cloclwise)? G3 : G2;
				n_G4  = G4;
				n_G5  = G5;
				n_G6  = G6;
			end
		`state_change1_2:
			begin
				n_Obj = Obj;
				n_G1  = G1;
				n_G2  = G2;
				n_G3  = G3;
				n_G4  = (cloclwise)? G4 : G5;
				n_G5  = (cloclwise)? G5 : G4;
				n_G6  = G6;
			end
		`state_change2_1:
			begin
				n_Obj = Obj;
				n_G1  = G1;
				n_G2  = G2;
				n_G3  = (cloclwise)? G3 : G4;
				n_G4  = (cloclwise)? G4 : G3;
				n_G5  = G5;
				n_G6  = G6;
			end
		`state_change2_2:
			begin
				n_Obj = Obj;
				n_G1  = G1;
				n_G2  = G2;
				n_G3  = G3;
				n_G4  = G4;
				n_G5  = (cloclwise)? G5 : G6;
				n_G6  = (cloclwise)? G6 : G5;
			end		
		`state_check1, `state_check2, `state_check3, `state_check4, `state_check5, `state_check6:
			begin
				n_G2 = G2;
				n_G3 = G3;
				n_G4 = G4;
				n_G5 = G5;
				n_G6 = G6;
			end	
		default:
			begin
				n_G2 = 20'dx;
				n_G3 = 20'dx;
				n_G4 = 20'dx;
				n_G5 = 20'dx;
				n_G6 = 20'dx;
			end		
	endcase


///////////////////////////////////////////////////////////
//				MUX
///////////////////////////////////////////////////////////
always @ (*)
	case (cs)
		`state_change1_1:
			begin
				A1 = G2;
				A2 = G3;
				B1 = G1;
				B2 = G1;
			end
		`state_change1_2:
			begin
				A1 = G4;
				A2 = G5;
				B1 = G1;
				B2 = G1;
			end
		`state_change2_1:
			begin
				A1 = G3;
				A2 = G4;
				B1 = G1;
				B2 = G1;
			end
		`state_change2_2:
			begin
				A1 = G5;
				A2 = G6;
				B1 = G1;
				B2 = G1;
			end
		
		`state_check1:
			begin
				A1 = G1;
				A2 = G2;
				B1 = Obj;
				B2 = G1;
			end
		`state_check2:
			begin
				A1 = G2;
				A2 = G3;
				B1 = Obj;
				B2 = G2;
			end
		`state_check3:
			begin
				A1 = G3;
				A2 = G4;
				B1 = Obj;
				B2 = G3;
			end		
		`state_check4:
			begin
				A1 = G4;
				A2 = G5;
				B1 = Obj;
				B2 = G4;
			end
		`state_check5:
			begin
				A1 = G5;
				A2 = G6;
				B1 = Obj;
				B2 = G5;
			end
		`state_check6:
			begin
				A1 = G6;
				A2 = G1;
				B1 = Obj;
				B2 = G6;
			end
		default:
			begin
				A1 = 20'dx;
				A2 = 20'dx;
				B1 = 20'dx;
				B2 = 20'dx;
			end	
	endcase


///////////////////////////////////////////////////////////
//				module
///////////////////////////////////////////////////////////
sub s1 (A1, B1, S1);
sub s2 (A2, B2, S2);

cross_product c1 (S1[21:11], S1[10:0], S2[21:11], S2[10:0], cloclwise);


///////////////////////////////////////////////////////////
//				CNT
///////////////////////////////////////////////////////////
always @ (posedge clk)
	is_inside <= cloclwise;

assign valid_1 = (cs == `state_wait);

always @ (posedge clk)
	valid_2 <= ~valid_1;

assign valid = valid_1 & valid_2;

endmodule
