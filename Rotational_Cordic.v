module Rotational_Cordic #( 
	parameter 	INT_LENGTH			  =	5, 
	parameter	  FRAC_LENGTH		  =	12,
	parameter 	NUM_OF_ITERATIONS	  =	12
)  (

///////////////////// Inputs /////////////////////////////////

input  wire                                          CLK,
input  wire                                          RST,
input  wire                                          ENABLE,
input  wire signed  [INT_LENGTH+FRAC_LENGTH-1:0]	   Xo,
input  wire signed  [INT_LENGTH+FRAC_LENGTH-1:0]	   Yo,
input  wire signed  [INT_LENGTH+FRAC_LENGTH-1:0]	   Zo,

///////////////////// Outputs ////////////////////////////////

output reg 	signed  [INT_LENGTH+FRAC_LENGTH-1:0]	   XN,
output reg 	signed  [INT_LENGTH+FRAC_LENGTH-1:0]	   YN,
output reg  signed  [INT_LENGTH+FRAC_LENGTH-1:0]	   ZN,
output reg                                           Done

);




//////////////////////////////////////////////////////////////
////////////////////////  Parameters /////////////////////////
//////////////////////////////////////////////////////////////

localparam WORD_LENGTH = INT_LENGTH + FRAC_LENGTH ;

// Fixed Variables from Matlab
// vary according to wordlength
// Example with wordlength 17 : 12 - 5 
wire signed [WORD_LENGTH-1:0] two_pi                = 'h06487 ;
wire signed [WORD_LENGTH-1:0] minus_two_pi          = 'h19b78 ;
wire signed [WORD_LENGTH-1:0] pi_f                  = 'h03243 ;
wire signed [WORD_LENGTH-1:0] minus_pi              = 'h1cdbc ;
wire signed [WORD_LENGTH-1:0] half_pi               = 'h01921 ;
wire signed [WORD_LENGTH-1:0] minus_half_pi         = 'h1e6de ;
wire signed [WORD_LENGTH-1:0] three_pi_over_2       = 'h04b65 ;
wire signed [WORD_LENGTH-1:0] minus_three_pi_over_2 = 'h1b49a ;
wire signed [WORD_LENGTH-1:0] Scaling               = 'h009b7 ;


//////////////////////////////////////////////////////////////
/////////////////////  Internal Signals  /////////////////////
//////////////////////////////////////////////////////////////


// Store Zo Input
//reg  signed [WORD_LENGTH-1:0] z_n ;
// Registers for temporary x and y and z (overwritten each iteration)
reg signed [WORD_LENGTH-1:0] x_n_reg ;
reg signed [WORD_LENGTH-1:0] y_n_reg ;
reg signed [WORD_LENGTH-1:0] z_n_reg ;
// Temporary outputs Scaled before truncation      
wire signed [2*WORD_LENGTH-1:0] XN_double  ;
wire signed [2*WORD_LENGTH-1:0] YN_double  ;
// Shifted Variables
wire signed	[WORD_LENGTH-1:0] x_shifted ;
wire signed	[WORD_LENGTH-1:0] y_shifted ;
// Counter number of iterations
reg [$clog2(NUM_OF_ITERATIONS):0] Count_iterations_reg;

// enable flag
reg flag_reg;




//////////////////////////////////////////////////////////////
//////////////////////////  LUT  /////////////////////////////
//////////////////////////////////////////////////////////////



// LUT of arctan *For WL=17 : 12 -5 *
reg signed  [WORD_LENGTH-1:0]    arctan_LUT    [NUM_OF_ITERATIONS - 1:0];
integer i;


