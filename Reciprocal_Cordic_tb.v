module Reciprocal_Cordic_tb();

parameter WORD_LENGTH = 18 ;



reg                    CLK_tb     ;
reg                    RST_tb     ;
reg                    ENABLE_tb	; 
reg  [WORD_LENGTH-1:0] number_tb     ;
wire  [WORD_LENGTH-1:0] reciprocal_tb ;
wire                   done_signal_tb ;





Reciprocal_Cordic DUT (
	.CLK(CLK_tb),
	.RST(RST_tb),
	.Enable(ENABLE_tb),
	.Input(number_tb),
	.reciprocal(reciprocal_tb),
	.Valid(done_signal_tb)
);



always #5  CLK_tb = !CLK_tb ;   // period = 10 ns



initial begin

// Initialize
	ENABLE_tb=1'b0;
	CLK_tb=1'b0;
	number_tb = 'b0;
	

// RST
	RST_tb=1'b1;
	@(posedge CLK_tb)
	RST_tb=1'b0;
	@(posedge CLK_tb)
	RST_tb=1'b1;


// First Trial
	@(posedge CLK_tb)
	//#5;
     ENABLE_tb=1'b1;
	number_tb=18'b000001000000000000; // 2, FL=11
	@(posedge CLK_tb)
     ENABLE_tb=1'b0;
     
	 @(done_signal_tb);
	 #5;
	 
	 // Second Trial
	 @(posedge CLK_tb)
    // #5;
     ENABLE_tb=1'b1;
	number_tb=18'b000001100000000000; // 3, FL=11
	@(posedge CLK_tb)
     ENABLE_tb=1'b0;
     
	 @(done_signal_tb);
     #5;
	 
	 // Third Trial
	 @(posedge CLK_tb)
    // #5;
     ENABLE_tb=1'b1;
	number_tb=18'b000001101101010100; // 3.4163, FL=11
	@(posedge CLK_tb)
     ENABLE_tb=1'b0;
     
	 @(done_signal_tb);
     #5;
	

	 #20;
     
      // fourth Trial
	 @(posedge CLK_tb)
    // #5;
     ENABLE_tb=1'b1;
	number_tb=18'b000000011110110111; // 0.9644, FL =11
	@(posedge CLK_tb)
     ENABLE_tb=1'b0;
     
	 @(done_signal_tb);
	 #5;

	// Fifth Trial
	 @(posedge CLK_tb)
    // #5;
     ENABLE_tb=1'b1;
	number_tb=18'b000000001100110011; // 0.4, FL =11
	@(posedge CLK_tb)
     ENABLE_tb=1'b0;
    
	@(done_signal_tb);
	 #5;


	 // Fifth Trial
	 @(posedge CLK_tb)
    // #5;
     ENABLE_tb=1'b1;
	number_tb=18'b000000000000110010; // 0.0249, FL =11
	@(posedge CLK_tb)
     ENABLE_tb=1'b0;
    
	@(done_signal_tb);
	 #5;

	 // Sixth Trial
	 @(posedge CLK_tb)
    // #5;
     ENABLE_tb=1'b1;
	number_tb=18'b000000000001001011; // 0.0371, FL =11
	@(posedge CLK_tb)
     ENABLE_tb=1'b0;
    
	@(done_signal_tb);
	 #5;

 	// 7th Trial
	 @(posedge CLK_tb)
    // #5;
     ENABLE_tb=1'b1;
	number_tb=18'b000110011010110010; // 12.837, FL =11
	@(posedge CLK_tb)
     ENABLE_tb=1'b0;
    
	@(done_signal_tb);
	 #5;

	 // 8th Trial
	 @(posedge CLK_tb)
    // #5;
     ENABLE_tb=1'b1;
	number_tb=18'b000000010000000000; // 0.5, FL =11
	@(posedge CLK_tb)
     ENABLE_tb=1'b0;
    
	@(done_signal_tb);
	 #5;

	 #50;
	 $stop;

end
endmodule