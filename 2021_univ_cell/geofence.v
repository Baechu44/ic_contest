`include 	"./load.v"
`include 	"./sort_v3.v"
`include 	"./is_inside_v2.v"

module geofence ( clk,reset,X,Y,valid,is_inside);
input clk;
input reset;
input [9:0] X;
input [9:0] Y;
output valid;
output is_inside;

wire	[19:0]	Obj, G1, G2, G3, G4, G5, G6, new_G1, new_G2, new_G3, new_G4, new_G5, new_G6;
wire			finish_load, finish_sort;


load      l1 (clk, reset, valid, X, Y, Obj, G1, G2, G3, G4, G5, G6, finish_load);

sort      s1 (clk, reset, finish_load, G1, G2, G3, G4, G5, G6, new_G1, new_G2, new_G3, new_G4, new_G5, new_G6, finish_sort);

is_inside i1 (clk, reset, finish_sort, Obj, new_G1, new_G2, new_G3, new_G4, new_G5, new_G6, valid, is_inside);

//sort s2 (clk, reset, finish_load, G1, G2, G3, G4, G5, G6, Obj, valid, is_inside);

endmodule
