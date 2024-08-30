`define		state_wait		2'd0
`define		state_str		2'd1
`define		state_pat		2'd2

`define		state_finish	3'd0
`define		state_set		3'd1
`define		state_comp		3'd2
`define		state_comp_s	3'd3
`define		state_result	3'd4

module SME(clk,reset,chardata,isstring,ispattern,valid,match,match_index);
input 				clk;
input 				reset;
input 	[7:0] 		chardata;
input 				isstring;
input 				ispattern;
output 				match;
output 	[4:0] 		match_index;
output 				valid;
/*
reg 				match;
reg 	[4:0] 		match_index;
reg					valid;
*/
reg		[255:0]		str, n_str;
reg		[63:0]		pat, n_pat;
reg		[5:0]		count_s, n_count_s;
reg		[3:0]		count_p, n_count_p;
reg		[1:0]		cs, ns;

wire				start_comp1, start_comp;
reg					start_comp2;


reg		[2:0]		cs_comp, ns_comp;

reg		[5:0]		str_index;
reg		[3:0]		pat_index;

wire	[7:0]		str_comp, pat_comp, str_comp_s, pat_comp_s, pat_comp2;
reg		[7:0]		same, same_s;
reg					tmp, tmp_s;

reg					match;
wire	[4:0]		match_index;

wire				valid1, valid;
reg					valid2;


/////////////////////////////////////////////
//         DFF
/////////////////////////////////////////////
always @ (posedge clk or posedge reset)
	if (reset)
		begin
			str     <= 256'd0;
			pat     <= 64'd0;
			count_s <= 6'd1;
			count_p <= 4'd1;
		end
	else
		begin
			str     <= n_str;
			pat 	<= n_pat;
			count_s <= n_count_s;
			count_p <= n_count_p;
		end

always @ (*)
	case (cs)
		`state_wait:
			n_str = (isstring)? {248'h20202020202020202020202020202020202020202020202020202020202020, chardata} : str;
		`state_str:
			n_str = (isstring)? {str[247:0], chardata} : str;
		default:
			n_str = str;
	endcase

always @ (*)
	case (cs)
		`state_wait, `state_str:
			n_pat = (ispattern)? {56'd0, chardata} : pat;
		`state_pat:
			n_pat = (ispattern)? {pat[55:0], chardata} : pat;
		default:
			n_pat = pat;
	endcase

always @ (*)
	case (cs)
		`state_wait:
			begin
				n_count_s = (isstring)?  6'd1 : count_s;
				n_count_p = (ispattern)? 4'd1 : count_p;
			end
		`state_str:
			begin
				n_count_s = (isstring)? count_s + 6'd1: count_s;
				n_count_p = (ispattern)? 4'd1 : count_p;
			end
		`state_pat:
			begin
				n_count_s = count_s;
				n_count_p = (ispattern)? count_p + 4'd1 : count_p;
			end
	endcase


/////////////////////////////////////////////
//         FSM
/////////////////////////////////////////////
always @ (posedge clk or posedge reset)
	if (reset)
		cs <= `state_wait;
	else
		cs <= ns;

always @ (*)
	case (cs)
		`state_wait:	ns = (isstring)?  `state_str : ((ispattern)? `state_pat : `state_wait);
		`state_str:		ns = (isstring)?  `state_str : `state_pat;
		`state_pat:		ns = (ispattern)? `state_pat : `state_wait;
		default:		ns = 2'dx;
	endcase


/////////////////////////////////////////////
//         CNT signal
/////////////////////////////////////////////
assign start_comp1 = (cs == `state_wait);

always @ (posedge clk)
	start_comp2 <= ~start_comp1;

assign start_comp = start_comp1 & start_comp2;



//*********compare work********************//


/////////////////////////////////////////////
//         compare FSM
/////////////////////////////////////////////
always @ (posedge clk or posedge reset)
	if (reset)
		cs_comp <= `state_finish;
	else
		cs_comp <= ns_comp;

always @ (*)
	case (cs_comp)
		`state_finish:	ns_comp = (start_comp)? `state_set : `state_finish;
		`state_set:		ns_comp = (count_p == 4'd9)?`state_finish : (pat_comp2 == 8'h5E)? `state_comp_s : `state_comp;
		`state_comp:	ns_comp = (pat_index == count_p)? `state_result : `state_comp;
		`state_comp_s:	ns_comp = (pat_index == count_p)? `state_result : `state_comp_s;
		`state_result:	ns_comp = 3'd5;
		3'd5:			ns_comp = ( match || (str_index == count_s) )? `state_finish : `state_set;
		default:		ns_comp = 3'dx;
	endcase

pat_mux m5 (pat, count_p, 4'd1, pat_comp2);
/////////////////////////////////////////////
//         state: set
/////////////////////////////////////////////
always @ (posedge clk)
	if (cs_comp == `state_finish)
		str_index <= 6'd0;
	else if (cs_comp == `state_set)
		str_index <= str_index + 6'd1;
	else
		str_index <= str_index;

	
always @ (posedge clk)
	if (cs_comp == `state_set)
		pat_index <= 4'd1;
	else
		pat_index <= pat_index + 4'd1;


