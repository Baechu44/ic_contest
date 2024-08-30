`define		state_load_Obj		3'd0
`define		state_load_G1		3'd1
`define		state_load_G2		3'd2
`define		state_load_G3		3'd3
`define		state_load_G4		3'd4
`define		state_load_G5		3'd5
`define		state_load_G6		3'd6
`define		state_wait			3'd7


module load (clk, reset, Valid, X, Y, Obj, G1, G2, G3, G4, G5, G6, finish_load);
input			clk;
input			reset;
input			Valid;// to restart the load circuit
input	[9:0]	X, Y;

output	[19:0]	Obj;//[19:10]--> for X, [9:0]--> for Y
output	[19:0]	G1, G2, G3, G4, G5, G6;
output			finish_load;

reg		[2:0]	cs, ns;

reg		[19:0]	Obj;
reg		[19:0]	G1, G2, G3, G4, G5, G6;

wire			finish_load_1;
reg				finish_load_2;

//*****************************************************************************  FSM	
always @ (posedge clk or posedge reset)
	if (reset)
		cs <= `state_load_Obj;
	else
		cs <= ns;

always @ (*)
	case (cs)
		`state_load_Obj:	ns = `state_load_G1;
		`state_load_G1:		ns = `state_load_G2;
		`state_load_G2:		ns = `state_load_G3;
		`state_load_G3:		ns = `state_load_G4;
		`state_load_G4:		ns = `state_load_G5;
		`state_load_G5:		ns = `state_load_G6;
		`state_load_G6:		ns = `state_wait;
		`state_wait:		ns = (Valid)? 	`state_load_Obj : `state_wait;
		default:			ns = 3'dx;
	endcase
//*****************************************************************************  FSM	



//*****************************************************************************  DFF
always @ (posedge clk) begin
	Obj <= (cs == `state_load_Obj)? 	{X, Y} : Obj;
	G1  <= (cs == `state_load_G1)? 		{X, Y} : G1;
	G2  <= (cs == `state_load_G2)? 		{X, Y} : G2;
	G3  <= (cs == `state_load_G3)? 		{X, Y} : G3;
	G4  <= (cs == `state_load_G4)? 		{X, Y} : G4;
	G5  <= (cs == `state_load_G5)? 		{X, Y} : G5;
	G6	<= (cs == `state_load_G6)? 		{X, Y} : G6;
end
//*****************************************************************************  DFF

assign finish_load_1 = (cs == `state_wait);

always @ (posedge clk)
	finish_load_2 <= ~finish_load_1;
	
assign finish_load = finish_load_1 & finish_load_2;

endmodule