`define	state_initial	3'd0
`define	state_compare	3'd1
`define	state_minimum	3'd2
`define	state_swap		3'd3
`define	state_inverse	3'd4
`define	state_finish	3'd5

module dictionary (clk, reset, next, A, B, C, D, E, F, G, H, finish);
input  			clk;
input  			reset;
input			next;
output	[2:0] 	A, B, C, D, E, F, G, H;
output			finish;
reg		[2:0]	A, B, C, D, E, F, G, H;
reg		[2:0] 	cs, ns;
reg		[2:0] 	comp_cs, comp_ns;
reg		[2:0] 	change_point, tmp;
wire			n_finish_compare;

reg				finish_compare;

reg		[2:0]	pointer, minimum, minimum_value;
wire	[2:0]	change_point_value, pointer_value;
wire			n_finish_minimum;

reg				finish_minimum;

reg		[2:0]	n_A, n_B, n_C, n_D, n_E, n_F, n_G, n_H;

wire			finish;
//reg 			finish;

//****************************************************  DFF
always @ (posedge clk or posedge reset)
	if (reset) begin
		A <= 3'd0;
		B <= 3'd1;
		C <= 3'd2;
		D <= 3'd3;
		E <= 3'd4;
		F <= 3'd5;
		G <= 3'd6;
		H <= 3'd7;
	end
	else begin
		A <= n_A;
		B <= n_B;
		C <= n_C;
		D <= n_D;
		E <= n_E;
		F <= n_F;
		G <= n_G;
		H <= n_H;
	end
//****************************************************  DFF


//****************************************************  FSM
always @ (posedge clk or posedge reset) 
	if (reset)
		cs <= `state_initial;
	else
		cs <= ns;

always @ (*) 
	case (cs)
		`state_initial: 		ns = `state_compare;
		`state_compare: 		ns = finish_compare? `state_minimum:`state_compare;
		`state_minimum: 		ns = finish_minimum? `state_swap:`state_minimum;
		`state_swap:	 		ns = `state_inverse;
		`state_inverse: 		ns = `state_finish;
		`state_finish:			ns = next? `state_compare : `state_finish;
		default: 	ns = 3'dx;
	endcase
//****************************************************  FSM


//****************************************************  control signal
always @ (posedge clk or posedge reset)
	if (reset) begin
		finish_compare <= 1'b0;
		finish_minimum <= 1'b0;
		//finish 		   <= 1'b0;
	end
	else begin
		finish_compare <= (cs == `state_compare)? n_finish_compare : 1'b0;
		finish_minimum <= (cs == `state_minimum)? n_finish_minimum : 1'b0;
		//finish		   <= (cs == 3'd5)? 1'b1 : 1'b0;
	end
	
