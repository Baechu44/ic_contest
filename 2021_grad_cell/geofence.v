module geofence ( clk,reset,X,Y,R,valid,is_inside);
input             clk;
input             reset;
input   [9:0]     X;
input   [9:0]     Y;
input   [10:0]    R;
output            valid;
output            is_inside;
reg               valid;
reg               is_inside;
reg    [2:0]      cs, ns;
reg    [2:0]      ctr, ptr_1, ptr_2, ptr_hex_1, ptr_tri_1;
wire   [2:0]      ptr_hex_2, ptr_tri_2;
wire   [10:0]     Ax, Ay, Bx, By;
wire   [9:0]      nAx, nAy, nBx, nBy;
reg               cross_product;
wire   [19:0]     m1, m2, m3, m4;
reg    [9:0]      x  [0:5];
reg    [9:0]      y  [0:5];
reg    [10:0]     r  [0:5];
reg    [21:0]     hexagonal_area;
wire   [19:0]     c_square, area_square1, area_square2;
wire   [9:0]      c;
wire   [9:0]      area1, area2;
wire   [10:0]     a_length, b_length;
wire   [11:0]     s;
wire   [9:0]      a_fixed, b_fixed;
reg    [19:0]     triangle_area;
reg               start_a, start_c;
wire              done_c, done_a;
integer           i;


//----------------------------------------------------
//        FSM
//----------------------------------------------------
parameter   IDLE = 3'd0,
            READ = 3'd1,
            SWAP = 3'd2,
            CALC = 3'd3,
            DONE = 3'd4;
            

always @ (posedge clk or posedge reset)
  if (reset)
    cs <= READ;
  else
    cs <= ns;

