
`timescale 1ns/10ps

module  CONV(
		clk,
		reset,
		busy,	
		ready,	
			
		iaddr,
		idata,	
	
		cwr,
		caddr_wr,
		cdata_wr,
	
		crd,
		caddr_rd,
		cdata_rd,
	
		csel
	);
input			clk;
input			reset;
output			busy;	
input			ready;	
output	[11:0]	iaddr;
input	[19:0]	idata;	
output	 		cwr;
output	[11:0]	caddr_wr;
output	[19:0]	cdata_wr;
output	 		crd;
output	[11:0]	caddr_rd;
input	[19:0]	cdata_rd;	
output	[2:0]	csel;

reg		[11:0]	iaddr, n_iaddr, caddr_wr, n_caddr_wr, caddr_rd, n_caddr_rd;
reg		[19:0]	cdata_wr, n_cdata_wr;
reg				busy, n_busy, cwr, n_cwr, crd, n_crd;
reg		[2:0]	csel, n_csel;

reg		[2:0]	cs, ns;
reg		[6:0]	row, column, n_row, n_column, row_s, column_s;
reg		[6:0]	op		[0:1];//0...row 1...column
reg		[6:0]	n_op	[0:1];
reg		[3:0]	cnt, n_cnt, ptr, n_ptr;
reg		[19:0]	pixel0, n_pixel0, pixel1, n_pixel1;
reg		[19:0]	image	[0:8];
reg		[19:0]	n_image	[0:8];
reg		[19:0]	kernel0	[0:9];
reg		[19:0]	kernel1	[0:9];

reg		[39:0]	product0, product1, n_product0, n_product1;
wire	[39:0]	tmp1, tmp2;

integer			i;


parameter	IDLE = 0,
			READ = 1,
			CALC = 2,
			SAVE = 3,
			RELU = 4,
			WRTE = 5,
			FLAT = 6,
			DONE = 7;

always @ (posedge clk or posedge reset)
	if (reset) begin
		cs <= IDLE;
		iaddr <= 12'd0;
		busy <= 0;
		cwr <= 0;
		cdata_wr <= 20'd0;
		caddr_wr <= 12'b1111_1111_1111;
		csel <= 3'd0;
		crd <= 0;
		caddr_rd <= 12'd0;
		//
		row <= 7'd0;
		column <= 7'd0;
		row_s <= 7'd0;
		column_s <= 7'd0;
		op[0] <= 7'd0;
		op[1] <= 7'd0;
		cnt <= 4'd0;
		//for (i=0; i<9; i=i+1)
		//	image[i] <= 20'd0;
		pixel0 <= 20'd0;
		pixel1 <= 20'd0;
		product0 <= 40'd0;
		product1 <= 40'd0;
	end
	else begin
		cs <= ns;
		iaddr <= n_iaddr;
		busy <= n_busy;
		cwr <= n_cwr;
		cdata_wr <= n_cdata_wr;
		caddr_wr <= n_caddr_wr;
		csel <= n_csel;
		crd <= n_crd;
		caddr_rd <= n_caddr_rd;
		//
		row <= n_row;
		column <= n_column;
		row_s <= row;
		column_s <= column;
		op[0] <= n_op[0];
		op[1] <= n_op[1];
		cnt <= n_cnt;
		//for (i=0; i<9; i=i+1)
		//	image[i] <= n_image[i];
		pixel0 <= n_pixel0;
		pixel1 <= n_pixel1;
		product0 <= n_product0;
		product1 <= n_product1;
	end

always @ (posedge clk or posedge reset)
	if (reset) begin
		for (i=0; i<9; i=i+1)
			image[i] <= 20'd0;
		ptr <= 4'd0;
	end
	else if (cs == READ) begin
		image[ptr] <= ((row_s == 0) || (row_s == 65) || (column_s == 0) || (column_s == 65))? 20'd0 : idata;
		ptr <= cnt;
	end
	else begin
		for (i=0; i<9; i=i+1)
			image[i] <= image[i];
		ptr <= 4'd0;
	end

always @ (*)
	case (cs)
		IDLE: begin
			ns = (ready)? READ : IDLE;
			n_iaddr = 12'd0;
			n_busy = (ready)? 1 : 0;
			n_cwr = 0;
			n_cdata_wr = cdata_wr;
			n_caddr_wr = caddr_wr;
			n_csel = 3'd0;
			n_crd = 0;
			n_caddr_rd = 12'd0;
			//
			n_row = 7'd0;
			n_column = 7'd0;
			n_op[0] = 7'd0;
			n_op[1] = 7'd0;
			n_cnt = 4'd0;
			//for (i=0; i<9; i=i+1)
			//	n_image[i] = 20'd0;
			n_pixel0 = 20'd0;
			n_pixel1 = 20'd0;
			n_product0 = 40'd0;
			n_product1 = 40'd0;
		end
		
		READ: begin
			ns = ((cnt == 9))? CALC : READ;
			n_iaddr = 64 * (row - 1) + (column - 1);
			n_busy = 1;
			n_cwr = 0;
			n_cdata_wr = cdata_wr;
			n_caddr_wr = (cnt == 8)? caddr_wr + 1 : caddr_wr;
			n_csel = 3'd0;
			n_crd = 0;
			n_caddr_rd = 12'd0;
			//
			n_row = (column == (op[1] + 2))? row + 1 : row;
			n_column = (column == (op[1] + 2))? op[1] : column + 1;
			n_op[0] = op[0];
			n_op[1] = op[1];
			n_cnt = (cnt == 9)? 4'd0 : cnt + 1;
			//n_image[ptr] = ((row_s == 0) || (row_s == 65) || (column_s == 0) || (column_s == 65))? 20'd0 : idata;
			n_pixel0 = 20'd0;
			n_pixel1 = 20'd0;
			n_product0 = 40'd0;
			n_product1 = 40'd0;
		end
		
		CALC: begin
			ns = (cnt == 10)? SAVE : CALC;
			n_iaddr = 12'd0;
			n_busy = 1;
			n_cwr = 0;
			n_cdata_wr = cdata_wr;
			n_caddr_wr = caddr_wr;
			n_csel = 3'd0;
			n_crd = 0;
			n_caddr_rd = 12'd0;
			//
			n_row = row;
			n_column = column;
			n_op[0] = (cnt != 10)? op[0] :
					  (op[1] == 63)? op[0] + 1 : op[0]; 
			n_op[1] = (cnt != 10)? op[1] :
					(op[1] == 63)? 7'd0 : op[1] + 1; 
			n_cnt = (cnt == 10)? 4'd0 : cnt + 1;
			//for (i=0; i<9; i=i+1)
			//	n_image[i] = image[i];
			n_pixel0 = (cnt != 10)? pixel0 : 
					   (product0[39])? 20'd0 : product0[35:16] + {19'd0, product0[15]};
			n_pixel1 = (cnt != 10)? pixel1 : 
					   (product1[39])? 20'd0 : product1[35:16] + {19'd0, product1[15]};
			n_product0 = (cnt == 10)? product0 : 
						 (cnt == 9)? product0 + {4'd0, kernel0[9], 16'd0} : product0 + tmp1;
			n_product1 = (cnt == 10)? product1 :
						 (cnt == 9)? product1 + {4'b1111, kernel1[9], 16'd0} : product1 + tmp2;
		end
		
		SAVE: begin
			ns = (cnt != 1)? SAVE : 
				 ({op[0], op[1]} == {7'd64, 7'd0})? RELU : READ;
			n_iaddr = 12'd0;
			n_busy = 1;
			n_cwr = 1;
			n_cdata_wr = (cnt == 0)? pixel0 : pixel1;
			n_caddr_wr = caddr_wr;
			n_csel = (cnt == 0)? 3'b001 : 3'b010;
			n_crd = 0;
			n_caddr_rd = 12'd0;
			//
			n_row = ((cnt == 1) && ({op[0], op[1]} == {7'd64, 7'd0}))? 7'd0 : op[0];
			n_column = ((cnt == 1) && ({op[0], op[1]} == {7'd64, 7'd0}))? 7'd0 : op[1];
			n_op[0] = ((cnt == 1) && ({op[0], op[1]} == {7'd64, 7'd0}))? 7'd0 : op[0];
			n_op[1] = ((cnt == 1) && ({op[0], op[1]} == {7'd64, 7'd0}))? 7'd0 : op[1];
			n_cnt = (cnt == 1)? 4'd0 : cnt + 1;
			//for (i=0; i<9; i=i+1)
			//	n_image[i] = image[i];
			n_pixel0 = pixel0;
			n_pixel1 = pixel1;
			n_product0 = 40'd0;
			n_product1 = 40'd0;
		end
		
		RELU: begin
			ns = (cnt == 4'd8)? WRTE : RELU;
			n_iaddr = 12'd0;
			n_busy = 1;
			n_cwr = 0;
			n_cdata_wr = cdata_wr;
			n_caddr_wr = (cnt == 8)? caddr_wr + 1 : caddr_wr;
			n_csel = (cnt > 3)? 3'b010 : 3'b001;
			n_crd = (cnt == 4'd8)? 0 : 1;
			n_caddr_rd = 64 * row + column;
			//
			n_row = (column != (op[1] + 1))? row : 
					(row == op[0] + 1)? op[0] : op[0] + 1;
			n_column = (column == (op[1] + 1))? op[1] : column + 1;
			n_op[0] = op[0];
			n_op[1] = op[1];
			n_cnt = (cnt == 8)? 4'd0 : cnt + 1;
			//for (i=0; i<9; i=i+1)
			//	n_image[i] = image[i];
			n_pixel0 = 	(cnt > 4)? pixel0 : 
						(cnt == 1)? cdata_rd : 
						(cdata_rd > pixel0)? cdata_rd : pixel0;
			n_pixel1 = 	(cnt < 4)?  pixel1 : 
						(cnt == 5)? cdata_rd : 
						(cdata_rd > pixel1)? cdata_rd : pixel1;
			n_product0 = 40'd0;
			n_product1 = 40'd0;
		end
		
		WRTE: begin
			ns = (cnt != 1)? WRTE :
				 ({op[0], op[1]} == {7'd64, 7'd0})? FLAT : RELU;
			n_iaddr = 12'd0;
			n_busy = 1;
			n_cwr = 1;
			n_cdata_wr = (cnt == 1)? pixel1 : pixel0;
			n_caddr_wr = ((cnt == 1) && ({op[0], op[1]} == {7'd64, 7'd0}))? 12'd1023 : caddr_wr;
			n_csel = (cnt == 1)? 3'b100 : 3'b011;
			n_crd = 0;
			n_caddr_rd = 0;//caddr_rd;
			//
			n_row = n_op[0];//(op[1] == 62)? op[0] + 2 : op[0];
			n_column = n_op[1];//(op[1] == 62)? 7'd0 : op[1];
			n_op[0] = (cnt == 1)? op[0] : 
					  (op[1] == 62)? (op[0] + 2) : op[0];
			n_op[1] = (cnt == 1)? op[1] : 
					  (op[1] == 62)? 7'd0 : op[1] + 2; 
			n_cnt = (cnt == 1)? 4'd0 : cnt + 1;
			//for (i=0; i<9; i=i+1)
			//	n_image[i] = image[i];
			n_pixel0 = 	pixel0;
			n_pixel1 = 	pixel1;
			n_product0 = 40'd0;
			n_product1 = 40'd0;
		end
		
		FLAT: begin
			ns = ((caddr_rd == 1023) && (cnt == 4))? DONE : FLAT;
			n_iaddr = 12'd0;
			n_busy = 1;
			n_cwr = (cnt == 2) || (cnt == 4);
			n_cdata_wr = (cnt == 2)? cdata_rd :
						 (cnt == 4)? cdata_rd : cdata_wr;
			n_caddr_wr = (cnt == 0)? 4095 : 
						 ((cnt == 1) || (cnt == 3))? caddr_wr + 1 : caddr_wr;
			n_csel = (cnt == 1)? 3'b011 :
					 (cnt == 3)? 3'b100 : 3'b101;
			n_crd = (cnt == 1) || (cnt == 3);
			n_caddr_rd = (cnt == 4)? caddr_rd + 1 : caddr_rd;
			//
			n_row = row;
			n_column = column;
			n_op[0] = op[0];
			n_op[1] = op[1];
			n_cnt = (cnt == 0)? 1 : 
					(cnt == 4)? 4'd1 : cnt + 1;
			//for (i=0; i<9; i=i+1)
			//	n_image[i] = image[i];
			n_pixel0 = 	pixel0;
			n_pixel1 = 	pixel1;
			n_product0 = 40'd0;
			n_product1 = 40'd0;
		end
		
		DONE: begin
			ns = IDLE;
			n_iaddr = 12'd0;
			n_busy = 0;
			n_cwr = 0;
			n_cdata_wr = 20'd0;
			n_caddr_wr = 12'd0;
			n_csel = 3'b000;
			n_crd = 0;
			n_caddr_rd = 12'd0;
			//
			n_row = 7'd0;
			n_column = 7'd0;
			n_op[0] = 7'd0;
			n_op[1] = 7'd0;
			n_cnt = 4'd0;
			//for (i=0; i<9; i=i+1)
			//	n_image[i] = 20'd0;
			n_pixel0 = 	20'd0;
			n_pixel1 = 	20'd0;
			n_product0 = 40'd0;
			n_product1 = 40'd0;
		end
		
		
	endcase


multiplier m1 (.A(image[cnt]), .B(kernel0[cnt]), .m(tmp1));
multiplier m2 (.A(image[cnt]), .B(kernel1[cnt]), .m(tmp2));




always @ (posedge clk) begin
	kernel0[0] <= 20'h0A89E;
	kernel0[1] <= 20'h092D5;
	kernel0[2] <= 20'h06D43;
	kernel0[3] <= 20'h01004;
	kernel0[4] <= 20'hF8F71;
	kernel0[5] <= 20'hF6E54;
	kernel0[6] <= 20'hFA6D7;
	kernel0[7] <= 20'hFC834;
	kernel0[8] <= 20'hFAC19;
	kernel0[9] <= 20'h01310;
	
	kernel1[0] <= 20'hFDB55;
	kernel1[1] <= 20'h02992;
	kernel1[2] <= 20'hFC994;
	kernel1[3] <= 20'h050FD;
	kernel1[4] <= 20'h02F20;
	kernel1[5] <= 20'h0202D;
	kernel1[6] <= 20'h03BD7;
	kernel1[7] <= 20'hFD369;
	kernel1[8] <= 20'h05E68;
	kernel1[9] <= 20'hF7295;
end

endmodule

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


