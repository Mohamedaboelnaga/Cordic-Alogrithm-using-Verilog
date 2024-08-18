module Rotational_Cordic_tb();

parameter WORD_LENGTH = 18 ;



reg                    CLK_tb         ;
reg                    RST_tb         ;
reg                    ENABLE_tb      ; 
reg  [WORD_LENGTH-1:0] Xo_tb          ;
reg  [WORD_LENGTH-1:0] Yo_tb          ;
reg  [WORD_LENGTH-1:0] Zo_tb          ;
wire [WORD_LENGTH-1:0] XN_tb          ;
wire [WORD_LENGTH-1:0] YN_tb          ;
wire [WORD_LENGTH-1:0] ZN_tb          ;
wire                   done_signal_tb ;





Rotational_Cordic My_Rotational_Cordic (
	.CLK(CLK_tb),
	.RST(RST_tb),
	.ENABLE(ENABLE_tb),
	.Xo(Xo_tb),
	.Yo(Yo_tb),
	.Zo(Zo_tb),
	.XN(XN_tb),
	.YN(YN_tb),
	.ZN(ZN_tb),
	.Done(done_signal_tb)
	);



always #5  CLK_tb = !CLK_tb ;   // period = 10 ns



initial begin

// Initialize
	ENABLE_tb=1'b0;
	CLK_tb=1'b0;
	
	

// RST
	RST_tb=1'b1;
	@(posedge CLK_tb)
	RST_tb=1'b0;
	@(posedge CLK_tb)
	RST_tb=1'b1;


// First Trial
	@(posedge CLK_tb)
     ENABLE_tb=1'b1;
	Xo_tb=18'b000001_0000_0000_0000; // 1
	Yo_tb=18'b000010_0000_0000_0000; // 2
	Zo_tb='h01921;// pi/2
	@(posedge CLK_tb)
     ENABLE_tb=1'b0;
     
	 @(done_signal_tb);
	 
	 
	 // Second Trial
	 @(posedge CLK_tb)
     ENABLE_tb=1'b1;
	Xo_tb=18'b000011_0000_0000_0000; // 3
	Yo_tb=18'b000100_0000_0000_0000; // 4
	Zo_tb='h3e6de;//- pi/2
	@(posedge CLK_tb)
     ENABLE_tb=1'b0;
     
	 @(done_signal_tb);
     
	 // Third Trial
	 @(posedge CLK_tb)
     ENABLE_tb=1'b1;
	Xo_tb=18'b111101000000000000; // -3
	Yo_tb=18'b000100_0000_0000_0000; // 4
	Zo_tb='h3e6de;//- pi/2
	@(posedge CLK_tb)
     ENABLE_tb=1'b0;
     
	 @(done_signal_tb);
     
     
     // Fourth Trial
	 @(posedge CLK_tb)
     ENABLE_tb=1'b1;
	Xo_tb=18'b000011_0000_0000_0000; // 3
	Yo_tb=18'b111100000000000000; // -4
	Zo_tb='h3e6de;//- pi/2
	@(posedge CLK_tb)
     ENABLE_tb=1'b0;
     
	 @(done_signal_tb);
     
	
	 // Fifth Trial
	 @(posedge CLK_tb)
     ENABLE_tb=1'b1; 
    Xo_tb=18'b111101000000000000; // -3
	Yo_tb=18'b111100000000000000; // -4
	Zo_tb='h01921;// pi/2
	@(posedge CLK_tb)
     ENABLE_tb=1'b0;
     
	 @(done_signal_tb);

	 #50;
	 $stop;

end
endmodule