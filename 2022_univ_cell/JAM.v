`include 	"./dictionary_v2.v"
`include 	"./sum.v"
module JAM (
input CLK,
input RST,
output  [2:0] W,
output  [2:0] J,
input [6:0] Cost,
output  [3:0] MatchCount,
output  [9:0] MinCost,  
output  Valid  );

wire			next, finish;
wire	[2:0]	A, B, C, D, E, F, G, H;

dictionary  d1 (CLK, RST, next, A, B, C, D, E, F, G, H, finish);

sum 		s1 (CLK, RST, finish, A, B, C, D, E, F, G, H, Cost, W, J, next, MatchCount, MinCost, Valid);

endmodule