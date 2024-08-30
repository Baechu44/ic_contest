module cross_product (AX, AY, BX, BY, cloclwise);
input	[10:0]	AX, AY, BX, BY;
output			cloclwise;//cloclwise = 1...A cross B 指向裡面

wire	[9:0]	new_AX, new_AY, new_BX, new_BY;
wire	[19:0]	m1, m2;

reg				cloclwise;

assign new_AX = (AX[10])? ~AX[9:0] + 10'd1 : AX[9:0];
assign new_BX = (BX[10])? ~BX[9:0] + 10'd1 : BX[9:0];
assign new_AY = (AY[10])? ~AY[9:0] + 10'd1 : AY[9:0];
assign new_BY = (BY[10])? ~BY[9:0] + 10'd1 : BY[9:0];

assign m1 = new_AX * new_BY;
assign m2 = new_BX * new_AY;

always @ (*)
	case ({AX[10] ^ BY[10], AY[10] ^ BX[10]})
		2'b00: cloclwise = (m1 < m2);
		2'b01: cloclwise = 0;
		2'b10: cloclwise = 1;
		2'b11: cloclwise = (m1 > m2);
	endcase


endmodule

///////////////////////////////////////////////////////////////////////////
module multiplier(A, B, m);
input  	[10:0] 	A, B;
output 	[21:0] 	m;

wire	[9:0]	new_A, new_B;
wire	[19:0]	new_m;

assign new_A = (A[10])? ~A[9:0] + 10'd1 : A[9:0];
assign new_B = (B[10])? ~B[9:0] + 10'd1 : B[9:0];

assign new_m = new_A * new_B;

assign m[21] 	= A[10]^B[10];
assign m[20:0]	= (m[21])? ~{1'b0, new_m} + 21'd1 : {1'b0, new_m};

endmodule
///////////////////////////////////////////////////////////////////////////
module sub (A, B, S);
input	[19:0]	A, B;
output	[21:0]	S;

wire	[10:0]	S_X, S_Y;

assign S = {S_X, S_Y};

assign S_X = {1'b0, A[19:10]} - {1'b0, B[19:10]};
assign S_Y = {1'b0, A[9:0]}   - {1'b0, B[9:0]};

endmodule