// LUT Initialization
always @(posedge CLK or negedge RST) begin
	if (!RST) begin
		// reset
		for ( i = 0 ; i <= (NUM_OF_ITERATIONS - 1) ; i = i + 1 ) begin
        	arctan_LUT [i] <= 'b0;
    	end 
	end
	else begin
		arctan_LUT[0]  <= 'b00000110010010000 ;
		arctan_LUT[1]  <= 'b00000011101101011 ;
		arctan_LUT[2]  <= 'b00000001111101011 ;
		arctan_LUT[3]  <= 'b00000000111111101 ;
		arctan_LUT[4]  <= 'b00000000011111111 ;
		arctan_LUT[5]  <= 'b00000000001111111 ;
		arctan_LUT[6]  <= 'b00000000000111111 ;
		arctan_LUT[7]  <= 'b00000000000011111 ;
		arctan_LUT[8]  <= 'b00000000000001111 ;
		arctan_LUT[9]  <= 'b00000000000000111 ;
		arctan_LUT[10] <= 'b00000000000000011 ;
		arctan_LUT[11] <= 'b00000000000000001 ;
	end
end




//////////////////////////////////////////////////////////////
/////////////////  Quadrant Correction  //////////////////////
//////////////////////////////////////////////////////////////

/*
always@(*)begin

     if(Zo	>=	two_pi)    begin
      	z_n = Zo - two_pi ;
      end        
      else if(Zo <= minus_two_pi) begin
      	z_n = Zo + two_pi ;
      end
	  else if(Zo > (minus_two_pi) && Zo < (minus_three_pi_over_2))	begin
      	z_n = Zo + two_pi;
	  end
	  else if(Zo >= (minus_three_pi_over_2) && Zo < (minus_half_pi)) begin
	  	z_n = Zo + pi;
	  end
	  else if(Zo > (half_pi) && Zo <= (three_pi_over_2)) begin
		z_n = Zo - pi;       
	  end
	  else if(Zo > (three_pi_over_2) && Zo <= (two_pi)) begin
		z_n = Zo - two_pi;            
	  end
	  else if(Zo >= (minus_half_pi) && Zo <= (half_pi)) begin
	  	z_n = Zo;
	  end
	  else begin 
	    z_n = Zo;
	  end
	    
end
*/



//////////////////////////////////////////////////////////////
///////////////////  CORDIC Iterations  //////////////////////
//////////////////////////////////////////////////////////////

