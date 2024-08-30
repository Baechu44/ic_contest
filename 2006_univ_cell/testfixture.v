`timescale 100ps/10ps
`define CYCLE      50	// Modify your clock period here (unit: 0.1ns)
`define INFILE1    "input.dat"
`define IN_LENGTH  6
`define INFILE2    "expect.dat"
`define OUT_LENGTH 48
`ifdef GL
`define SDF_FILE   "triangle_syn.sdf"
`endif
`define End_CYCLE  800000
module test;
parameter INPUT_DATA = `INFILE1;
parameter EXPECT_DATA = `INFILE2;
parameter period = `CYCLE * 10; 
reg     clk;
reg     reset;
reg     nt;
reg     [2:0] xi, yi;

wire    [2:0] xo, yo;
wire    po;
wire    busy;


integer i, j, k, l, out_f, err, pattern_num, total_num, total_cycle_num;
integer a, b, c, d;
reg [5:0]  data_base [0:`IN_LENGTH - 1];
reg [5:0]  data_base_expect [0:`OUT_LENGTH - 1];
reg [5:0]  data_tmp_expect;
reg [5:0]  data_tmp_i1, data_tmp_i2, data_tmp_i3;




triangle top(.clk(clk), .reset(reset), .nt(nt), .xi(xi), .yi(yi), .busy(busy), .po(po), .xo(xo), .yo(yo));



`ifdef GL
initial $sdf_annotate(`SDF_FILE,top);
`endif

initial	$readmemb(INPUT_DATA,  data_base);
initial	$readmemb(EXPECT_DATA,  data_base_expect);

initial begin
  `ifdef GL
	$fsdbDumpfile("triangle_syn.fsdb");
	`else
	$fsdbDumpfile("triangle.fsdb");
	`endif
	$fsdbDumpvars;
   
   clk   = 1'b0;
   reset = 1'b0;
   nt    = 1'b0;
   xi    = 3'bz;
   yi    = 3'bz;
   l = 0;
   i = 0;
   j = 0;
   k = 0;
   err = 0;
   pattern_num = 1 ; 
   total_num = 0 ;
end

initial begin
   out_f = $fopen("OUT.DAT");
   if (out_f == 0) begin
      $display("Output file open error !");
      $finish;
   end
end

always 
   #(period/2)  clk = ~clk;

initial begin 
   @(negedge clk)  
      reset = 1'b1;
      $display ("\n****** START to VERIFY the Triangel Rendering Enginen OPERATION ******\n");
      #(period - 0.1)
         reset = 1'b0;
   
   
   for(i = 0; i < `IN_LENGTH; i = i + k) begin
      if(busy == 1'b1) begin
         @(negedge clk)
            nt =1'b0;
            k  =0;
      end else begin
         k  = 3;
         // cycle 1
         @(negedge clk)
            nt = 1'b1;      
            #(`CYCLE*3)  // read x1 & y1
               data_tmp_i1 = data_base[i];
               xi = data_tmp_i1[5:3];
               yi = data_tmp_i1[2:0];
         @(posedge clk)
            #(`CYCLE*2)  // close x1 & y1 
               xi = 3'bz; 
               yi = 3'bz; 
         // cycle 2
         @(negedge clk)
            nt =1'b0;      
            #(`CYCLE*3)  // read x2 & y2
               data_tmp_i2 = data_base[i+1];
               xi = data_tmp_i2[5:3];
               yi = data_tmp_i2[2:0];
         @(posedge clk)
            #(`CYCLE*2)  // close x2 & y2 
               xi = 3'bz; 
               yi = 3'bz;
         // cycle 3
         @(negedge clk)
            #(`CYCLE*3)  // read x3 & y3
               data_tmp_i3 = data_base[i+2];
               xi = data_tmp_i3[5:3];
               yi = data_tmp_i3[2:0];
         @(posedge clk)
            #(`CYCLE*2)  // close x3 & y3 
               xi = 3'bz; 
               yi = 3'bz;
         
         $display("Waiting for the rendering operation of the triangle points with:"); 
         $display("(x1, y1)=(%h, %h)",data_tmp_i1[5:3], data_tmp_i1[2:0]); 
         $display("(x2, y2)=(%h, %h)",data_tmp_i2[5:3], data_tmp_i2[2:0]); 
         $display("(x3, y3)=(%h, %h)",data_tmp_i3[5:3], data_tmp_i3[2:0]); 
      end
   end
end 

always @(posedge clk) begin
   if (po ==1'b1) begin 
      data_tmp_expect = data_base_expect[l]; 
      if ((xo !== data_tmp_expect[5:3])|| (yo!== data_tmp_expect[2:0])) begin
         $display("ERROR at %d:xo=(%h) yo=(%h)!=expect xo=(%h), yo=(%h)",l 
         ,xo, yo, data_tmp_expect[5:3], data_tmp_expect[2:0]);
         err = err + 1 ;   
      end
      $fdisplay(out_f,"%h%h",xo,yo); 
      l = l + 1;
   end
    
   if( l == `OUT_LENGTH ) begin
      if (err == 0)
         $display("PASS! All data have been generated successfully!");
      else begin
         $display("---------------------------------------------");
         $display("There are %d errors!", err);
         $display("---------------------------------------------");
      end
      $display("---------------------------------------------");
      total_num = total_cycle_num * period; 
      $display("Total delay: %d ns", total_num );
      $display("---------------------------------------------");
      $finish;
   end
end

always @(posedge clk) begin
   if (reset == 1'b1) 
      total_cycle_num = 0 ;
   else 
      total_cycle_num = total_cycle_num + 1 ;
end 
initial  begin
 #`End_CYCLE ;
 	$display("-----------------------------------------------------\n");
 	$display("Error!!! The simulation can't be terminated under normal operation!\n");
 	$display("-------------------------FAIL------------------------\n");
 	$display("-----------------------------------------------------\n");
 	$finish;
end
endmodule