assign n_finish_compare = (comp_cs == 4'd7)? 1'b1: 1'b0;

assign n_finish_minimum = (pointer == change_point);

assign finish = (cs == `state_finish);
//****************************************************  control signal


//****************************************************  compare
always @ (posedge clk or posedge reset) 
	if (reset) begin
		comp_cs <= 3'd0;
		change_point <= 3'dx;
	end
	else begin
		comp_cs <= comp_ns;
		change_point <= tmp;
	end

always @ (*) 
	case(comp_cs)
		3'd0: 	 
			if (G > H) begin
				comp_ns = 3'd1;
				tmp = 3'dx;
			end
			else begin
				comp_ns = 3'd7;
				tmp = 3'd6;
			end
		3'd1: 	
			if (F > G) begin
				comp_ns = 3'd2;
				tmp = 3'dx;
			end
			else begin
				comp_ns = 3'd7;
				tmp = 3'd5;
			end
		3'd2:	 
			if (E > F) begin
				comp_ns = 3'd3;
				tmp = 3'dx;
			end
			else begin
				comp_ns = 3'd7;
				tmp = 3'd4;
			end
		3'd3: 	 
			if (D > E) begin
				comp_ns = 3'd4;
				tmp = 3'dx;
			end
			else begin
				comp_ns = 3'd7;
				tmp = 3'd3;
			end
		3'd4: 	 
			if (C > D) begin
				comp_ns = 3'd5;
				tmp = 3'dx;
			end
			else begin
				comp_ns = 3'd7;
				tmp = 3'd2;
			end
		3'd5:
			if (B > C) begin
				comp_ns = 3'd6;
				tmp = 3'dx;
			end
			else begin
				comp_ns = 3'd7;
				tmp = 3'd1;
			end
		3'd6: 
			if (A > B) begin
				comp_ns = 3'd7;
				tmp = 3'dx;
			end
			else begin
				comp_ns = 3'd7;
				tmp = 3'd0;
			end
		3'd7: 	 
			begin
				comp_ns = next? 3'd0:3'd7;
				tmp = change_point;
			end
		default:
			begin
				comp_ns = 4'dx;
				tmp = 3'dx;
			end
	endcase
//****************************************************  compare


//****************************************************  minimum
always @ (posedge clk) begin
	if (cs == `state_compare) begin
		pointer 		<= 3'd7;
		minimum 		<= 3'dx;
		minimum_value 	<= 3'd7;
	end
	else if (cs == `state_minimum) begin
		pointer			 <= (pointer == change_point)? pointer:pointer - 1;
		minimum 		 <= (minimum_value >= pointer_value && pointer_value > change_point_value)? pointer:minimum;
		minimum_value    <= (minimum_value >= pointer_value && pointer_value > change_point_value)? pointer_value:minimum_value;
	end
end

mux m1 (.A(A), .B(B), .C(C), .D(D), .E(E), .F(F), .G(G), .H(H), .sel(change_point), .FF(change_point_value));
mux m2 (.A(A), .B(B), .C(C), .D(D), .E(E), .F(F), .G(G), .H(H), .sel(pointer), .FF(pointer_value));
//****************************************************  minimum



//****************************************************  swap + inverse
always @ (*) begin
	if (cs == `state_swap) begin
		case(change_point)
			3'd0:
				begin
					n_A = minimum_value;
					n_B = (minimum == 3'd1)? change_point_value:B;
					n_C = (minimum == 3'd2)? change_point_value:C;
					n_D = (minimum == 3'd3)? change_point_value:D;
					n_E = (minimum == 3'd4)? change_point_value:E;
					n_F = (minimum == 3'd5)? change_point_value:F;
					n_G = (minimum == 3'd6)? change_point_value:G;
					n_H = (minimum == 3'd7)? change_point_value:H;
				end
			3'd1:
				begin
					n_A = A;
					n_B = minimum_value;
					n_C = (minimum == 3'd2)? change_point_value:C;
					n_D = (minimum == 3'd3)? change_point_value:D;
					n_E = (minimum == 3'd4)? change_point_value:E;
					n_F = (minimum == 3'd5)? change_point_value:F;
					n_G = (minimum == 3'd6)? change_point_value:G;
					n_H = (minimum == 3'd7)? change_point_value:H;
				end
			3'd2:
				begin
					n_A = A;
					n_B = B;
					n_C = minimum_value;
					n_D = (minimum == 3'd3)? change_point_value:D;
					n_E = (minimum == 3'd4)? change_point_value:E;
					n_F = (minimum == 3'd5)? change_point_value:F;
					n_G = (minimum == 3'd6)? change_point_value:G;
					n_H = (minimum == 3'd7)? change_point_value:H;
				end
			3'd3:
				begin
					n_A = A;
					n_B = B;
					n_C = C;
					n_D = minimum_value;
					n_E = (minimum == 3'd4)? change_point_value:E;
					n_F = (minimum == 3'd5)? change_point_value:F;
					n_G = (minimum == 3'd6)? change_point_value:G;
					n_H = (minimum == 3'd7)? change_point_value:H;
				end
			3'd4:
				begin
					n_A = A;
					n_B = B;
					n_C = C;
					n_D = D;
					n_E = minimum_value;
					n_F = (minimum == 3'd5)? change_point_value:F;
					n_G = (minimum == 3'd6)? change_point_value:G;
					n_H = (minimum == 3'd7)? change_point_value:H;
				end
			3'd5:
				begin
					n_A = A;
					n_B = B;
					n_C = C;
					n_D = D;
					n_E = E;
					n_F = minimum_value;
					n_G = (minimum == 3'd6)? change_point_value:G;
					n_H = (minimum == 3'd7)? change_point_value:H;
				end
			3'd6:
				begin
					n_A = A;
					n_B = B;
					n_C = C;
					n_D = D;
					n_E = E;
					n_F = F;
					n_G = minimum_value;
					n_H = change_point_value;
				end
			default:
				begin
					n_A = 3'dx;
					n_B = 3'dx;
					n_C = 3'dx;
					n_D = 3'dx;
					n_E = 3'dx;
					n_F = 3'dx;
					n_G = 3'dx;
					n_H = 3'dx;
				end
		endcase
	end
	else if (cs == `state_inverse)
		case (change_point)
			3'd0:
				begin
					n_A = A;
					n_B = H;
					n_C = G;
					n_D = F;
					n_E = E;
					n_F = D;
					n_G = C;
					n_H = B;
				end
			3'd1:
				begin
					n_A = A;
					n_B = B;
					n_C = H;
					n_D = G;
					n_E = F;
					n_F = E;
					n_G = D;
					n_H = C;
				end		
			3'd2:
				begin
					n_A = A;
					n_B = B;
					n_C = C;
					n_D = H;
					n_E = G;
					n_F = F;
					n_G = E;
					n_H = D;
				end	
			3'd3:
				begin
					n_A = A;
					n_B = B;
					n_C = C;
					n_D = D;
					n_E = H;
					n_F = G;
					n_G = F;
					n_H = E;
				end	
			3'd4:
				begin
					n_A = A;
					n_B = B;
					n_C = C;
					n_D = D;
					n_E = E;
					n_F = H;
					n_G = G;
					n_H = F;
				end	
			3'd5:
				begin
					n_A = A;
					n_B = B;
					n_C = C;
					n_D = D;
					n_E = E;
					n_F = F;
					n_G = H;
					n_H = G;
				end	
			3'd6:
				begin
					n_A = A;
					n_B = B;
					n_C = C;
					n_D = D;
					n_E = E;
					n_F = F;
					n_G = G;
					n_H = H;
				end	
			default:
				begin
					n_A = 3'dx;
					n_B = 3'dx;
					n_C = 3'dx;
					n_D = 3'dx;
					n_E = 3'dx;
					n_F = 3'dx;
					n_G = 3'dx;
					n_H = 3'dx;
				end
		endcase
	else begin
		n_A = A;
		n_B = B;
		n_C = C;
		n_D = D;
		n_E = E;
		n_F = F;
		n_G = G;
		n_H = H;
	end
end


endmodule


//****************************************************  mux
module mux (A, B, C, D, E, F, G, H, sel, FF);
input	[2:0]	A, B, C, D, E, F, G, H, sel;
output	[2:0]	FF;
reg		[2:0]	FF;

always @ (*) begin
	case (sel)
		3'd0: FF = A;
		3'd1: FF = B;
		3'd2: FF = C;
		3'd3: FF = D;
		3'd4: FF = E;
		3'd5: FF = F;
		3'd6: FF = G;
		3'd7: FF = H;
		default: FF = 3'dx;
	endcase
end

endmodule
//****************************************************  mux

