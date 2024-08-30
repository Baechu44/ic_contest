module LASER (
input CLK,
input RST,
input [3:0] X,
input [3:0] Y,
output reg [3:0] C1X,
output reg [3:0] C1Y,
output reg [3:0] C2X,
output reg [3:0] C2Y,
output reg DONE
);

parameter           LOAD    = 0;
parameter           FIND_C1 = 1;
parameter           FIND_C2 = 2;
parameter           RE_C1   = 3;
parameter           RE_C2   = 4;
parameter           FINISH  = 5;

reg         [4:0]   state, next_state;
reg         [5:0]   cnt, next_cnt;
reg	    	[3:0]	pointX	[0:39], pointY	[0:39], next_pointX	[0:39], next_pointY	[0:39];
reg         [3:0]   next_C1X, next_C2X, next_C1Y, next_C2Y;
reg         [3:0]   ptr_x, ptr_y, next_ptr_x, next_ptr_y;
reg         [5:0]   inside_number, next_inside_number, max_number, next_max_number;
reg         [3:0]   tmp_C1X, tmp_C1Y, tmp_C2X, tmp_C2Y;
reg         [3:0]   times;

wire signed [10:0]  product, product_C1, product_C2;
wire                is_inside, is_inside_C1, is_inside_C2;

integer             i;

//--------------------------
//  FSM
//--------------------------
always @ (posedge CLK or posedge RST)
    if (RST)
        state <= LOAD;
    else
        state <= next_state;

always @ (*) begin
    next_state = state;
    case (state)
        LOAD:    next_state = (cnt == 39)? FIND_C1 : LOAD;
        FIND_C1: next_state = ((cnt == 39) && (ptr_x == 13) && (ptr_y == 13))? FIND_C2 : FIND_C1;
        FIND_C2: next_state = ((cnt == 39) && (ptr_x == 13) && (ptr_y == 13))? RE_C1   : FIND_C2;
        RE_C1:   next_state = ((cnt == 39) && (ptr_x == 13) && (ptr_y == 13))? RE_C2   : RE_C1;
        RE_C2:   next_state = ((cnt == 39) && (ptr_x == 13) && (ptr_y == 13))? ((times == 1)? FINISH : RE_C1)  : RE_C2;
        FINISH: next_state = LOAD;
    endcase
end

//--------------------------
//  Input Buffer
//--------------------------
always @ (posedge CLK or posedge RST)
	if (RST)
		for (i=0; i<40; i=i+1) begin
			pointX[i] <= 4'd0;
            pointY[i] <= 4'd0;
        end
	else
		for (i=0; i<40; i=i+1) begin
			pointX[i] <= next_pointX[i];
            pointY[i] <= next_pointY[i];
        end

always @ (*) begin
    for (i=0; i<40; i=i+1) begin
        next_pointX[i] = pointX[i];
        next_pointY[i] = pointY[i];
    end
    if (state == LOAD) begin
        next_pointX[cnt] = X;
        next_pointY[cnt] = Y;
    end
end

//--------------------------
//  Control Signal
//--------------------------
always @ (posedge CLK or posedge RST)
    if (RST)
        cnt <= 1'b0;
    else
        cnt <= (DONE)? 0 : next_cnt;

always @ (*) begin
    next_cnt = cnt;
    case (state)
        LOAD:    next_cnt = (cnt == 39)? 0 : cnt + 1;
        FIND_C1: next_cnt = (cnt == 39)? 0 : cnt + 1;
        FIND_C2: next_cnt = (cnt == 39)? 0 : cnt + 1;
        RE_C1:   next_cnt = (cnt == 39)? 0 : cnt + 1;
        RE_C2:   next_cnt = (cnt == 39)? 0 : cnt + 1;
        FINISH:  next_cnt = 0;
    endcase
end

