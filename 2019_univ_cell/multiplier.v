module multiplier (A, B, m);
input	[19:0]	A, B;
output	[39:0]	m;
wire	[39:0]	tmp;

wire	[19:0]	tmp_A, tmp_B;
reg		[39:0]	m;


assign	tmp_A 	= (A[19] == 1'b1)? ~A + 1 : A;
assign  tmp_B 	= (B[19] == 1'b1)? ~B + 1 : B;

assign	tmp		= tmp_A * tmp_B;


always @ (*)
	case ({A[19], B[19]})
		2'b00: m = tmp;
		2'b01: m = ~tmp + 1;
		2'b10: m = ~tmp + 1;
		2'b11: m = tmp;
	endcase

endmodule