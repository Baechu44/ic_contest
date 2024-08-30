
`timescale 1ns/10ps
module LBP ( clk, reset, gray_addr, gray_req, gray_ready, gray_data, lbp_addr, lbp_valid, lbp_data, finish);
input   	            clk;
input   	            reset;
output  reg     [13:0] 	gray_addr;
output  reg       	    gray_req;
input   	            gray_ready;
input           [7:0] 	gray_data;
output  reg     [13:0] 	lbp_addr;
output  reg	            lbp_valid;
output  reg     [7:0] 	lbp_data;
output  reg 	        finish;
//====================================================================

reg             [2:0]   state;
reg             [2:0]   next_state;
reg             [6:0]   row;
reg             [6:0]   col;
reg             [3:0]   cnt;
reg             [7:0]   pixel       [0:8];
reg             [7:0]   tmp;
reg             [8:0]   ptr;  

integer                 i;   


//-----------------------------
//  FSM
//-----------------------------
parameter   IDLE = 3'd0,
            LOAD = 3'd1,
            COMP = 3'd2,
            STOR = 3'd3,
            DONE = 3'd4;

always @(posedge clk or posedge reset) begin
    if (reset)
        state <= IDLE;
    else
        state <= next_state;
end

always @ (*) begin
    next_state = IDLE;
    case (state)
        IDLE: next_state = (gray_ready)? LOAD : IDLE;
        LOAD: next_state = (cnt == 4'd9)? COMP : LOAD;
        COMP: next_state = (cnt == 4'd8)? STOR : COMP;
        STOR: next_state = ({row, col} == {7'd125, 7'd125})? DONE : LOAD;
        DONE: next_state = DONE;
    endcase
end

//-----------------------------
//  gray_addr, gray_req
//-----------------------------
always @ (posedge clk or posedge reset)
    if (reset) begin
        gray_addr <= 14'd0;
        gray_req  <= 1'b0;
    end else begin
        gray_addr <= gray_addr;
        gray_req  <= 1'b0;
        case (state)
            LOAD: begin
                gray_addr <= {row, col} + {5'd0, ptr};
                gray_req  <= 1'b1;
            end
        endcase
    end

//-----------------------------
//  row, col, cnt, pixel, ptr
//-----------------------------
always @ (posedge clk or posedge reset)
    if (reset) begin
        row <= 7'd0;
        col <= 7'd0;
        cnt <= 4'd0;
        for (i=0; i<9; i=i+1)
            pixel[i] <= 8'd0;
    end else begin
        row <= row;
        col <= col;
        cnt <= 4'd0;
        for (i=0; i<9; i=i+1)
            pixel[i] <= pixel[i];
        case (state)
            LOAD: begin
                cnt <= (cnt == 4'd9)? 4'd0 : cnt + 4'd1;
                pixel[cnt-1] <= gray_data;
            end
            COMP: begin
                cnt <= (cnt == 4'd3)? 4'd5 : cnt + 4'd1;
            end
            STOR: begin
                row <= (col == 7'd125)? row + 7'd1 : row;
                col <= (col == 7'd125)? 7'd0 : col + 7'd1;
            end

        endcase
    end

always @ (*) begin
    ptr = 9'dx;
    case (cnt)
        4'd0: ptr = 9'd0;
        4'd1: ptr = 9'd1;
        4'd2: ptr = 9'd2;
        4'd3: ptr = 9'd128;
        4'd4: ptr = 9'd129;
        4'd5: ptr = 9'd130;
        4'd6: ptr = 9'd256;
        4'd7: ptr = 9'd257;
        4'd8: ptr = 9'd258;
        4'd9: ptr = 9'd258;
    endcase
end

//-----------------------------
//  lbp_addr, lbp_data, lbp_valid, finish
//-----------------------------
always @ (posedge clk or posedge reset)
    if (reset) begin
        lbp_addr  <= 14'd0;
        lbp_data  <= 8'd0;
        lbp_valid <= 1'b0;
        finish    <= 1'b0;
    end else begin
        lbp_addr  <= lbp_addr;
        lbp_data  <= lbp_data;
        lbp_valid <= 1'b0;
        finish    <= 1'b0;
        case (state)
            LOAD: begin
                lbp_data <= 8'd0;
            end
            COMP: begin
                lbp_data <= (pixel[cnt] >= pixel[4])? lbp_data + tmp : lbp_data;
            end
            STOR: begin
                lbp_addr  <= {row+7'd1, col+7'd1};
                lbp_data  <= lbp_data;
                lbp_valid <= 1'b1;
            end
            DONE: begin
                finish <= 1'b1;
            end
        endcase
    end

always @ (*)
    if (cnt > 4)
        tmp = (8'd1 << (cnt-1));
    else
        tmp = (8'd1 << cnt);


//====================================================================
endmodule
