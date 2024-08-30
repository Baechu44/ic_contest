`include 	"./convolution.v"

//counter
`define		state_c_wait		4'd0
`define		state_c_1			4'd1
`define		state_c_2			4'd2
`define		state_c_3			4'd3
`define		state_c_4			4'd4
`define		state_c_5			4'd5
`define		state_c_6			4'd6
`define		state_c_7			4'd7
`define		state_c_8			4'd8
`define		state_c_9			4'd9
`define		state_c_finish1		4'd10
`define		state_c_finish2		4'd11

//max
`define		state_m_initial		3'd0
`define		state_m_wait		3'd1
`define		state_m_1			3'd2
`define		state_m_2			3'd3
`define		state_m_3			3'd4
`define		state_m_4			3'd5
`define		state_m_finish1		3'd6
`define		state_m_finish2		3'd7

`timescale 1ns/10ps

module  CONV(
	input				clk,
	input				reset,
	output	reg			busy,	
	input				ready,	
			
	output		[11:0]	iaddr,
	input		[19:0]	idata,	
	
	output	reg 		cwr,
	output	reg	[11:0] 	caddr_wr,
	output	reg	[19:0]	cdata_wr,
	
	output	reg 		crd,
	output		[11:0] 	caddr_rd,
	input		[19:0] 	cdata_rd,
	
	output	reg	[2:0] 	csel
	);

reg				[3:0]	cs_c, ns_c;
wire					finish_c, start_c, finish_l0, finish_l1, finish_l1_2;
reg				[6:0]	X, Y, n_X, n_Y;
reg				[179:0]	pixel;
reg						finish_l1_1, n_busy;
reg				[2:0]	cs_m, ns_m;
reg				[5:0]	X_m, Y_m, n_X_m, n_Y_m;
reg				[19:0]	max_value;
wire			[19:0]	tmp, result;
wire			[11:0]	tmpy;

/////////////////////////////////////////////
//         counterXY...layer0
/////////////////////////////////////////////
always @ (posedge clk or posedge reset)
	if (reset)
		cs_c <= `state_c_wait;
	else if (ready)
		cs_c <= `state_c_1;
	else
		cs_c <= ns_c;

always @ (*)
	case (cs_c)
		`state_c_wait:		ns_c = ({X, Y} == {7'd65, 7'd65})? `state_c_wait : (finish_c)? `state_c_1 : `state_c_wait;
		`state_c_1:			ns_c = `state_c_2;
		`state_c_2:			ns_c = `state_c_3;
		`state_c_3:			ns_c = `state_c_4;
		`state_c_4:			ns_c = `state_c_5;
		`state_c_5:			ns_c = `state_c_6;
		`state_c_6:			ns_c = `state_c_7;
		`state_c_7:			ns_c = `state_c_8;
		`state_c_8:			ns_c = `state_c_9;
		`state_c_9:			ns_c = `state_c_finish1;
		`state_c_finish1:	ns_c = `state_c_finish2;
		`state_c_finish2:	ns_c = `state_c_wait;
		default:			ns_c = 4'dx;
	endcase
	

always @ (posedge clk)
	begin
		X <= n_X;
		Y <= n_Y;
	end
		
