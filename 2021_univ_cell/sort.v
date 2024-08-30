`include 	"./cross_product.v"
`define		state_wait			3'd0
`define		state_initialize	3'd1
`define		state_change1		3'd2
`define		state_change2		3'd3
`define		state_change3		3'd4
`define		state_change4		3'd5
`define		state_change5		3'd6
`define		state_change6		3'd7

module sort (clk, reset, finish_load, G1, G2, G3, G4, G5, G6, new_G1, new_G2, new_G3, new_G4, new_G5, new_G6, finish_sort);
input			clk;
input			reset;
input			finish_load;
input	[19:0]	G1, G2, G3, G4, G5, G6;	

output	[19:0]	new_G1, new_G2, new_G3, new_G4, new_G5, new_G6;
output			finish_sort;

reg		[21:0]	Vec1, Vec2, Vec3, Vec4, Vec5;//Vec1 = G2 - G1; Vec5 = G6 - G1;
reg		[21:0]	n_Vec1, n_Vec2, n_Vec3, n_Vec4, n_Vec5;

reg		[2:0]	cs, ns;

wire			cloclwise_1, cloclwise_2, cloclwise_3, cloclwise_4;

wire			finish_sort_1;
reg				finish_sort_2;

wire	[10:0]	new_G2_X, new_G2_Y, new_G3_X, new_G3_Y, new_G4_X, new_G4_Y, new_G5_X, new_G5_Y, new_G6_X, new_G6_Y;

wire	[10:0]	n_Vec1_X, n_Vec1_Y, n_Vec2_X, n_Vec2_Y, n_Vec3_X, n_Vec3_Y, n_Vec4_X, n_Vec4_Y, n_Vec5_X, n_Vec5_Y;



//*******************************************************************************  FSM
always @ (posedge clk or posedge reset)
	if (reset)
		cs <= `state_wait;
	else
		cs <= ns;