//--------------------------
//  Output Buffer
//--------------------------
always @ (posedge CLK or posedge RST)
    if (RST) begin
        C1X <= 4'd0;
        C1Y <= 4'd0;
        C2X <= 4'd0;
        C2Y <= 4'd0;
        DONE <= 1'b0;
    end else begin
        C1X <= next_C1X;
        C1Y <= next_C1Y;
        C2X <= next_C2X;
        C2Y <= next_C2Y;
        DONE <= (state == FINISH);
    end

always @ (*) begin
    next_C1X = C1X;
    next_C1Y = C1Y;
    next_C2X = C2X;
    next_C2Y = C2Y;
    case (state)
        LOAD: begin
            next_C1X = 4'd0;
            next_C1Y = 4'd0;
            next_C2X = 4'd0;
            next_C2Y = 4'd0;
        end
        FIND_C1: begin
            next_C1X = (cnt == 39)? (((inside_number + is_inside) >= max_number)? ptr_x : C1X) : C1X;
            next_C1Y = (cnt == 39)? (((inside_number + is_inside) >= max_number)? ptr_y : C1Y) : C1Y;
        end
        FIND_C2: begin
            next_C2X = (cnt == 39)? (((inside_number + (is_inside || is_inside_C1)) >= max_number)? ptr_x : C2X) : C2X;
            next_C2Y = (cnt == 39)? (((inside_number + (is_inside || is_inside_C1)) >= max_number)? ptr_y : C2Y) : C2Y;
        end
        RE_C1: begin
            next_C1X = (cnt == 39)? (((inside_number + (is_inside || is_inside_C2)) >= max_number)? ptr_x : C1X) : C1X;
            next_C1Y = (cnt == 39)? (((inside_number + (is_inside || is_inside_C2)) >= max_number)? ptr_y : C1Y) : C1Y;
        end
        RE_C2: begin
            next_C2X = (cnt == 39)? (((inside_number + (is_inside || is_inside_C1)) >= max_number)? ptr_x : C2X) : C2X;
            next_C2Y = (cnt == 39)? (((inside_number + (is_inside || is_inside_C1)) >= max_number)? ptr_y : C2Y) : C2Y;
        end
    endcase
end

//--------------------------
//  Pointer, Counter
//--------------------------
always @ (posedge CLK or posedge RST)
    if (RST) begin
        ptr_x <= 4'd0;
        ptr_y <= 4'd0;
        //
        inside_number <= 6'd0;
        max_number <= 6'd0;
    end else begin
        ptr_x <= next_ptr_x;
        ptr_y <= next_ptr_y;
        //
        inside_number <= next_inside_number;
        max_number <= next_max_number;
    end

