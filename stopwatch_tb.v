`timescale 1us/1us
module top;

reg [3:0]PSW,RSW;
reg CLK,RSTn;

wire [7:0]SEG_A, SEG_B, SEG_C, SEG_D,LED;

parameter STEP = 1000;

stopwatch stopwatch(CLK, RSTn, PSW, RSW, SEG_A, SEG_B, SEG_C, SEG_D, LED);
always #(STEP/2) CLK =~CLK;

initial begin
			CLK = 0;RSW=4'b0000; RSTn = 0;
	#(STEP)			RSTn = 1;
	#(STEP)			PSW=4'b1000;
	#(STEP*20)		RSTn = 0;
	#(STEP)			RSTn = 1;
	#(STEP)			PSW=4'b1000;
	#(STEP*100)		PSW=4'b0100;
	#(STEP)			PSW=4'b0010;
	#(STEP*2)		$finish;
end

initial $monitor( $stime, " SEG_A=%b SEG_B=%b SEG_C=%b SEG_D=%b LED=%b ", SEG_A, SEG_B, SEG_C, SEG_D, LED);

endmodule
