module triangle (clk, reset, nt, xi, yi, busy, po, xo, yo);
input 			clk;
input			reset;
input			nt;
input 	[2:0] 	xi;
input	[2:0]	yi;
output 			busy;
output			po;
output 	[2:0] 	xo;
output	[2:0]	yo;


reg		[1:0]	cs, ns, count;
reg		[2:0]	x	[0:2];
reg		[2:0]	y	[0:2];

integer			i;


wire	[2:0]	min_x, max_x;

wire			is_inside, cross1, cross2, same1, same2;

reg		[2:0]	test_x, test_y;

wire	[3:0]	vec1_x, vec1_y, vec2_x, vec2_y, vec3_x, vec3_y, vec4_x, vec4_y;

reg 			busy;
reg				po;
reg 	[2:0] 	xo;
reg		[2:0]	yo;


////////////////////////////////////////
//				FSM
////////////////////////////////////////

parameter	state_wait		= 2'd0,
			state_load 		= 2'd1,
			state_compute 	= 2'd2;

always @ (posedge clk or posedge reset)
	if (reset)
		cs <= state_wait;
	else
		cs <= ns;

always @ (*)
	case (cs)
		state_wait:		ns = (nt)?									state_load	  : state_wait;
		state_load:		ns = (count == 2'd2)? 						state_compute : state_load;
		state_compute:	ns = ({test_x, test_y} == {x[2], y[2]})? 	state_wait 	  : state_compute;
		
		default:		ns = 2'dx;
	endcase


////////////////////////////////////////
//				state_wait
////////////////////////////////////////

//count
always @ (posedge clk or posedge reset)
	if (reset)
		count <= 2'd0;
	else if (nt)
		count <= 2'd1;
	else if (cs == state_load)
		count <= (count == 2'd2)? 2'd2 : count + 2'd1;
	else
		count <= 2'd0;


////////////////////////////////////////
//				state_load
////////////////////////////////////////

//save x, y
always @ (posedge clk or posedge reset)
	if (reset)
		for (i=0; i<=2; i=i+1)
			{x[i], y[i]} <= 6'd0;
	else if ( nt || (cs == state_load) )
			{x[count], y[count]} <= {xi, yi};
	else
		for (i=0; i<=2; i=i+1)
			{x[i], y[i]} <= {x[i], y[i]};
	
	
////////////////////////////////////////
//				state_compute
////////////////////////////////////////	


//boundary:
assign min_x = (x[0] < x[1])? x[0] : x[1];
assign max_x = (x[0] < x[1])? x[1] : x[0];

//generate (test_x, test_y)
always @ (posedge clk)
	if (cs == state_load)
		begin
			test_x <= min_x;
			test_y <= y[0];
		end
	else if (cs == state_compute)
		begin
			test_x <= ({test_x, test_y} == {x[2], y[2]})?	x[2]          :
					  (test_x == max_x)? 					min_x         : test_x + 3'd1;
			
			test_y <= (test_y == y[2])? 					y[2]  		  :
					  (test_x == max_x)? 					test_y + 3'd1 : test_y;
		end
	else
		begin
			test_x <= test_x;
			test_y <= test_y;
		end


//check the point which is inside or not  
assign is_inside = (cross1 ~^ cross2) || ({test_x, test_y} == {x[0], y[0]}) 
					|| (test_y == y[1]) || ({test_x, test_y} == {x[2], y[2]}) || same1 || same2;


cross_product c1 (vec1_x, vec1_y, vec2_x, vec2_y, cross1, same1);

assign vec1_x = {1'b0, test_x} - {1'b0, x[1]};
assign vec1_y = {1'b0, test_y} - {1'b0, y[1]};
assign vec2_x = {1'b0,   x[0]} - {1'b0, x[1]};
assign vec2_y = {1'b0,   y[0]} - {1'b0, y[1]};


cross_product c2 (vec3_x, vec3_y, vec4_x, vec4_y, cross2, same2);

assign vec3_x = {1'b0,   x[2]} - {1'b0, x[1]};
assign vec3_y = {1'b0,   y[2]} - {1'b0, y[1]};
assign vec4_x = {1'b0, test_x} - {1'b0, x[1]};
assign vec4_y = {1'b0, test_y} - {1'b0, y[1]};

	
//output
always @ (posedge clk)
	if (cs == state_compute)
		begin
			po <= (is_inside)? 1'b1 : 1'b0;
			xo <= test_x;
			yo <= test_y;
		end
	else
		begin
			po <= 1'b0;
			xo <= 3'dx;
			yo <= 3'dx;
		end

always @ (posedge clk or posedge reset)
	if (reset)
		busy <= 1'b0;
	else if ( (cs == state_load) || (cs == state_compute) )
		busy <= 1'b1;
	else
		busy <= 1'b0;
		

endmodule


module cross_product (vec1_x, vec1_y, vec2_x, vec2_y, cloclwise, same);
input	[3:0]	vec1_x, vec1_y, vec2_x, vec2_y;
output			cloclwise, same;

wire	[2:0]	new_vec1_x, new_vec1_y, new_vec2_x, new_vec2_y;
wire	[6:0]	m1, m2;

reg				cloclwise, same;

assign new_vec1_x = (vec1_x[3])? ~vec1_x[2:0] + 3'd1 : vec1_x[2:0];
assign new_vec1_y = (vec1_y[3])? ~vec1_y[2:0] + 3'd1 : vec1_y[2:0];
assign new_vec2_x = (vec2_x[3])? ~vec2_x[2:0] + 3'd1 : vec2_x[2:0];
assign new_vec2_y = (vec2_y[3])? ~vec2_y[2:0] + 3'd1 : vec2_y[2:0];

assign m1 = new_vec1_x * new_vec2_y;
assign m2 = new_vec2_x * new_vec1_y;


always @ (*)
	case ({vec1_x[3] ^ vec2_y[3], vec1_y[3] ^ vec2_x[3]})
		2'b00: 
			begin
				cloclwise = (m1 < m2);
				same	  = (m1 == m2);
			end
		2'b01: 
			begin
				cloclwise = 0;
				same      = 0;
			end
		2'b10:
			begin
				cloclwise = 1;
				same	  = 0;
			end
		2'b11: 
			begin
				cloclwise = (m1 > m2);
				same      = (m1 == m2);
			end
	endcase


endmodule