always @(posedge CLK or negedge RST)
 begin
	if (!RST) begin
		x_n_reg 	<= 'b0;
		y_n_reg		<= 'b0;
		z_n_reg 	<= 'b0;
		flag_reg	<=	'b0;
		Done        <=  'b0;
		Count_iterations_reg <= 0;
	end

	else begin 
	
		if(ENABLE) begin
			x_n_reg 	<= 	Xo;
			y_n_reg 	<= 	Yo;
			flag_reg	<=	'b1;
			Done        <=  'b0;
			Count_iterations_reg <= 'b0;
			
			/*z_n_reg initial value will depend on the quadrant of the input angle*/
                  if(Zo	>=	two_pi)    begin
                    z_n_reg = Zo - two_pi ;
                  end        
                  else if(Zo <= minus_two_pi) begin
                    z_n_reg = Zo + two_pi ;
                  end
                  else if(Zo > (minus_two_pi) && Zo < (minus_three_pi_over_2))	begin
                    z_n_reg = Zo + two_pi;
                  end
                  else if(Zo >= (minus_three_pi_over_2) && Zo < (minus_half_pi)) begin
                    z_n_reg = Zo + pi_f;
                  end
                  else if(Zo > (half_pi) && Zo <= (three_pi_over_2)) begin
                    z_n_reg = Zo - pi_f;       
                  end
                  else if(Zo > (three_pi_over_2) && Zo <= (two_pi)) begin
                    z_n_reg = Zo - two_pi;            
                  end
                  else if(Zo >= (minus_half_pi) && Zo <= (half_pi)) begin
                    z_n_reg = Zo;
                  end
                  else begin 
                    z_n_reg = Zo;
                  end
                  
		end


	   	else if( flag_reg == 'b1 ) begin  // flag_reg is high aslong as iterations are counting
               
			if (z_n_reg[WORD_LENGTH-1])  begin
			      x_n_reg <= x_n_reg + y_shifted ;
			      y_n_reg <= y_n_reg - x_shifted ;
			      z_n_reg <= z_n_reg + arctan_LUT[Count_iterations_reg] ;
			end
			else begin
			      x_n_reg <= x_n_reg - y_shifted ;
			      y_n_reg <= y_n_reg + x_shifted ;
			      z_n_reg <= z_n_reg - arctan_LUT[Count_iterations_reg] ;		   	
			end

			if(Count_iterations_reg	==	(NUM_OF_ITERATIONS)) begin
			    flag_reg	 <=	'b0;
			    Done         <= 'b1;    // Done is high when iterations are finished,and at that time you can take the correct output
			 // x_n_reg      <= 'b0;
			 // y_n_reg      <= 'b0;
			    z_n_reg      <= 'b0;
			 // Count_iterations_reg <='b0;
			end
			else begin
			    Count_iterations_reg <=  Count_iterations_reg + 1'b1 ;
			    Done                 <=  'b0;
			    flag_reg	         <=	 'b1;
			end
	    end

	   else begin
			flag_reg	<=	'b0;
			x_n_reg 	<= 	'b0;
			y_n_reg		<= 	'b0;
			z_n_reg 	<= 	'b0;
			Done        <=  'b0;
			Count_iterations_reg	<=	'b0;
			
	    end
	     	
	end
end

//////////////////////////////////////////////////////////////
///////////////  Cosntant Output  Flag ///////////////////////
//////////////////////////////////////////////////////////////

//This flag is responsible to make the output bus steady on the value it reached when counter reached max no. of iterations
assign before_end=(Count_iterations_reg==(NUM_OF_ITERATIONS))? 1'b1:1'b0;

//////////////////////////////////////////////////////////////
///////////////  Shifting CORDIC Operands  ///////////////////
//////////////////////////////////////////////////////////////

assign x_shifted = x_n_reg >>> Count_iterations_reg;
assign y_shifted = y_n_reg >>> Count_iterations_reg;



//////////////////////////////////////////////////////////////
//////  Outputs Scalling and Quadrants Sign Correction  //////
//////////////////////////////////////////////////////////////

// After Scaling
assign XN_double = x_n_reg * Scaling ;
assign YN_double = y_n_reg * Scaling ;




// Correction of Output Sign of Yn , Xn
// Truncation happens here alsp ( shifting with fractional size)
// Output is zero until done comes then output is steady as this value till new enable comes
always@(posedge CLK,negedge RST)begin
    if(!RST) begin
        XN <= 'b0;
        YN <= 'b0;
        ZN <= 'b0;
    end
	else if(before_end && !Done)  begin
	
	    ZN <= z_n_reg;
	    if(Zo >= (minus_three_pi_over_2) && Zo < (minus_half_pi))
	    begin
	    	XN <= - XN_double[WORD_LENGTH+FRAC_LENGTH-1:FRAC_LENGTH];
	    	YN <= - YN_double[WORD_LENGTH+FRAC_LENGTH-1:FRAC_LENGTH];
	    end
	    else if(Zo > (half_pi) && Zo <= (three_pi_over_2))
	    begin
	    	XN <= - XN_double[WORD_LENGTH+FRAC_LENGTH-1:FRAC_LENGTH];
	    	YN <= - YN_double[WORD_LENGTH+FRAC_LENGTH-1:FRAC_LENGTH];		         
	    end
	    else if(Zo >= (minus_half_pi) && Zo <= (half_pi)) begin
	    	XN <= XN_double[WORD_LENGTH+FRAC_LENGTH-1:FRAC_LENGTH];
	    	YN <= YN_double[WORD_LENGTH+FRAC_LENGTH-1:FRAC_LENGTH];	
        end
	    else begin
	    	XN <= XN_double[WORD_LENGTH+FRAC_LENGTH-1:FRAC_LENGTH];
	    	YN <= YN_double[WORD_LENGTH+FRAC_LENGTH-1:FRAC_LENGTH];	         	
	    end
	 end
end



endmodule