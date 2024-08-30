module huffman(clk, reset, gray_valid, gray_data, CNT_valid, CNT1, CNT2, CNT3, CNT4, CNT5, CNT6,
    code_valid, HC1, HC2, HC3, HC4, HC5, HC6, M1, M2, M3, M4, M5, M6);

input 			clk;
input 			reset;
input 			gray_valid;
input 	[7:0] 	gray_data;
output 			CNT_valid;
output 	[7:0] 	CNT1, CNT2, CNT3, CNT4, CNT5, CNT6;
output 			code_valid;
output 	[7:0] 	HC1, HC2, HC3, HC4, HC5, HC6;
output 	[7:0] 	M1, M2, M3, M4, M5, M6;


reg		[2:0]	cs, ns;

reg		[6:0]	A	[1:6];
reg		[5:0]	S	[1:6];

integer			i;

wire 	[7:0] 	CNT1, CNT2, CNT3, CNT4, CNT5, CNT6;

reg				finish_count_1, finish_count_2, code_valid;
wire			CNT_valid, finish_sort, finish_combine;

reg		[1:0]	count;

wire	[5:0]	check_M, check_HC_0, check_HC_1;

reg 	[7:0] 	HC1, HC2, HC3, HC4, HC5, HC6, nHC1, nHC2, nHC3, nHC4, nHC5, nHC6;
reg 	[7:0] 	M1, M2, M3, M4, M5, M6;


///////////////////////////////////////
//				FSM
///////////////////////////////////////

parameter	state_count		= 3'd0,
			state_sort_odd	= 3'd1,
			state_sort_even = 3'd2,
			state_combine	= 3'd3,
			state_inverse	= 3'd4;


always @ (posedge clk or posedge reset)
	if (reset)
		cs <= state_count;
	else
		cs <= ns;


always @ (*)
	case (cs)
		state_count		:	ns = (CNT_valid)     ? 	state_sort_odd	: 	state_count;
		state_sort_odd	:	ns = state_sort_even;
		state_sort_even	:	ns = (finish_sort)   ? 	state_combine 	: 	state_sort_odd;
		state_combine	:	ns = (finish_combine)?	state_inverse	:	state_sort_odd;
		state_inverse	:	ns = state_count;
		
		default			:	ns = 3'dx;
	endcase


///////////////////////////////////////
//				A circuit
///////////////////////////////////////

always @ (posedge clk or posedge reset)
	if (reset)
		for (i=1; i<=6; i=i+1)
			A[i] <= 7'd0;

	else if (gray_valid)
		A[gray_data] <= A[gray_data] + 7'd1;
	
	else if (cs == state_sort_odd)
		begin
			A[1] <= (A[1] >= A[2])? A[1] : A[2];
			A[2] <= (A[1] >= A[2])? A[2] : A[1];
			
			A[3] <= (A[3] >= A[4])? A[3] : A[4];
			A[4] <= (A[3] >= A[4])? A[4] : A[3];
			
			A[5] <= (A[5] >= A[6])? A[5] : A[6];
			A[6] <= (A[5] >= A[6])? A[6] : A[5];
		end
		
	else if (cs == state_sort_even)
		begin
			A[1] <= A[1];
			
			A[2] <= (A[2] >= A[3])? A[2] : A[3];
			A[3] <= (A[2] >= A[3])? A[3] : A[2];
			
			A[4] <= (A[4] >= A[5])? A[4] : A[5];
			A[5] <= (A[4] >= A[5])? A[5] : A[4];
			
			A[6] <= A[6];
		end
	
	else if (cs == state_combine)//
		begin
			A[1] <= 7'd127;
			A[2] <= A[1];
			A[3] <= A[2];
			A[4] <= A[3];
			A[5] <= A[4];
			A[6] <= A[5] + A[6];
		end
	
	else
		for (i=1; i<=6; i=i+1)
			A[i] <= A[i];


///////////////////////////////////////
//				Symbol circuit
///////////////////////////////////////

always @ (posedge clk or posedge reset)
	if (reset)
		begin
			S[1] <= 6'b00_0001;
			S[2] <= 6'b00_0010;
			S[3] <= 6'b00_0100;
			S[4] <= 6'b00_1000;
			S[5] <= 6'b01_0000;
			S[6] <= 6'b10_0000;
		end
	
	else if (cs == state_sort_odd)
		begin
			S[1] <= (A[1] >= A[2])? S[1] : S[2];
			S[2] <= (A[1] >= A[2])? S[2] : S[1];
			
			S[3] <= (A[3] >= A[4])? S[3] : S[4];
			S[4] <= (A[3] >= A[4])? S[4] : S[3];
			
			S[5] <= (A[5] >= A[6])? S[5] : S[6];
			S[6] <= (A[5] >= A[6])? S[6] : S[5];
		end
	
	else if (cs == state_sort_even)
		begin
			S[1] <= S[1];
			
			S[2] <= (A[2] >= A[3])? S[2] : S[3];
			S[3] <= (A[2] >= A[3])? S[3] : S[2];
			
			S[4] <= (A[4] >= A[5])? S[4] : S[5];
			S[5] <= (A[4] >= A[5])? S[5] : S[4];
			
			S[6] <= S[6];
		end

	else if (cs == state_combine)
		begin
			S[1] <= 6'd0;
			S[2] <= S[1];
			S[3] <= S[2];
			S[4] <= S[3];
			S[5] <= S[4];
			S[6] <= S[5] | S[6];
		end
	
	else
		for (i=1; i<=6; i=i+1)
			S[i] <= S[i];