/////////////////////////////////////////////
//         state: compare
/////////////////////////////////////////////
str_mux m1 (str, count_s, str_index + {2'd0, pat_index}, str_comp);
pat_mux m2 (pat, count_p, pat_index, pat_comp);


always @ (posedge clk)
	if (cs_comp == `state_set)
		same <= 8'b1111_1111;
	else if (cs_comp == `state_comp)
		same <= {same[6:0], tmp};
	else
		same <= same;

always @ (*)
	if ( (pat_comp == 8'h24) && (str_comp == 8'h20) )
		tmp = 1'b1;
	else if (pat_comp == 8'h2E)
		tmp = 1'b1;
	else if (pat_comp == str_comp)
		tmp = 1'b1;
	else
		tmp = 1'b0;


/////////////////////////////////////////////
//         state: compare_s
/////////////////////////////////////////////
str_mux m3 (str, count_s, str_index + {2'd0, pat_index} - 6'd1, str_comp_s);
pat_mux m4 (pat, count_p, pat_index, pat_comp_s);


always @ (posedge clk)
	if (cs_comp == `state_set)
		same_s <= 8'b1111_1111;
	else if (cs_comp == `state_comp_s)
		same_s <= {same_s[6:0], tmp_s};
	else
		same_s <= same_s;

always @ (*)
	if ( (pat_comp_s == 8'h24) && (str_comp_s == 8'h20) )
		tmp_s = 1'b1;
	else if (pat_comp_s == 8'h2E)
		tmp_s = 1'b1;
	else if (pat_comp_s == str_comp_s)
		tmp_s = 1'b1;
	else if ( (pat_comp_s == 8'h5E) && (str_comp_s == 8'h20) )
		tmp_s = 1'b1;
	else
		tmp_s = 1'b0;
		

/////////////////////////////////////////////
//         state: result
/////////////////////////////////////////////
always @ (posedge clk)
	if (cs_comp == `state_set)
		match <= 1'b0;
	else if (cs_comp == `state_result)
		match <= &{same[7:0], same_s[7:0]};
	else
		match <= match;

assign match_index = str_index - 1;

assign valid1 = (cs_comp == `state_finish);

always @ (posedge clk)
	valid2 <= ~valid1;

assign valid = valid1 & valid2;



endmodule


/////////////////////////////////////////////
//         MUX
/////////////////////////////////////////////
module str_mux (str, count_s, str_index, str_comp);
input	[255:0]	str;
input	[5:0]	count_s, str_index;
output	[7:0]	str_comp;
reg		[7:0]	str_comp;
always @ (*)
	case (count_s - str_index + 6'd2)
		6'd0:	str_comp = 8'h20;
		6'd1:	str_comp = str[7:0];
		6'd2:	str_comp = str[15:8];
		6'd3:	str_comp = str[23:16];
		6'd4:	str_comp = str[31:24];
		6'd5:	str_comp = str[39:32];
		6'd6:	str_comp = str[47:40];
		6'd7:	str_comp = str[55:48];
		6'd8:	str_comp = str[63:56];
		6'd9:	str_comp = str[71:64];	
		6'd10:	str_comp = str[79:72];
		6'd11:	str_comp = str[87:80];
		6'd12:	str_comp = str[95:88];
		6'd13:	str_comp = str[103:96];
		6'd14:	str_comp = str[111:104];
		6'd15:	str_comp = str[119:112];
		6'd16:	str_comp = str[127:120];
		6'd17:	str_comp = str[135:128];
		6'd18:	str_comp = str[143:136];
		6'd19:	str_comp = str[151:144];
		6'd20:	str_comp = str[159:152];
		6'd21:	str_comp = str[167:160];//
		6'd22:	str_comp = str[175:168];
		6'd23:	str_comp = str[183:176];
		6'd24:	str_comp = str[191:184];
		6'd25:	str_comp = str[199:192];
		6'd26:	str_comp = str[207:200];
		6'd27:	str_comp = str[215:208];	
		6'd28:	str_comp = str[223:216];
		6'd29:	str_comp = str[231:224];	
		6'd30:	str_comp = str[239:232];
		6'd31:	str_comp = str[247:240];
		6'd32:	str_comp = str[255:248];
		default:str_comp = 8'dx;
	endcase
endmodule

module pat_mux (pat, count_p, pat_index, pat_comp);
input	[63:0]	pat;
input	[3:0]	count_p, pat_index;
output	[7:0]	pat_comp;
reg		[7:0]	pat_comp;
always @ (*)
	case (count_p - pat_index + 4'd1)
		4'd1:	pat_comp = pat[7:0];
		4'd2:	pat_comp = pat[15:8];
		4'd3:	pat_comp = pat[23:16];
		4'd4:	pat_comp = pat[31:24];
		4'd5:	pat_comp = pat[39:32];
		4'd6:	pat_comp = pat[47:40];
		4'd7:	pat_comp = pat[55:48];
		4'd8:	pat_comp = pat[63:56];
		default:pat_comp = 8'dx;
	endcase
endmodule
