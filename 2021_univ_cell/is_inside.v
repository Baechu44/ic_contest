//`include 	"./cross_product.v"
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

reg		[10:0]	AX, AY, BX, BY, n_AX, n_AY, n_BX, n_BY;

reg				A, B, C, D, E, F;

wire			valid_1;
reg				valid_2, valid;


//*******************************************************************************  FSM
always @ (posedge clk or posedge reset)
	if (reset)
		cs <= `state_wait;
	else
		cs <= ns;

always @ (*)
	case (cs)
		`state_wait:	ns = (finish_sort)? `state_check1 : `state_wait;
		`state_check1: 	ns = `state_check2;
		`state_check2:	ns = `state_check3;
		`state_check3:	ns = `state_check4;
		`state_check4:	ns = `state_check5;
		`state_check5:	ns = `state_check6;
		`state_check6:	ns = `state_wait;
		default:		ns = 3'dx;
	endcase
//*******************************************************************************  FSM


cross_product c1 (AX, AY, BX, BY, cloclwise);


//*******************************************************************************  cross_product input
always @ (posedge clk)
	begin
		AX <= n_AX;
		AY <= n_AY;
		BX <= n_BX;
		BY <= n_BY;
	end

always @ (*)
	case (cs)
		`state_check1:
			begin
				n_AX = {1'b0, new_G1[19:10]} - {1'b0, Obj[19:10]};
				n_AY = {1'b0, new_G1[9:0]}   - {1'b0, Obj[9:0]};
				n_BX = {1'b0, new_G2[19:10]} - {1'b0, new_G1[19:10]};
				n_BY = {1'b0, new_G2[9:0]}   - {1'b0, new_G1[9:0]};
			end
		`state_check2:
			begin
				n_AX = {1'b0, new_G2[19:10]} - {1'b0, Obj[19:10]};
				n_AY = {1'b0, new_G2[9:0]}   - {1'b0, Obj[9:0]};
				n_BX = {1'b0, new_G3[19:10]} - {1'b0, new_G2[19:10]};
				n_BY = {1'b0, new_G3[9:0]}   - {1'b0, new_G2[9:0]};
			end
		`state_check3:
			begin
				n_AX = {1'b0, new_G3[19:10]} - {1'b0, Obj[19:10]};
				n_AY = {1'b0, new_G3[9:0]}   - {1'b0, Obj[9:0]};
				n_BX = {1'b0, new_G4[19:10]} - {1'b0, new_G3[19:10]};
				n_BY = {1'b0, new_G4[9:0]}   - {1'b0, new_G3[9:0]};
			end		
		`state_check4:
			begin
				n_AX = {1'b0, new_G4[19:10]} - {1'b0, Obj[19:10]};
				n_AY = {1'b0, new_G4[9:0]}   - {1'b0, Obj[9:0]};
				n_BX = {1'b0, new_G5[19:10]} - {1'b0, new_G4[19:10]};
				n_BY = {1'b0, new_G5[9:0]}   - {1'b0, new_G4[9:0]};
			end	
		`state_check5:
			begin
				n_AX = {1'b0, new_G5[19:10]} - {1'b0, Obj[19:10]};
				n_AY = {1'b0, new_G5[9:0]}   - {1'b0, Obj[9:0]};
				n_BX = {1'b0, new_G6[19:10]} - {1'b0, new_G5[19:10]};
				n_BY = {1'b0, new_G6[9:0]}   - {1'b0, new_G5[9:0]};
			end	
		`state_check6:
			begin
				n_AX = {1'b0, new_G6[19:10]} - {1'b0, Obj[19:10]};
				n_AY = {1'b0, new_G6[9:0]}   - {1'b0, Obj[9:0]};
				n_BX = {1'b0, new_G1[19:10]} - {1'b0, new_G6[19:10]};
				n_BY = {1'b0, new_G1[9:0]}   - {1'b0, new_G6[9:0]};
			end	
		default:
			begin
				n_AX = 11'dx;
				n_AY = 11'dx;
				n_BX = 11'dx;
				n_BY = 11'dx;
			end	
	endcase
//*******************************************************************************  cross_product input


//*******************************************************************************  cross_product output
always @ (posedge clk or posedge reset)
	if (reset)
	begin
		A <= 1'b0;
		B <= 1'b0;
		C <= 1'b0;
		D <= 1'b0;
		E <= 1'b0;
		F <= 1'b0;
	end
	else
	begin
		A <= (cs == `state_check2)? cloclwise : A;
		B <= (cs == `state_check3)? cloclwise : B;
		C <= (cs == `state_check4)? cloclwise : C;
		D <= (cs == `state_check5)? cloclwise : D;
		E <= (cs == `state_check6)? cloclwise : E;
		F <= (cs == `state_wait)?   cloclwise : F;
	end


assign is_inside = A & B & C & D & E & F;

assign valid_1 = (cs == `state_wait);

always @ (posedge clk) begin
	valid_2 <= ~valid_1;
	valid = valid_1 & valid_2;
end

endmodule