///////////////////////////////////////
//				state_count
///////////////////////////////////////

assign CNT1 = {1'b0, A[1]};
assign CNT2 = {1'b0, A[2]};
assign CNT3 = {1'b0, A[3]};
assign CNT4 = {1'b0, A[4]};
assign CNT5 = {1'b0, A[5]};
assign CNT6 = {1'b0, A[6]};


//CNT_valid

always @ (posedge clk)
	begin
		finish_count_1 <= gray_valid;
		finish_count_2 <= ~finish_count_1;
	end

assign CNT_valid = ~(gray_valid | finish_count_2);


///////////////////////////////////////
//				state_sort
///////////////////////////////////////

always @ (posedge clk)
	if ( (cs == state_count) || (cs == state_combine) )
		count <= 2'd0;
	else if (cs == state_sort_odd)
		count <= count + 2'd1;
	else
		count <= count;

assign finish_sort = (count == 2'd3);


///////////////////////////////////////
//				state_combine, state_inverse
///////////////////////////////////////

assign finish_combine = ( (A[5] + A[6]) == 7'd100 );

always @ (posedge clk)
	if (cs == state_inverse)
		code_valid <= 1'b1;
	else
		code_valid <= 1'b0;

//M
assign check_M = S[5] | S[6];

always @ (posedge clk or posedge reset)
	if (reset)
		begin
			M1 <= 8'd0;
			M2 <= 8'd0;
			M3 <= 8'd0;
			M4 <= 8'd0;
			M5 <= 8'd0;
			M6 <= 8'd0;
		end
	
	else if (cs == state_combine)
		begin
			M1 <= (check_M[0] == 1'b1)? 	{M1[6:0], 1'b1} : M1;
			M2 <= (check_M[1] == 1'b1)? 	{M2[6:0], 1'b1} : M2;
			M3 <= (check_M[2] == 1'b1)? 	{M3[6:0], 1'b1} : M3;
			M4 <= (check_M[3] == 1'b1)? 	{M4[6:0], 1'b1} : M4;
			M5 <= (check_M[4] == 1'b1)? 	{M5[6:0], 1'b1} : M5;
			M6 <= (check_M[5] == 1'b1)? 	{M6[6:0], 1'b1} : M6;
		end		

	else
		begin
			M1 <= M1;
			M2 <= M2;
			M3 <= M3;
			M4 <= M4;
			M5 <= M5;
			M6 <= M6;
		end


//HC
assign check_HC_0 = S[5];
assign check_HC_1 = S[6];

always @ (posedge clk or posedge reset)
	if (reset)
		begin
			HC1 <= 8'd0;
			HC2 <= 8'd0;
			HC3 <= 8'd0;
			HC4 <= 8'd0;
			HC5 <= 8'd0;
			HC6 <= 8'd0;
		end
	
	else if (cs == state_combine)
		begin
			HC1 <= (check_HC_0[0] == 1'b1)? 	{1'b0, HC1[7:1]} :
				   (check_HC_1[0] == 1'b1)?		{1'b1, HC1[7:1]} : HC1;
			
			HC2 <= (check_HC_0[1] == 1'b1)? 	{1'b0, HC2[7:1]} :
				   (check_HC_1[1] == 1'b1)?		{1'b1, HC2[7:1]} : HC2;
				  
			HC3 <= (check_HC_0[2] == 1'b1)? 	{1'b0, HC3[7:1]} :
				   (check_HC_1[2] == 1'b1)?		{1'b1, HC3[7:1]} : HC3;
			
			HC4 <= (check_HC_0[3] == 1'b1)? 	{1'b0, HC4[7:1]} :
				   (check_HC_1[3] == 1'b1)?		{1'b1, HC4[7:1]} : HC4;
			
			HC5 <= (check_HC_0[4] == 1'b1)? 	{1'b0, HC5[7:1]} :
				   (check_HC_1[4] == 1'b1)?		{1'b1, HC5[7:1]} : HC5;
			
			HC6 <= (check_HC_0[5] == 1'b1)? 	{1'b0, HC6[7:1]} :
				   (check_HC_1[5] == 1'b1)?		{1'b1, HC6[7:1]} : HC6;	  
		end		

	else if (cs == state_inverse)
		begin
			HC1 <= nHC1;
			HC2 <= nHC2;
			HC3 <= nHC3;
			HC4 <= nHC4;
			HC5 <= nHC5;
			HC6 <= nHC6;
		end

	else
		begin
			HC1 <= HC1;
			HC2 <= HC2;
			HC3 <= HC3;
			HC4 <= HC4;
			HC5 <= HC5;
			HC6 <= HC6;
		end


//nHC1		
always @ (*)
	case (M1)
		8'b0000_0000:	nHC1 = 8'd0;
		8'b0000_0001:	nHC1 = {7'd0, HC1[7]};
		8'b0000_0011:	nHC1 = {6'd0, HC1[7:6]};
		8'b0000_0111:	nHC1 = {5'd0, HC1[7:5]};
		8'b0000_1111:	nHC1 = {4'd0, HC1[7:4]};
		8'b0001_1111:	nHC1 = {3'd0, HC1[7:3]};
		/*
		8'b0011_1111:	nHC1 = {2'd0, HC1[7:2]};
		8'b0111_1111:	nHC1 = {1'd0, HC1[7:1]};
		8'b1111_1111:	nHC1 = HC1;
		*/
		default		:	nHC1 = 8'dx;
	endcase

//nHC2		
always @ (*)
	case (M2)
		8'b0000_0000:	nHC2 = 8'd0;
		8'b0000_0001:	nHC2 = {7'd0, HC2[7]};
		8'b0000_0011:	nHC2 = {6'd0, HC2[7:6]};
		8'b0000_0111:	nHC2 = {5'd0, HC2[7:5]};
		8'b0000_1111:	nHC2 = {4'd0, HC2[7:4]};
		8'b0001_1111:	nHC2 = {3'd0, HC2[7:3]};
		/*
		8'b0011_1111:	nHC2 = {2'd0, HC2[7:2]};
		8'b0111_1111:	nHC2 = {1'd0, HC2[7:1]};
		8'b1111_1111:	nHC2 = HC2;
		*/
		default		:	nHC2 = 8'dx;
	endcase

