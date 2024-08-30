module DT(
	input 					clk, 
	input					reset,
	output	reg				done ,
	output	reg				sti_rd ,
	output	reg 	[9:0]	sti_addr ,
	input			[15:0]	sti_di,
	output	reg				res_wr ,
	output	reg				res_rd ,
	output	reg 	[13:0]	res_addr ,
	output	reg 	[7:0]	res_do,
	input			[7:0]	res_di
	);


reg		[3:0]	state;
reg		[3:0]	next_state;
reg		[15:0]	pixel		[0:7];
reg		[2:0]	cnt;
reg		[6:0]	row;
reg		[6:0]	col;
reg		[7:0]	tmp;//store RAM
reg		[7:0]	op;

integer 		i;


//------------------------------------------------
//  main FSM
//------------------------------------------------
parameter 	IDLE = 4'd0,
			STOR = 4'd1,//store
			//forward
			FRWD = 4'd2,
			LROM = 4'd3,//load_ROM
			CHEK = 4'd4,//check_1
			LRAM = 4'd5,//load_RAM
			PUSH = 4'd6,//store new RAM
			ZERO = 4'd7,
			//backward
			BKWD = 4'd8,
			LRM1 = 4'd9,
			WAIT = 4'd10,
			LRM3 = 4'd11,
			SAV0 = 4'd12,
			SAVE = 4'd13,
			DONE = 4'd14;

always @ (posedge clk or negedge reset) begin
	if (!reset)
		state <= IDLE;
	else
		state <= next_state;
end

