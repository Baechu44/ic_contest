`include 	"./cross_product_v2.v"
`define		state_wait			3'd0
`define		state_initialize	3'd1
`define		state_change1_1		3'd2
`define		state_change1_2		3'd3
`define		state_change2_1		3'd4
`define		state_change2_2		3'd5


module sort (clk, reset, finish_load, G1, G2, G3, G4, G5, G6, new_G1, new_G2, new_G3, new_G4, new_G5, new_G6, finish_sort);
input			clk;
input			reset;
input			finish_load;
input	[19:0]	G1, G2, G3, G4, G5, G6;	

output	[19:0]	new_G1, new_G2, new_G3, new_G4, new_G5, new_G6;
output			finish_sort;

reg		[19:0]	new_G2, new_G3, new_G4, new_G5, new_G6;
reg		[19:0]	n_new_G2, n_new_G3, n_new_G4, n_new_G5, n_new_G6;
reg		[19:0]	A1, A2;
wire	[21:0]	S1, S2;

reg		[2:0]	cs, ns;

wire			cloclwise;

wire			finish_sort_1;
reg				finish_sort_2;

reg		[1:0]	count;


//*******************************************************************************  FSM
always @ (posedge clk or posedge reset)
	if (reset)
		cs <= `state_wait;
	else
		cs <= ns;

always @ (*)
	case (cs)
		`state_wait:			ns = (finish_load)? `state_initialize : `state_wait;
		`state_initialize:		ns = `state_change1_1;
		`state_change1_1:		ns = `state_change1_2;
		`state_change1_2:		ns = `state_change2_1;
		`state_change2_1:		ns = `state_change2_2;
		`state_change2_2:		ns = (count == 2'd3)? `state_wait : `state_change1_1;
		default:				ns = 3'dx;
	endcase
	
always @ (posedge clk)
	if (cs == `state_initialize)
		count <= 2'd0;
	else  
		count <= (cs == `state_change1_1)? count + 2'd1 : count;
//*******************************************************************************  FSM



//*******************************************************************************  DFF

assign new_G1 	= G1;

always @ (posedge clk)
	begin
		new_G2 <= n_new_G2;
		new_G3 <= n_new_G3;
		new_G4 <= n_new_G4;
		new_G5 <= n_new_G5;
		new_G6 <= n_new_G6;
	end

always @ (*)
	case (cs)
		`state_wait:
			begin
				n_new_G2 = new_G2;
				n_new_G3 = new_G3;
				n_new_G4 = new_G4;
				n_new_G5 = new_G5;
				n_new_G6 = new_G6;
			end
		`state_initialize:
			begin
				n_new_G2 = G2;
				n_new_G3 = G3;
				n_new_G4 = G4;
				n_new_G5 = G5;
				n_new_G6 = G6;
			end
		`state_change1_1:
			begin
				n_new_G2 = (cloclwise)? new_G2 : new_G3;
				n_new_G3 = (cloclwise)? new_G3 : new_G2;
				n_new_G4 = new_G4;
				n_new_G5 = new_G5;
				n_new_G6 = new_G6;
			end
		`state_change1_2:
			begin
				n_new_G2 = new_G2;
				n_new_G3 = new_G3;
				n_new_G4 = (cloclwise)? new_G4 : new_G5;
				n_new_G5 = (cloclwise)? new_G5 : new_G4;
				n_new_G6 = new_G6;
			end
		`state_change2_1:
			begin
				n_new_G2 = new_G2;
				n_new_G3 = (cloclwise)? new_G3 : new_G4;
				n_new_G4 = (cloclwise)? new_G4 : new_G3;
				n_new_G5 = new_G5;
				n_new_G6 = new_G6;
			end
		`state_change2_2:
			begin
				n_new_G2 = new_G2;
				n_new_G3 = new_G3;
				n_new_G4 = new_G4;
				n_new_G5 = (cloclwise)? new_G5 : new_G6;
				n_new_G6 = (cloclwise)? new_G6 : new_G5;
			end			
		default:
			begin
				n_new_G2 = 20'dx;
				n_new_G3 = 20'dx;
				n_new_G4 = 20'dx;
				n_new_G5 = 20'dx;
				n_new_G6 = 20'dx;
			end		
	endcase

sub s1 (A1, G1, S1);
sub s2 (A2, G1, S2);

cross_product c1 (S1[21:11], S1[10:0], S2[21:11], S2[10:0], cloclwise);


always @ (*)
	case (cs)
		`state_change1_1:
			begin
				A1 = new_G2;
				A2 = new_G3;
			end
		`state_change1_2:
			begin
				A1 = new_G4;
				A2 = new_G5;
			end
		`state_change2_1:
			begin
				A1 = new_G3;
				A2 = new_G4;
			end
		`state_change2_2:
			begin
				A1 = new_G5;
				A2 = new_G6;
			end
		default:
			begin
				A1 = 20'dx;
				A2 = 20'dx;
			end	
	endcase


//*****************************************************************************************  CNT signal
assign finish_sort_1 = (cs == `state_wait);

always @ (posedge clk)
	finish_sort_2 <= ~finish_sort_1;
	
assign finish_sort = finish_sort_1 & finish_sort_2;


endmodule
