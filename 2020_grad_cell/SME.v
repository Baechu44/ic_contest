module SME(clk,reset,chardata,isstring,ispattern,valid,match,match_index);
input 			clk;
input 			reset;
input 	[7:0] 	chardata;
input 			isstring;
input 			ispattern;
output 			match;
output 	[4:0] 	match_index;
output 			valid;
// reg match;
// reg [4:0] match_index;
// reg valid;

reg				cs, ns;

reg		[7:0]	str		[0:31];
reg		[7:0]	pat		[0:7];

integer			i, j;

reg		[4:0]	str_count, str_count_max, str_ptr, n_str_ptr, pointer, n_pointer, backup;
reg		[2:0]	pat_count, pat_count_max, pat_ptr, n_pat_ptr;

reg				finish_load_1, match_2, timestamp;
wire			finish_load, equal, match, valid;
wire	[4:0]	match_index;


////////////////////////////////////////////
//              FSM
////////////////////////////////////////////

parameter	state_load		= 1'b0,
			state_compare	= 1'b1;
			

always @ (posedge clk or posedge reset)
	if (reset)
		cs <= state_load;
	else
		cs <= ns;

always @ (*)
	case (cs)
		state_load	 :	ns = (finish_load)? state_compare : state_load;
		state_compare:	ns = (valid)?		state_load	  : state_compare;
		
		default:		ns = 1'bx;
	endcase


////////////////////////////////////////////
//              state_load
////////////////////////////////////////////

//string
always @ (posedge clk or posedge reset)
	if (reset)
		for (i=0; i<=31; i=i+1)
			str[i] <= 8'h20;
	
	else if (isstring)
		str[str_count] <= chardata;
	
	else
		for (i=0; i<=31; i=i+1)
			str[i] <= str[i];

//pattern
always @ (posedge clk or posedge reset)
	if (reset)
		for (j=0; j<=7; j=j+1)
			pat[i] <= 8'h20;
	
	else if (ispattern)
		pat[pat_count] <= chardata;
	
	else
		for (j=0; j<=7; j=j+1)
			pat[i] <= pat[i];

//str_count, str_count_max
always @ (posedge clk or posedge reset)
	if (reset)
		begin
			str_count 		<= 5'd0;
			str_count_max	<= 5'd0;
		end
	
	else if (isstring)
		begin
			str_count 		<= str_count + 5'd1;
			str_count_max	<=	str_count;
		end

	else
		begin
			str_count 		<= 5'd0;
			str_count_max	<= str_count_max;
		end

//pat_count, pat_count_max
always @ (posedge clk or posedge reset)
	if (reset)
		begin
			pat_count 		<= 3'd0;
			pat_count_max	<= 3'd0;
		end

	else if (ispattern)
		begin
			pat_count 		<= pat_count + 3'd1;
			pat_count_max	<= pat_count;
		end

	else
		begin
			pat_count 		<= 3'd0;
			pat_count_max	<= pat_count_max;
		end

//finish_load
always @ (posedge clk or posedge reset)
	if (reset)
		finish_load_1 <= 1'b1;
	else
		finish_load_1 <= ~ispattern;

assign finish_load = ~(finish_load_1 | ispattern);


////////////////////////////////////////////
//              state_compare
////////////////////////////////////////////

//pointer, match_index
always @ (posedge clk or posedge reset)
	if (reset)
		begin
			str_ptr	<= 5'd0;
			pat_ptr	<= 3'd0;
			pointer	<= 5'd0;
		end
	
	else if (cs == state_compare)
		begin
			str_ptr	<= n_str_ptr;
			pat_ptr	<= n_pat_ptr;
			pointer	<= n_pointer;
		end
	
	else
		begin
			str_ptr	<= 5'd0;
			pat_ptr	<= 3'd0;
			pointer	<= 5'd0;
		end

//n_str_ptr, n_pat_ptr
always @ (*)
	if (pat[pat_ptr] == 8'h2A)//
		begin
			n_str_ptr = (str[str_ptr] == pat[pat_ptr + 3'd1])? str_ptr		  : str_ptr + 5'd1; 
			n_pat_ptr = (pat_ptr == pat_count_max)?		  	   pat_ptr        : 
						(str[str_ptr] == pat[pat_ptr + 3'd1])? pat_ptr + 3'd1 : pat_ptr;
			n_pointer = pointer;
		end
	
	else if (equal)
		begin
			n_str_ptr = (str_ptr == str_count_max)? str_ptr : str_ptr + 5'd1;
			n_pat_ptr = (pat_ptr == pat_count_max)? pat_ptr : pat_ptr + 3'd1;
			n_pointer = pointer;
		end
	
	else
		begin
			n_str_ptr = (str_ptr == str_count_max)? str_ptr : pointer + 5'd1;
			n_pat_ptr = 3'd0;
			n_pointer = pointer + 5'd1;
		end

assign equal =  (pat[pat_ptr] == str[str_ptr]) 										   			|| 
				(pat[pat_ptr] == 8'h5E && (str[str_ptr] == 8'h20 || str_ptr == 5'd0) ) 			||
				(pat[pat_ptr] == 8'h24 && (str[str_ptr] == 8'h20 || str_ptr == str_count_max) ) ||
				(pat[pat_ptr] == 8'h2E);

//backup *
always @ (posedge clk or posedge reset)
	if (reset)
		begin
			backup    <= 5'd0;
			timestamp <= 1'b0;
		end
	
	else if (cs == state_compare)
		begin
			backup    <= (pat[pat_ptr] == 8'h2A && timestamp == 1'b0)? pointer : backup;
			timestamp <= (pat[pat_ptr] == 8'h2A && timestamp == 1'b0)? 1'b1    : timestamp;
		end
	
	else
		begin
			backup    <= 5'd0;
			timestamp <= 1'd0;
		end
	
				
//output stage
always @ (posedge clk or posedge reset)
	if (reset)
		begin
			match_2 <= 1'b0;
		end
	else
		begin
			match_2 <= (str_ptr == str_count_max);
		end

assign match 	   = (cs == state_compare) && (pat_ptr == pat_count_max) && equal;

assign match_index =  (timestamp)?	 	 backup  :
					  (pat[0] != 8'h5E)? pointer :
					  (pointer == 5'd0)? pointer : pointer + 5'd1;

assign valid	   = ((cs == state_compare) &&match_2 && (str_ptr == str_count_max) ) || match;



endmodule