always @ (*) begin
	next_state = IDLE; 
	case (state)
		IDLE: next_state = STOR;
		STOR: next_state = (res_addr == 14'd255)? FRWD : STOR;
		//
		FRWD: next_state = LROM;
		LROM: next_state = (cnt == 3'd6)? CHEK : LROM;
		CHEK: next_state = (pixel[col[6:4]][15-col[3:0]] == 1)? LRAM : ZERO;
		LRAM: next_state = (cnt == 3'd3)? PUSH : LRAM;
		PUSH: next_state = ( (row == 8'd127) && (col == 8'd0) )? 	BKWD : 
						   (col == 8'd0)? 						LROM : CHEK;
		ZERO: next_state = ( (row == 8'd127) && (col == 8'd0) )? 	BKWD : 
						   (col == 8'd0)? 						LROM : CHEK;
		//
		BKWD: next_state = LRM1;
		LRM1: next_state = WAIT;
		WAIT: next_state = (res_di != 8'd0)? LRM3 : SAV0;
		LRM3: next_state = (cnt == 3'd3)? SAVE : LRM3;
		SAVE: next_state = ( (row == 8'd1) && (col == 8'd0) )? DONE : LRM1;
		SAV0: next_state = ( (row == 8'd1) && (col == 8'd0) )? DONE : LRM1;
		DONE: next_state = DONE;
	endcase
end


//------------------------------------------------
//  sti_rd, sti_addr, pixel
//------------------------------------------------
always @ (posedge clk or negedge reset)
	if (!reset) begin
		sti_rd <= 1'b0;
		sti_addr <= 10'd7;
		for (i=0; i<8; i=i+1)
			pixel[i] <= 16'd1;
	end else begin
		sti_rd <= 1'b0;
		sti_addr <= sti_addr;
		for (i=0; i<8; i=i+1)
			pixel[i] <= pixel[i];
		case(state)
			STOR: begin
				sti_rd <= 1'b1;
				sti_addr <= (sti_addr == 10'd15)? sti_addr : sti_addr + 10'd1;//8~15
				pixel[sti_addr[2:0]] <= sti_di;
			end
			LROM: begin
				sti_rd <= 1'b1;
				sti_addr <= sti_addr + 10'd1;;
				pixel[cnt] <= sti_di;
			end
			CHEK:
				pixel[cnt] <= sti_di;
		endcase
	end


//------------------------------------------------
//  cnt, row, col, tmp, op
//------------------------------------------------
always @ (posedge clk or negedge reset)
	if (!reset) begin
		cnt <= 3'd7;
		row <= 7'd2;
		col <= 7'd0;
		tmp <= 8'd0;
		op <= 8'd0;
	end else begin
		cnt <= 3'd7;
		row <= row;
		col <= col;
		tmp <= tmp;
		op <= op;
		case(state)
			LROM: begin
				cnt <= cnt + 3'd1;
				row <= (cnt == 3'd6)? row + 7'd1 : row;//row 會先指到下一個
				col <= 7'd0;
			end
			CHEK: begin
				col <= col + 3'd1;//col 會先指到下一個
				cnt <= 3'd0;
			end
			LRAM: begin
				cnt <= cnt + 3'd1;
				tmp <= res_rd? (( res_di < tmp)? res_di : tmp) : tmp;
			end
			PUSH: begin
				tmp <= tmp + 8'd1;
			end
			ZERO: begin
				tmp <= 8'd0;
			end
			BKWD: begin
				row <= 7'd126;
				col <= 7'd127;
				tmp <= 8'd0;
			end
			LRM1: begin
				cnt <= 3'd0;
				//op <= res_di;
			end
			WAIT: begin
				cnt <= 3'd0;
				op <= res_di;
			end
			LRM3: begin
				cnt <= cnt + 3'd1;
				tmp <= (res_di < tmp)? res_di : tmp;
			end
			SAVE: begin
				row <= (col == 7'd0)? row - 7'd1 : row;
				col <= (col == 7'd0)? 7'd127 : col - 7'd1;
				tmp <= (op < (tmp+8'd1))? op : tmp + 8'd1;
			end
			SAV0: begin
				row <= (col == 7'd0)? row - 7'd1 : row;
				col <= (col == 7'd0)? 7'd127 : col - 7'd1;
				tmp <= 8'd0;
			end
		endcase
	end


//------------------------------------------------
//  res_wr, res_rd, res_addr, res_do, res_di
//------------------------------------------------
always @ (posedge clk or negedge reset)
	if (!reset) begin
		res_wr <= 1'b0;
		res_rd <= 1'b0;
		res_addr <= 14'h3f7f;//14'd16256 = 14'h3F80...128*127
		res_do <= 8'd0;
	end else begin
		res_wr <= 1'b0;
		res_rd <= 1'b0;
		res_addr <= res_addr;
		res_do <= res_do;
		case(state)
			STOR: begin
				res_wr <= 1'b1;
				res_addr <= (res_addr == 14'd255)? res_addr : res_addr + 14'd1;
				res_do <= ( (res_addr > 14'd127) && (res_addr < 14'd256) )? {7'd0, pixel[res_addr%8][15-res_addr%16]} : 8'd0;
			end
			LRAM: begin
				//res_wr <= 1'b0;
				res_rd <= 1'b1;
				res_addr <= {row-7'd2, col-7'd2} + {11'd0, cnt};
				//res_do <= ;
			end
			PUSH: begin
				res_wr <= 1'b1;
				res_addr <= {row-7'd1, col-7'd1};
				res_do <= tmp + 8'd1;
			end
			ZERO: begin
				res_wr <= 1'b1;
				res_addr <= {row-7'd1, col-7'd1};
				res_do <= 8'd0;
			end
			LRM1: begin
				res_rd <= 1'b1;
				res_addr <= {row, col};
			end
			LRM3: begin
				res_rd <= 1'b1;
				res_addr <= {row+7'd1, col+7'd1} - {11'd0, cnt};
			end
			SAVE: begin
				res_wr <= 1'b1;
				res_addr <= {row, col};
				res_do <= (op < (tmp+8'd1))? op : tmp + 8'd1;
			end
			SAV0: begin
				res_wr <= 1'b1;
				res_addr <= {row, col};
				res_do <= 8'd0;
			end
		endcase
	end

//------------------------------------------------
//  done
//------------------------------------------------
always @ (posedge clk or negedge reset)
	if (!reset)
		done <= 1'b0;
	else if (state == DONE)
		done <= 1'b1;
	else
		done <= 1'b0;


endmodule
