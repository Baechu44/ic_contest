module SET ( clk , rst, en, central, radius, mode, busy, valid, candidate );

input           clk, rst;
input           en;
input   [23:0]  central;
input   [11:0]  radius;
input   [1:0]   mode;
output          busy;
output          valid;
output  [7:0]   candidate;


reg     [3:0]   x1, y1, x2, y2, x3, y3;
reg     [3:0]   r1, r2, r3;
reg     [1:0]   m;//mode

reg     [1:0]   state, next_state;
reg     [3:0]   row, col, next_row, next_col;
//reg     [7:0]   cnt, next_cnt;
reg             flag;
reg             busy, next_busy;
reg             valid, next_valid;
reg     [7:0]   candidate, next_candidate;

wire            is_inside_1, is_inside_2, is_inside_3;
wire    [7:0]   tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7, tmp8, tmp9;


//-------------------------------------------
// FSM
//-------------------------------------------
parameter   IDLE = 2'd0,
            SCAN = 2'd1,
            DONE = 2'd2;

always @ (posedge clk or posedge rst)
    if (rst)
        state <= IDLE;
    else
        state <= next_state;


always @ (*) begin
    next_state = state;
    case (state)
        IDLE: next_state = en? SCAN : IDLE;
        SCAN: next_state = ((row == 4'd8) && (col == 4'd8))? DONE : SCAN;
        DONE: next_state = IDLE;
    endcase
end

//-------------------------------------------
// x1, y1, x2, y2, x3, y3, r1, r2, r3, m
//-------------------------------------------
always @ (posedge clk or posedge rst) 
    if (rst) begin
        x1 <= 4'd0;
        y1 <= 4'd0;
        r1 <= 4'd0;
        x2 <= 4'd0;
        y2 <= 4'd0;
        r2 <= 4'd0;
        x3 <= 4'd0;
        y3 <= 4'd0;
        r3 <= 4'd0;
        m  <= 2'd0;
    end else begin
        x1 <= en? central[23:20] : x1;
        y1 <= en? central[19:16] : y1;
        x2 <= en? central[15:12] : x2;
        y2 <= en? central[11:8]  : y2;
        x3 <= en? central[7:4]   : x3;
        y3 <= en? central[3:0]   : y3;
        r1 <= en? radius[11:8]   : r1;
        r2 <= en? radius[7:4]    : r2;
        r3 <= en? radius[3:0]    : r3;
        m  <= en? mode : m;
    end

//-------------------------------------------
// state: SCAN
//-------------------------------------------
always @ (posedge clk or posedge rst)
    if (rst) begin
        row <= 4'd1;
        col <= 4'd1;
        //cnt <= 8'd0;
    end else begin
        row <= next_row;
        col <= next_col;
        //cnt <= next_cnt;
    end

always @ (*) begin
    next_row = row;
    next_col = col;
    //next_cnt = cnt;
    case (state)
        IDLE: begin
            next_row = 4'd1;
            next_col = 4'd1;
            //next_cnt = 8'd0;
        end
        SCAN: begin
            next_row = (col == 4'd8)? row + 4'd1 : row;
            next_col = (col == 4'd8)? 4'd1 : col + 4'd1;
            //next_cnt = flag? cnt + 8'd1 : cnt;
        end
    endcase
end

assign is_inside_1 = ((tmp1 + tmp2) <= tmp3);//1...inside
assign tmp1 = (x1 > col)? (x1 - col)**2 : (col - x1)**2;
assign tmp2 = (y1 > row)? (y1 - row)**2 : (row - y1)**2;
assign tmp3 = r1**2;

assign is_inside_2 = ((tmp4 + tmp5) <= tmp6);//1...inside
assign tmp4 = (x2 > col)? (x2 - col)**2 : (col - x2)**2;
assign tmp5 = (y2 > row)? (y2 - row)**2 : (row - y2)**2;
assign tmp6 = r2**2;

assign is_inside_3 = ((tmp7 + tmp8) <= tmp9);//1...inside
assign tmp7 = (x3 > col)? (x3 - col)**2 : (col - x3)**2;
assign tmp8 = (y3 > row)? (y3 - row)**2 : (row - y3)**2;
assign tmp9 = r3**2;

always @ (*) begin
    flag = 1'b0;
    case (m)
        2'b00: flag = is_inside_1;
        2'b01: flag = is_inside_1 & is_inside_2;
        2'b10: flag = is_inside_1 ^ is_inside_2;
        2'b11: flag = (is_inside_1 & is_inside_2 & ~is_inside_3) | (~is_inside_1 & is_inside_2 & is_inside_3) | (is_inside_1 & ~is_inside_2 & is_inside_3);
    endcase
end

//-------------------------------------------
// busy, valid, candidate
//-------------------------------------------
always @ (posedge clk or posedge rst)
    if (rst) begin
        busy  <= 1'b0;
        valid <= 1'b0;
        candidate <= 8'd0;
    end else begin
        busy  <= next_busy;
        valid <= next_valid;
        candidate <= next_candidate;
    end

always @ (*) begin
    next_busy  = busy;
    next_valid = valid;
    next_candidate = candidate;
    case (state)
        IDLE: begin
            next_busy  = en? 1'b1 : 1'b0;
            next_valid = 1'b0;
            next_candidate = 8'd0;
        end
        SCAN: begin
            next_busy  = 1'b1;
            next_candidate = flag? candidate + 8'd1 : candidate;
        end
        DONE: begin
            next_busy  = 1'b1;
            next_valid = 1'b1;
        end
    endcase
end


endmodule