//nHC3	
always @ (*)
	case (M3)
		8'b0000_0000:	nHC3 = 8'd0;
		8'b0000_0001:	nHC3 = {7'd0, HC3[7]};
		8'b0000_0011:	nHC3 = {6'd0, HC3[7:6]};
		8'b0000_0111:	nHC3 = {5'd0, HC3[7:5]};
		8'b0000_1111:	nHC3 = {4'd0, HC3[7:4]};
		8'b0001_1111:	nHC3 = {3'd0, HC3[7:3]};
		/*
		8'b0011_1111:	nHC3 = {2'd0, HC3[7:2]};
		8'b0111_1111:	nHC3 = {1'd0, HC3[7:1]};
		8'b1111_1111:	nHC3 = HC3;
		*/
		default		:	nHC3 = 8'dx;
	endcase

//nHC4		
always @ (*)
	case (M4)
		8'b0000_0000:	nHC4 = 8'd0;
		8'b0000_0001:	nHC4 = {7'd0, HC4[7]};
		8'b0000_0011:	nHC4 = {6'd0, HC4[7:6]};
		8'b0000_0111:	nHC4 = {5'd0, HC4[7:5]};
		8'b0000_1111:	nHC4 = {4'd0, HC4[7:4]};
		8'b0001_1111:	nHC4 = {3'd0, HC4[7:3]};
		/*
		8'b0011_1111:	nHC4 = {2'd0, HC4[7:2]};
		8'b0111_1111:	nHC4 = {1'd0, HC4[7:1]};
		8'b1111_1111:	nHC4 = HC4;
		*/
		default		:	nHC4 = 8'dx;
	endcase

//nHC5		
always @ (*)
	case (M5)
		8'b0000_0000:	nHC5 = 8'd0;
		8'b0000_0001:	nHC5 = {7'd0, HC5[7]};
		8'b0000_0011:	nHC5 = {6'd0, HC5[7:6]};
		8'b0000_0111:	nHC5 = {5'd0, HC5[7:5]};
		8'b0000_1111:	nHC5 = {4'd0, HC5[7:4]};
		8'b0001_1111:	nHC5 = {3'd0, HC5[7:3]};
		/*
		8'b0011_1111:	nHC5 = {2'd0, HC5[7:2]};
		8'b0111_1111:	nHC5 = {1'd0, HC5[7:1]};
		8'b1111_1111:	nHC5 = HC5;
		*/
		default		:	nHC5 = 8'dx;
	endcase

//nHC6		
always @ (*)
	case (M6)
		8'b0000_0000:	nHC6 = 8'd0;
		8'b0000_0001:	nHC6 = {7'd0, HC6[7]};
		8'b0000_0011:	nHC6 = {6'd0, HC6[7:6]};
		8'b0000_0111:	nHC6 = {5'd0, HC6[7:5]};
		8'b0000_1111:	nHC6 = {4'd0, HC6[7:4]};
		8'b0001_1111:	nHC6 = {3'd0, HC6[7:3]};
		/*
		8'b0011_1111:	nHC6 = {2'd0, HC6[7:2]};
		8'b0111_1111:	nHC6 = {1'd0, HC6[7:1]};
		8'b1111_1111:	nHC6 = HC6;
		*/
		default		:	nHC6 = 8'dx;
	endcase	


endmodule