always @ (*)
  case (cs)
    IDLE:     ns = READ;
    READ:     ns = (ctr == 3'd5)? SWAP : READ;
    SWAP:     ns = ((ptr_1 == 3'd4) && (ptr_2 == 3'd5))? CALC : SWAP;
    CALC:     ns = ((ptr_tri_1 == 3'd5) && (done_a))? DONE : CALC;
    DONE:     ns = IDLE;
    default:  ns = 3'dx;
  endcase


//----------------------------------------------------
//        data x, y, r
//----------------------------------------------------
always @ (posedge clk or posedge reset)
  if (reset)
    for (i=0; i<=5; i=i+1)
      begin
        x[i] <= 10'd0;
        y[i] <= 10'd0;
        r[i] <= 11'd0;
      end
  else if (cs == READ)
      begin
        x[ctr] <= X;
        y[ctr] <= Y;
        r[ctr] <= R;
      end
  else if (cs == SWAP)
      begin
        x[ptr_1] <= (cross_product == 1)? x[ptr_2] : x[ptr_1];
        x[ptr_2] <= (cross_product == 1)? x[ptr_1] : x[ptr_2];
        y[ptr_1] <= (cross_product == 1)? y[ptr_2] : y[ptr_1];
        y[ptr_2] <= (cross_product == 1)? y[ptr_1] : y[ptr_2];
        r[ptr_1] <= (cross_product == 1)? r[ptr_2] : r[ptr_1];
        r[ptr_2] <= (cross_product == 1)? r[ptr_1] : r[ptr_2];
      end
  else if (cs == CALC)
    for (i=0; i<=5; i=i+1)
      begin
        x[i] <= x[i];
        y[i] <= y[i];
        r[i] <= r[i];
      end
  else
    for (i=0; i<=5; i=i+1)
      begin
        x[i] <= 10'dx;
        y[i] <= 10'dx;
        r[i] <= 10'dx;
      end

always @ (posedge clk or posedge reset)
  if (reset)
    ctr <= 3'd0;    
  else if (cs == READ)
    ctr <= ctr + 3'd1;
  else
    ctr <= 3'd0;


//----------------------------------------------------
//        state SWAP
//----------------------------------------------------
always @ (posedge clk or posedge reset)
  if (reset)
    begin
      ptr_1 <= 3'd1;
      ptr_2 <= 3'd2;
    end
  else if (cs == SWAP)
    begin
      ptr_1 <= (ptr_2 == 3'd5)? ptr_1 + 3'd1 : ptr_1;
      ptr_2 <= (ptr_2 == 3'd5)? ptr_1 + 3'd2 : ptr_2 + 3'd1;
    end
  else
    begin
      ptr_1 <= 3'd1;
      ptr_2 <= 3'd2;
    end

//cross product
assign Ax = {1'b0, x[ptr_1]} - {1'b0, x[0]};//11 bits
assign Ay = {1'b0, y[ptr_1]} - {1'b0, y[0]};
assign Bx = {1'b0, x[ptr_2]} - {1'b0, x[0]};
assign By = {1'b0, y[ptr_2]} - {1'b0, y[0]};

assign nAx = (Ax[10])? ~Ax[9:0] + 10'd1 : Ax[9:0];//10bits
assign nAy = (Ay[10])? ~Ay[9:0] + 10'd1 : Ay[9:0];
assign nBx = (Bx[10])? ~Bx[9:0] + 10'd1 : Bx[9:0];
assign nBy = (By[10])? ~By[9:0] + 10'd1 : By[9:0];

assign m1 = nAx * nBy;//20bits
assign m2 = nBx * nAy;

always @ (*)
  case ({Ax[10] ^ By[10], Bx[10] ^ Ay[10]})
    2'b00:    cross_product = (m1 < m2);
    2'b01:    cross_product = 1'b0;
    2'b10:    cross_product = 1'b1;
    2'b11:    cross_product = (m1 > m2);
    default:  cross_product = 1'bx;
  endcase


//----------------------------------------------------
//        state CALC...triangle area vs hexagonal area
//----------------------------------------------------

//hexagonal_area 
always @ (posedge clk or posedge reset)
  if (reset)
    hexagonal_area <= 22'd0;
  else if ( (cs == CALC) && (ptr_hex_1 != 3'd6) )
    hexagonal_area <= hexagonal_area + ({1'b0, m3} - {1'b0, m4});//divide 2...not yet
  else if (cs == SWAP)
    hexagonal_area <= 22'd0;
  else
    hexagonal_area <= hexagonal_area;

assign m3 = x[ptr_hex_1] * y[ptr_hex_2];
assign m4 = x[ptr_hex_2] * y[ptr_hex_1];


always @ (posedge clk or posedge reset)
  if (reset)
    ptr_hex_1 <= 3'd0;
  else if (cs == CALC)
    ptr_hex_1 <= (ptr_hex_1 == 3'd6)? 3'd6 : ptr_hex_1 + 3'd1;
  else
    ptr_hex_1 <= 3'd0;

assign ptr_hex_2 = (ptr_hex_1 == 3'd5)? 3'd0 : ptr_hex_1 + 3'd1;


//triangle_area 
assign c_square = a_fixed * a_fixed + b_fixed * b_fixed;//get c_square
assign a_length = {1'b0, x[ptr_tri_2]} - {1'b0, x[ptr_tri_1]};//11bits
assign a_fixed  = (a_length[10])? ~a_length[9:0] + 1 : a_length[9:0];
assign b_length = {1'b0, y[ptr_tri_2]} - {1'b0, y[ptr_tri_1]};//11bits
assign b_fixed  = (b_length[10])? ~b_length[9:0] + 1 : b_length[9:0];

root_c_square u1 (clk, reset, start_c, c_square, done_c, c);

always @ (posedge clk)
  begin
    start_c <= (done_a || (ptr_1 == 3'd4));
    start_a <= (cs == CALC)? done_c : 1'b0;
  end

assign s = {({2'b0, r[ptr_tri_1]} + {2'b0, r[ptr_tri_2]} + {2'b0, c}) >> 1};//12 bits
assign area_square1 = s * (s-r[ptr_tri_1]);
assign area_square2 = (s-r[ptr_tri_2]) * (s-c);

root_c_square u2 (clk, reset, start_a, area_square1, done_a, area1);
root_c_square u3 (clk, reset, start_a, area_square2,       , area2);

//triangle
always @ (posedge clk or posedge reset)
  if (reset)
    triangle_area <= 20'd0;
  else if ( (cs == CALC) && (done_a) )
    triangle_area <= triangle_area + area1 * area2;
  else if (cs == SWAP)
    triangle_area <= 20'd0;
  else
    triangle_area <= triangle_area;

always @ (posedge clk or posedge reset)
  if (reset)
    ptr_tri_1 <= 3'd0;
  else if (done_a)
    ptr_tri_1 <= ptr_tri_1 + 3'd1;
  else if (cs == CALC)
    ptr_tri_1 <= ptr_tri_1;
  else
    ptr_tri_1 <= 3'd0;

assign ptr_tri_2 = (ptr_tri_1 == 3'd5)? 3'd0 : ptr_tri_1 + 3'd1;


//----------------------------------------------------
//        state DONE
//----------------------------------------------------
always @ (posedge clk or posedge reset)
  if (reset)
    begin
      valid <= 1'b0;
      is_inside <= 1'b0;
    end
  else if (cs == DONE)
    begin
      valid <= 1'b1;
      is_inside <= ( triangle_area < {hexagonal_area[19:0] >> 1} );
    end
  else
    begin
      valid <= 1'b0;
      is_inside <= 1'b0; 
    end

endmodule

//----------------------------------------------------
//        square
//----------------------------------------------------
module root_c_square (clk, reset, start, c_square, done, c);
input          clk;
input          reset;
input          start;
input  [19:0]  c_square;
output         done;
output [9:0]   c;
reg    [1:0]   cs, ns;
reg    [19:0]  test_point;
wire   [19:0]  comb_square;
reg    [9:0]   c, src;
wire   [9:0]   comb;
reg    [3:0]   ptr;
reg            done;

parameter   IDLE = 2'd0,
            READ = 2'd1,
            CALC = 2'd2;

always @ (posedge clk or posedge reset)
  if (reset)
    cs <= IDLE;
  else
    cs <= ns;

always @ (*)
  case (cs)
    IDLE: ns = (start)? READ : IDLE;
    READ: ns = CALC;
    CALC: ns = (ptr == 4'd0)? IDLE : CALC;
    default: ns = 2'dx;
  endcase

always @ (posedge clk or posedge reset)
  if (reset)
    test_point <= 20'd0;
  else if (cs == READ)
    test_point <= c_square;
  else
    test_point <= test_point;

always @ (posedge clk or posedge reset)
  if (reset)
    begin
      c   <= 10'd0;
      src <= 10'dx;//shift right constant
    end
  else if (cs == IDLE)
    begin
      c   <= c;
      src <= 10'dx;
    end
  else if (cs == READ)
    begin
      c   <= 10'd0;
      src <= 10'b10_0000_0000;
    end
  else if (cs == CALC)
    begin
      c[ptr] <= (test_point >= comb_square);
      src <= (src >> 1);
    end
  else
    begin
      c   <= 10'dx;
      src <= 10'dx;
    end
    
assign comb = (c | src);

assign comb_square = comb * comb;

always @ (posedge clk or posedge reset)
  if (reset)
    ptr <= 4'd9;
  else if (cs == CALC)
    ptr <= ptr - 4'd1;
  else
    ptr <= 4'd9;

always @ (posedge clk or posedge reset)
  if (reset)
    done <= 1'b0;
  else
    done <= (ptr == 4'd0);
    
endmodule
