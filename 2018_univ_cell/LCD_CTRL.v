module LCD_CTRL(clk, reset, cmd, cmd_valid, IROM_Q, IROM_rd, IROM_A, IRAM_valid, IRAM_D, IRAM_A, busy, done);
input 			clk;
input 			reset;
input 	[3:0] 	cmd;
input 			cmd_valid;
input 	[7:0]	IROM_Q;
output 			IROM_rd;
output 	[5:0] 	IROM_A;
output 			IRAM_valid;
output 	[7:0] 	IRAM_D;
output 	[5:0] 	IRAM_A;
output 			busy;
output 			done;

reg		[7:0]	ImageBuffer	[0:63];

reg		[3:0]	cs, ns, cmd_save;
reg				start;

reg 			IROM_rd;
reg 	[5:0] 	IROM_A;
reg				a;
wire			finish_wait, finish_write;

integer			i, j;

reg				busy, done;

reg		[6:0]	b;
reg		[7:0]	IRAM_D;
reg				IRAM_valid;
wire	[5:0]	IRAM_A, P1, P2, P3, P4;

reg		[2:0]	op			[0:1];//0...for X 1...for Y

wire	[7:0]	ImageBuffer_max1, ImageBuffer_max2, ImageBuffer_max;
wire	[7:0]	ImageBuffer_min1, ImageBuffer_min2, ImageBuffer_min;
wire	[7:0]	ImageBuffer_average;
wire	[9:0]	ImageBuffer_total;



////////////////////////////////////////
//             FSM
////////////////////////////////////////

parameter	state_write 	= 4'h0,
			state_up		= 4'h1,
			state_down		= 4'h2,
			state_left  	= 4'h3,
			state_right 	= 4'h4,
			state_max		= 4'h5,
			state_min		= 4'h6,
			state_average	= 4'h7,
			state_cRotation	= 4'h8,
			state_Rotation	= 4'h9,
			state_mirrorX	= 4'ha,
			state_mirrorY	= 4'hb,
			state_wait		= 4'hc;

always @ (posedge clk or posedge reset)
	if (reset)
		cs <= state_wait;
	else
		cs <= ns;

always @ (*)
	if ( (cs == state_wait) && (start) )
		ns = cmd_save;
	else if (cs == state_write)
		ns = (done)? state_wait : state_write;
	else
		ns = state_wait;


//save cmd, cmd_valid
always @ (posedge clk)
	begin
		cmd_save <= (cmd_valid)? cmd : cmd_save;
		start	 <= cmd_valid;
	end
	
	
////////////////////////////////////////
//             state_wait
////////////////////////////////////////	

//IROM_rd, IROM_A
always @ (posedge clk or posedge reset)
	if (reset)
		begin
			IROM_rd 	 <= 1'b1;
			{a, IROM_A}  <= 7'b1111111;
		end
	else
		begin
			IROM_rd 	 <= (finish_wait)? 1'b0 : 1'b1;
			{a, IROM_A}  <= (finish_wait)? 7'd63 : {a, IROM_A} + 7'd1;
		end