always @ (*) begin
    next_ptr_x = ptr_x;
    next_ptr_y = ptr_y;
    //
    next_inside_number = inside_number;
    next_max_number = max_number;
    case (state)
        LOAD, FINISH: begin
            next_ptr_x = 2;
            next_ptr_y = 2;
            next_inside_number = 0;
            next_max_number = 0;
        end
        FIND_C1: begin
            next_ptr_x = (cnt == 39)? ((ptr_x == 13)? 2 : ptr_x + 1) : ptr_x;
            next_ptr_y = (cnt == 39)? ((ptr_x == 13)? ((ptr_y == 13)? 2 : ptr_y + 1) : ptr_y) : ptr_y;
            next_inside_number = (cnt == 39)? 0 : ((is_inside)? inside_number + 1 : inside_number);
            next_max_number = ((cnt == 39) && (ptr_x == 13) && (ptr_y == 13))? 0 : ((cnt == 39)? (((inside_number + is_inside) > max_number)? inside_number + is_inside : max_number) : max_number);
        end
        FIND_C2: begin
            next_ptr_x = (cnt == 39)? ((ptr_x == 13)? 2 : ptr_x + 1) : ptr_x;
            next_ptr_y = (cnt == 39)? ((ptr_x == 13)? ((ptr_y == 13)? 2 : ptr_y + 1) : ptr_y) : ptr_y;
            next_inside_number = (cnt == 39)? 0 : ((is_inside || is_inside_C1)? inside_number + 1 : inside_number);
            next_max_number = ((cnt == 39) && (ptr_x == 13) && (ptr_y == 13))? 0 : ((cnt == 39)? (((inside_number + (is_inside || is_inside_C1)) > max_number)? inside_number + (is_inside || is_inside_C1) : max_number) : max_number);
        end
        RE_C1: begin
            next_ptr_x = (cnt == 39)? ((ptr_x == 13)? 2 : ptr_x + 1) : ptr_x;
            next_ptr_y = (cnt == 39)? ((ptr_x == 13)? ((ptr_y == 13)? 2 : ptr_y + 1) : ptr_y) : ptr_y;
            next_inside_number = (cnt == 39)? 0 : ((is_inside || is_inside_C2)? inside_number + 1 : inside_number);
            next_max_number = ((cnt == 39) && (ptr_x == 13) && (ptr_y == 13))? 0 : ((cnt == 39)? (((inside_number + (is_inside || is_inside_C2)) > max_number)? inside_number + (is_inside || is_inside_C2) : max_number) : max_number);
        end
        RE_C2: begin
            next_ptr_x = (cnt == 39)? ((ptr_x == 13)? 2 : ptr_x + 1) : ptr_x;
            next_ptr_y = (cnt == 39)? ((ptr_x == 13)? ((ptr_y == 13)? 2 : ptr_y + 1) : ptr_y) : ptr_y;
            next_inside_number = (cnt == 39)? 0 : ((is_inside || is_inside_C1)? inside_number + 1 : inside_number);
            next_max_number = ((cnt == 39) && (ptr_x == 13) && (ptr_y == 13))? 0 : ((cnt == 39)? (((inside_number + (is_inside || is_inside_C1)) > max_number)? inside_number + (is_inside || is_inside_C1) : max_number) : max_number);
        end
    endcase
end

//--------------------------
//  is_inside
//--------------------------
assign product = $signed({1'b0, ptr_x} - {1'b0, pointX[cnt]}) * $signed({1'b0, ptr_x} - {1'b0, pointX[cnt]}) + $signed({1'b0, ptr_y} - {1'b0, pointY[cnt]}) * $signed({1'b0, ptr_y} - {1'b0, pointY[cnt]});
assign product_C1 = $signed({1'b0, C1X} - {1'b0, pointX[cnt]}) * $signed({1'b0, C1X} - {1'b0, pointX[cnt]}) + $signed({1'b0, C1Y} - {1'b0, pointY[cnt]}) * $signed({1'b0, C1Y} - {1'b0, pointY[cnt]});
assign product_C2 = $signed({1'b0, C2X} - {1'b0, pointX[cnt]}) * $signed({1'b0, C2X} - {1'b0, pointX[cnt]}) + $signed({1'b0, C2Y} - {1'b0, pointY[cnt]}) * $signed({1'b0, C2Y} - {1'b0, pointY[cnt]});

assign is_inside    = ~(product > 16);
assign is_inside_C1 = ~(product_C1 > 16);
assign is_inside_C2 = ~(product_C2 > 16);

//--------------------------
//  Record C
//--------------------------
always @ (posedge CLK or posedge RST)
    if (RST) begin
        tmp_C1X <= 4'd0;
        tmp_C1Y <= 4'd0;
        tmp_C2X <= 4'd0;
        tmp_C2Y <= 4'd0;
        //
        times <= 0;
    end else begin
        tmp_C1X <= (state == FIND_C2)? C1X : tmp_C1X;
        tmp_C1Y <= (state == FIND_C2)? C1Y : tmp_C1Y;
        tmp_C2X <= (state == RE_C2)?   C2X : tmp_C2X;
        tmp_C2Y <= (state == RE_C2)?   C2Y : tmp_C2Y;
        //
        times <= (DONE)? 0 : ((cnt == 39) && (ptr_x == 13) && (ptr_y == 13) && (state == RE_C2))? times + 1 : times;
    end

endmodule