always @ (*)
	case (cs_c)
		`state_c_wait:		
			begin
				n_X = (ready)? 7'd0 : X;
				n_Y = (ready)? 7'd0 : Y;
			end
		`state_c_1:
			begin
				n_X = X;
				n_Y = Y;
			end
		`state_c_2:
			begin
				n_X = X + 7'd1;
				n_Y = Y;
			end
		`state_c_3:
			begin
				n_X = X + 7'd1;
				n_Y = Y;
			end
		`state_c_4:
			begin
				n_X = X - 7'd2;
				n_Y = Y + 7'd1;
			end
		`state_c_5:
			begin
				n_X = X + 7'd1;
				n_Y = Y;
			end
		`state_c_6:
			begin
				n_X = X + 7'd1;
				n_Y = Y;
			end
		`state_c_7:
			begin
				n_X = X - 7'd2;
				n_Y = Y + 7'd1;
			end
		`state_c_8:
			begin
				n_X = X + 7'd1;
				n_Y = Y;
			end
		`state_c_9:
			begin
				n_X = X + 7'd1;
				n_Y = Y;
			end
		`state_c_finish1:
			begin
				n_X = X;
				n_Y = Y;
			end
		`state_c_finish2:
			begin
				n_X = ({X, Y} == {7'd65, 7'd65})? X : (X == 7'd65)? 7'd0 : X - 7'd1;
				n_Y = ({X, Y} == {7'd65, 7'd65})? Y : (X == 7'd65)? Y - 7'd1 : Y - 7'd2;
			end
		default:
			begin
				n_X = 7'dx;
				n_Y = 7'dx;
			end
	endcase

assign  tmpy = {5'd0, Y} - 12'd1;

assign	iaddr = {5'd0, X} - 12'd1 + {tmpy[5:0], 6'd0};

assign  tmp = ((X == 7'd0)||(X == 7'd65)||(Y == 7'd0)||(Y == 7'd65))? 20'd0 : idata; 

always @ (posedge clk)
	case (cs_c)	
		`state_c_2:			pixel <= {tmp, pixel[159:0]};	
		`state_c_3:			pixel <= {pixel[179:160], tmp, pixel[139:0]};	
		`state_c_4:			pixel <= {pixel[179:140], tmp, pixel[119:0]};	
		`state_c_5:			pixel <= {pixel[179:120], tmp, pixel[99:0]};	
		`state_c_6:			pixel <= {pixel[179:100], tmp, pixel[79:0]};	
		`state_c_7:			pixel <= {pixel[179:80], tmp, pixel[59:0]};
		`state_c_8:			pixel <= {pixel[179:60], tmp, pixel[39:0]};
		`state_c_9:			pixel <= {pixel[179:40], tmp, pixel[19:0]};
		`state_c_finish1:	pixel <= {pixel[179:20], tmp};
		default:			pixel <= pixel;
	endcase

assign start_c = (cs_c == `state_c_3);

convolution c1 (clk, reset, start_c, pixel, result, finish_c);


/////////////////////////////////////////////
//         CNT
/////////////////////////////////////////////
always @ (posedge clk)
	if (finish_c)
		begin
			cwr 	 <= 1'b1;
			caddr_wr <= caddr_wr;
			cdata_wr <= result; 
			csel	 <= 3'd1;
		end
	else if (cs_m == `state_m_finish2)
		begin
			cwr 	 <= 1'b1;
			caddr_wr <= ({X_m, Y_m} == 12'd0)? 1023 : (X_m >> 1) + Y_m * 16 - 1;
			cdata_wr <= max_value; 
			csel	 <= 3'd3;
		end
	else
		begin
			cwr 	 <= 1'b0;
			caddr_wr <= (cs_c == `state_c_2)? X + Y*64 : caddr_wr;
			cdata_wr <= 20'dx; 
			csel	 <= 3'd1;
		end 
	
assign finish_l0 = ((X == 7'd65)&&(Y == 7'd65));



/////////////////////////////////////////////
//         max...layer1
/////////////////////////////////////////////
always @ (posedge clk or posedge reset)
	if (reset)
		cs_m <= `state_m_initial;
	else
		cs_m <= ns_m;

always @ (*)
	case (cs_m)
		`state_m_initial:	ns_m = (finish_l0 & finish_c)? `state_m_1 : `state_m_initial;
		`state_m_wait:		ns_m = ({X_m, Y_m} == {6'd0, 6'd0})? `state_m_initial : `state_m_1;
		`state_m_1:			ns_m = `state_m_2;
		`state_m_2:			ns_m = `state_m_3;
		`state_m_3:			ns_m = `state_m_4;
		`state_m_4:			ns_m = `state_m_finish1;

		`state_m_finish1:	ns_m = `state_m_finish2;
		`state_m_finish2:	ns_m = `state_m_wait;
		default:			ns_m = 3'dx;
	endcase

always @ (posedge clk)
	begin
		X_m <= n_X_m;
		Y_m <= n_Y_m;
	end
		
always @ (*)
	case (cs_m)
		`state_m_initial:
			begin
				n_X_m = 6'd0;
				n_Y_m = 6'd0;
				crd	  = 1'b0;
			end
		`state_m_wait:		
			begin
				n_X_m = X_m;
				n_Y_m = Y_m;
				crd	  = 1'b0;
			end
		`state_m_1:
			begin
				n_X_m = X_m;
				n_Y_m = Y_m;
				crd	  = 1'b0;
			end
		`state_m_2:
			begin
				n_X_m = X_m + 6'd1;
				n_Y_m = Y_m;
				crd	  = 1'b1;
			end
		`state_m_3:
			begin
				n_X_m = X_m - 6'd1;
				n_Y_m = Y_m + 6'd1;
				crd	  = 1'b1;
			end
		`state_m_4:
			begin
				n_X_m = X_m + 6'd1;
				n_Y_m = Y_m;
				crd	  = 1'b1;
			end
		
		`state_m_finish1:
			begin
				n_X_m = ({X_m, Y_m} == {6'd63, 6'd63})? 6'd0 : (X_m == 6'd63)? 6'd0 : X_m + 6'd1;
				n_Y_m = ({X_m, Y_m} == {6'd63, 6'd63})? 6'd0 : (X_m == 6'd63)? Y_m + 6'd1 : Y_m - 6'd1;
				crd	  = 1'b1;
			end
		`state_m_finish2:
			begin
				n_X_m = X_m;
				n_Y_m = Y_m;
				crd	  = 1'b0;
			end
		default:
			begin
				n_X_m = 6'dx;
				n_Y_m = 6'dx;
				crd	  = 1'bx;
			end
	endcase

assign	caddr_rd = {6'd0, X_m} + {Y_m, 6'd0};

always @ (posedge clk)
	case (cs_m)	
		`state_m_2:			max_value <= cdata_rd;
		`state_m_3:			max_value <= (max_value > cdata_rd)? max_value : cdata_rd;
		`state_m_4:			max_value <= (max_value > cdata_rd)? max_value : cdata_rd;
		`state_m_finish1:	max_value <= (max_value > cdata_rd)? max_value : cdata_rd;
		default:			max_value <= max_value;
	endcase

assign finish_l1 = (cs_m == `state_m_initial);

always @ (posedge clk)
	finish_l1_1 <= ~finish_l1;

assign finish_l1_2 = finish_l1 & finish_l1_1;

always @ (posedge clk or posedge reset)
	if (reset)
		busy <= 1'b0;
	else
		busy <= n_busy;
		
always @ (*)
	case (busy)
		1'b0:	n_busy = (ready)? 1'b1 : 1'b0;
		1'b1:	n_busy = (finish_l1_2)? 1'b0 : 1'b1;
		default:n_busy = 1'bx;
	endcase
	
endmodule

