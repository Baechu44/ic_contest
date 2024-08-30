`define	state_load		2'd0
`define	state_get_cost	2'd1
`define	state_change	2'd2
`define	state_finish	2'd3


module sum (clk, reset, start, A, B, C, D, E, F, G, H, Cost, W, J, next, MatchCount, MinCost, Valid);
input			clk;
input  			reset;
input			start;//connect to dictionary's finish
input	[2:0]	A, B, C, D, E, F, G, H;
input	[6:0]	Cost;
output	[2:0]	W;
output	[2:0]	J;
output			next;
output	[3:0]	MatchCount;
output	[9:0]	MinCost;
output			Valid;


reg		[1:0]	cs, ns;
reg		[2:0]	FF_A, FF_B, FF_C, FF_D, FF_E, FF_F, FF_G, FF_H;

reg		[2:0]	W;
reg		[2:0]	J, n_J;
reg		[9:0]	total;
wire			finish_get_cost;

reg		[3:0]	MatchCount;
reg		[9:0]	MinCost;

reg				Valid, n_Valid;


//****************************************************  FSM
always @ (posedge clk or posedge reset)
	if (reset)
		cs <= `state_load;
	else
		cs <= ns;

always @ (*)
	case (cs)
		`state_load:		 ns = `state_get_cost;
		`state_get_cost:	 ns = finish_get_cost? `state_change : `state_get_cost;
		`state_change:		 ns = `state_finish;
		`state_finish:	 	 ns = start? `state_load : `state_finish;
		default: ns = 2'dx;
	endcase
//****************************************************  FSM


//****************************************************  DFF
always @ (posedge clk or posedge reset)
	if (reset) begin
		FF_A <= 3'd0;
		FF_B <= 3'd1;
		FF_C <= 3'd2;
		FF_D <= 3'd3;
		FF_E <= 3'd4;
		FF_F <= 3'd5;
		FF_G <= 3'd6;
		FF_H <= 3'd7;
	end
	else begin
		FF_A <= (cs == `state_load)? A:FF_A;
		FF_B <= (cs == `state_load)? B:FF_B;
		FF_C <= (cs == `state_load)? C:FF_C;
		FF_D <= (cs == `state_load)? D:FF_D;
		FF_E <= (cs == `state_load)? E:FF_E;
		FF_F <= (cs == `state_load)? F:FF_F;
		FF_G <= (cs == `state_load)? G:FF_G;
		FF_H <= (cs == `state_load)? H:FF_H;
	end
//****************************************************  DFF


//****************************************************  get_cost
always @ (posedge clk)
	if (cs == `state_load) begin
		W     <= 3'd0;
		J     <= A;
		total <= 10'd0;
	end
	else if (cs == `state_get_cost) begin
		W     <= (W == 3'd7)? 3'd7 : W + 1;
		J     <= n_J;
		total <= total + {3'd0, Cost};
	end
	else  begin
		W     <= 3'dx;
		J     <= 3'dx;
		total <= total;
	end


	
always @ (*)
	case (W)
		3'd0:    n_J = FF_B;
		3'd1:    n_J = FF_C;
		3'd2:    n_J = FF_D;
		3'd3:    n_J = FF_E;
		3'd4:    n_J = FF_F;
		3'd5:    n_J = FF_G;
		3'd6:    n_J = FF_H;
		3'd7:    n_J = FF_H;
		default: n_J = 3'dx;
	endcase

assign finish_get_cost = (W == 3'd7);
//****************************************************  get_cost


//****************************************************  change
always @ (posedge clk or posedge reset)
	if (reset) begin
		MatchCount 	<= 4'd0;
		MinCost		<= 10'd501;
	end
	else if (cs == `state_change) begin
		MatchCount 	<= (MinCost > total)? 4'd1 : ((MinCost == total)? MatchCount + 1 : MatchCount);
		MinCost		<= (MinCost > total)? total : MinCost;
	end
//****************************************************  change



always @ (posedge clk or posedge reset)
	if (reset)
		Valid <= 1'b0;
	else
		Valid <= n_Valid;

always @ (*)
	if ((cs == `state_finish) && (FF_A == 3'd7) && (FF_B == 3'd6) && (FF_C == 3'd5) && (FF_D == 3'd4) && (FF_E == 3'd3) && (FF_F == 3'd2) && (FF_G == 3'd1) && (FF_H == 3'd0))
		n_Valid = 1'b1;
	else
		n_Valid = 1'b0;
	
assign next = (cs == `state_load);

endmodule