always @ (*)
	case (cs)
		`state_wait:		ns = (finish_load)? `state_initialize : `state_wait;
		`state_initialize:	ns = `state_change1;
		`state_change1:		ns = `state_change2;
		`state_change2:		ns = `state_change3;
		`state_change3:		ns = `state_change4;
		`state_change4:		ns = `state_change5;
		`state_change5:		ns = `state_change6;
		`state_change6:		ns = `state_wait;
	endcase
//*******************************************************************************  FSM

assign n_Vec1_X = {1'b0, G2[19:10]} - {1'b0, G1[19:10]};
assign n_Vec1_Y = {1'b0, G2[9:0]}   - {1'b0, G1[9:0]};

assign n_Vec2_X = {1'b0, G3[19:10]} - {1'b0, G1[19:10]};
assign n_Vec2_Y = {1'b0, G3[9:0]}   - {1'b0, G1[9:0]};

assign n_Vec3_X = {1'b0, G4[19:10]} - {1'b0, G1[19:10]};
assign n_Vec3_Y = {1'b0, G4[9:0]}   - {1'b0, G1[9:0]};

assign n_Vec4_X = {1'b0, G5[19:10]} - {1'b0, G1[19:10]};
assign n_Vec4_Y = {1'b0, G5[9:0]}   - {1'b0, G1[9:0]};

assign n_Vec5_X = {1'b0, G6[19:10]} - {1'b0, G1[19:10]};
assign n_Vec5_Y = {1'b0, G6[9:0]}   - {1'b0, G1[9:0]};
//*******************************************************************************  DFF
always @ (posedge clk)
	begin
		Vec1 <= n_Vec1;
		Vec2 <= n_Vec2;
		Vec3 <= n_Vec3;
		Vec4 <= n_Vec4;
		Vec5 <= n_Vec5;
	end

always @ (*)
	case (cs)
		`state_initialize:
			begin
				n_Vec1 = {n_Vec1_X, n_Vec1_Y};
				n_Vec2 = {n_Vec2_X, n_Vec2_Y};
				n_Vec3 = {n_Vec3_X, n_Vec3_Y};
				n_Vec4 = {n_Vec4_X, n_Vec4_Y};
				n_Vec5 = {n_Vec5_X, n_Vec5_Y};
			end
		`state_change1:
			begin
				n_Vec1 = (cloclwise_1)? Vec1 : Vec2;
				n_Vec2 = (cloclwise_1)? Vec2 : Vec1;
				n_Vec3 = (cloclwise_2)? Vec3 : Vec4;
				n_Vec4 = (cloclwise_2)? Vec4 : Vec3;
				n_Vec5 = Vec5;
			end
		`state_change2:
			begin
				n_Vec1 = Vec1;
				n_Vec2 = (cloclwise_3)? Vec2 : Vec3;
				n_Vec3 = (cloclwise_3)? Vec3 : Vec2;
				n_Vec4 = (cloclwise_4)? Vec4 : Vec5;
				n_Vec5 = (cloclwise_4)? Vec5 : Vec4;
			end
		`state_change3:
			begin
				n_Vec1 = (cloclwise_1)? Vec1 : Vec2;
				n_Vec2 = (cloclwise_1)? Vec2 : Vec1;
				n_Vec3 = (cloclwise_2)? Vec3 : Vec4;
				n_Vec4 = (cloclwise_2)? Vec4 : Vec3;
				n_Vec5 = Vec5;
			end
		`state_change4:
			begin
				n_Vec1 = Vec1;
				n_Vec2 = (cloclwise_3)? Vec2 : Vec3;
				n_Vec3 = (cloclwise_3)? Vec3 : Vec2;
				n_Vec4 = (cloclwise_4)? Vec4 : Vec5;
				n_Vec5 = (cloclwise_4)? Vec5 : Vec4;
			end
		`state_change5:
			begin
				n_Vec1 = (cloclwise_1)? Vec1 : Vec2;
				n_Vec2 = (cloclwise_1)? Vec2 : Vec1;
				n_Vec3 = (cloclwise_2)? Vec3 : Vec4;
				n_Vec4 = (cloclwise_2)? Vec4 : Vec3;
				n_Vec5 = Vec5;
			end
		`state_change6:
			begin
				n_Vec1 = Vec1;
				n_Vec2 = (cloclwise_3)? Vec2 : Vec3;
				n_Vec3 = (cloclwise_3)? Vec3 : Vec2;
				n_Vec4 = (cloclwise_4)? Vec4 : Vec5;
				n_Vec5 = (cloclwise_4)? Vec5 : Vec4;
			end
		`state_wait:
			begin
				n_Vec1 = Vec1;
				n_Vec2 = Vec2;
				n_Vec3 = Vec3;
				n_Vec4 = Vec4;
				n_Vec5 = Vec5;
			end
		default:
			begin
				n_Vec1 = 22'dx;
				n_Vec2 = 22'dx;
				n_Vec3 = 22'dx;
				n_Vec4 = 22'dx;
				n_Vec5 = 22'dx;
			end
	endcase

cross_product c1 (Vec1[21:11], Vec1[10:0], Vec2[21:11], Vec2[10:0], cloclwise_1);
cross_product c2 (Vec3[21:11], Vec3[10:0], Vec4[21:11], Vec4[10:0], cloclwise_2);

cross_product c3 (Vec2[21:11], Vec2[10:0], Vec3[21:11], Vec3[10:0], cloclwise_3);
cross_product c4 (Vec4[21:11], Vec4[10:0], Vec5[21:11], Vec5[10:0], cloclwise_4);


//*****************************************************************************************  CNT signal
assign finish_sort_1 = (cs == `state_wait);

always @ (posedge clk)
	finish_sort_2 <= ~finish_sort_1;
	
assign finish_sort = finish_sort_1 & finish_sort_2;


//*****************************************************************************************
assign new_G1 	= G1;

assign new_G2 	= {new_G2_X[9:0], new_G2_Y[9:0]};
assign new_G2_X = Vec1[21:11] + {1'b0, G1[19:10]};
assign new_G2_Y = Vec1[10:0]  + {1'b0, G1[9:0]};

assign new_G3 	= {new_G3_X[9:0], new_G3_Y[9:0]};
assign new_G3_X = Vec2[21:11] + {1'b0, G1[19:10]};
assign new_G3_Y = Vec2[10:0]  + {1'b0, G1[9:0]};

assign new_G4 	= {new_G4_X[9:0], new_G4_Y[9:0]};
assign new_G4_X = Vec3[21:11] + {1'b0, G1[19:10]};
assign new_G4_Y = Vec3[10:0]  + {1'b0, G1[9:0]};

assign new_G5 	= {new_G5_X[9:0], new_G5_Y[9:0]};
assign new_G5_X = Vec4[21:11] + {1'b0, G1[19:10]};
assign new_G5_Y = Vec4[10:0]  + {1'b0, G1[9:0]};

assign new_G6 	= {new_G6_X[9:0], new_G6_Y[9:0]};
assign new_G6_X = Vec5[21:11] + {1'b0, G1[19:10]};
assign new_G6_Y = Vec5[10:0]  + {1'b0, G1[9:0]};


endmodule