assign finish_wait = ({a, IROM_A} == 7'd63);


////////////////////////////////////////
//             ImageBuffer
////////////////////////////////////////
always @ (posedge clk)
	if (cs == state_wait)
		ImageBuffer[IROM_A] <= (IROM_rd)? IROM_Q : ImageBuffer[IROM_A];
	else if (cs == state_max)
		begin
			ImageBuffer[P1] <= ImageBuffer_max;
			ImageBuffer[P2] <= ImageBuffer_max;
			ImageBuffer[P3] <= ImageBuffer_max;
			ImageBuffer[P4] <= ImageBuffer_max;
		end
	else if (cs == state_min)
		begin
			ImageBuffer[P1] <= ImageBuffer_min;
			ImageBuffer[P2] <= ImageBuffer_min;
			ImageBuffer[P3] <= ImageBuffer_min;
			ImageBuffer[P4] <= ImageBuffer_min;
		end
	else if (cs == state_average)
		begin
			ImageBuffer[P1] <= ImageBuffer_average;
			ImageBuffer[P2] <= ImageBuffer_average;
			ImageBuffer[P3] <= ImageBuffer_average;
			ImageBuffer[P4] <= ImageBuffer_average;
		end
	else if (cs == state_cRotation)
		begin
			ImageBuffer[P1] <= ImageBuffer[P2];
			ImageBuffer[P2] <= ImageBuffer[P4];
			ImageBuffer[P3] <= ImageBuffer[P1];
			ImageBuffer[P4] <= ImageBuffer[P3];
		end
	else if (cs == state_Rotation)
		begin
			ImageBuffer[P1] <= ImageBuffer[P3];
			ImageBuffer[P2] <= ImageBuffer[P1];
			ImageBuffer[P3] <= ImageBuffer[P4];
			ImageBuffer[P4] <= ImageBuffer[P2];
		end
	else if (cs == state_mirrorX)
		begin
			ImageBuffer[P1] <= ImageBuffer[P3];
			ImageBuffer[P2] <= ImageBuffer[P4];
			ImageBuffer[P3] <= ImageBuffer[P1];
			ImageBuffer[P4] <= ImageBuffer[P2];
		end
	else if (cs == state_mirrorY)
		begin
			ImageBuffer[P1] <= ImageBuffer[P2];
			ImageBuffer[P2] <= ImageBuffer[P1];
			ImageBuffer[P3] <= ImageBuffer[P4];
			ImageBuffer[P4] <= ImageBuffer[P3];
		end
	else
		for (i=0; i<=63; i=i+1)
			ImageBuffer[i] <= ImageBuffer[i];
		

////////////////////////////////////////
//             CNT signal
////////////////////////////////////////

always @ (posedge clk or posedge reset)
	if (reset)
		busy <= 1'b1;
	//
	else if (cmd_valid == 1'b1)
		busy <= 1'b1;
	//
	else if (cs == state_wait)
		busy <= (finish_wait)? 1'b0 : 1'b1;
	else if (cs == state_write)
		busy <= (finish_write)? 1'b0 : 1'b1;
	else 
		busy <= 1'b1;


////////////////////////////////////////
//             state_write
////////////////////////////////////////	

always @ (posedge clk)
	if (cs == state_write)
		begin
			b			<= (finish_write)? 7'd64 : b + 7'd1;
			IRAM_D 		<= ImageBuffer[b[5:0]];
			IRAM_valid	<= (finish_write)? 1'b0 : 1'b1;
			done		<= (finish_write)? 1'b1 : 1'b0;
		end
	else
		begin
			b			<= 7'd0;
			IRAM_D 		<= ImageBuffer[63];
			IRAM_valid	<= 1'b0;
			done		<= 1'b0;
		end


assign finish_write = (b == 7'd64);

assign IRAM_A = b[5:0] - 6'd1;


////////////////////////////////////////
//             op control
////////////////////////////////////////

always @ (posedge clk or posedge reset)
	if (reset)
		for(j=0; j<=1; j=j+1)//op = (4, 4)
				op[j] <= 3'd4;
	else
		case (cs)
			state_up:
				op[1] <= (op[1] == 3'd1)? 3'd1 : op[1] - 3'd1;
			state_down:
				op[1] <= (op[1] == 3'd7)? 3'd7 : op[1] + 3'd1;
			state_left:
				op[0] <= (op[0] == 3'd1)? 3'd1 : op[0] - 3'd1;
			state_right:
				op[0] <= (op[0] == 3'd7)? 3'd7 : op[0] + 3'd1;
			default:
				for(j=0; j<=1; j=j+1)
					op[j] <= op[j];
	endcase

assign P4 = {op[1], op[0]};
assign P3 = P4 - 6'd1;
assign P2 = P4 - 6'd8;
assign P1 = P4 - 6'd9;	


////////////////////////////////////////
//             state_max, state_min
////////////////////////////////////////

assign ImageBuffer_max1 = (ImageBuffer[P1] > ImageBuffer[P2])? ImageBuffer[P1] : ImageBuffer[P2];
assign ImageBuffer_max2 = (ImageBuffer[P3] > ImageBuffer[P4])? ImageBuffer[P3] : ImageBuffer[P4];
assign ImageBuffer_max  = (ImageBuffer_max1 > ImageBuffer_max2)? ImageBuffer_max1 : ImageBuffer_max2;

assign ImageBuffer_min1 = (ImageBuffer[P1] > ImageBuffer[P2])? ImageBuffer[P2] : ImageBuffer[P1];
assign ImageBuffer_min2 = (ImageBuffer[P3] > ImageBuffer[P4])? ImageBuffer[P4] : ImageBuffer[P3];
assign ImageBuffer_min  = (ImageBuffer_min1 > ImageBuffer_min2)? ImageBuffer_min2 : ImageBuffer_min1;

assign ImageBuffer_average = ImageBuffer_total[9:2];

assign ImageBuffer_total = {2'b0,ImageBuffer[P1]} + {2'b0,ImageBuffer[P2]} + {2'b0,ImageBuffer[P3]} + {2'b0,ImageBuffer[P4]};

endmodule



