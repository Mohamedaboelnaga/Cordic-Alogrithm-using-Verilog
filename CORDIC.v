module My_Cordic(CLK,angle,X_in,Y_in,X_out,Y_out);

parameter                          XY_WIDTH=16;
parameter                          angle_WIDTH=32;
parameter                          stages=16;

input                              CLK;
input signed  [angle_WIDTH-1 :0]   angle;
input signed  [XY_WIDTH-1:0]       X_in,Y_in;
output signed [XY_WIDTH:0]         X_out,Y_out;




  wire signed [31:0] atan_table [0:30];
   
   // upper 2 bits = 2'b00 which represents 0 - PI/2 range
   // upper 2 bits = 2'b01 which represents PI/2 to PI range
   // upper 2 bits = 2'b10 which represents PI to 3*PI/2 range (i.e. -PI/2 to -PI)
   // upper 2 bits = 2'b11 which represents 3*PI/2 to 2*PI range (i.e. 0 to -PI/2)
   // The upper 2 bits therefore tell us which quadrant we are in.
   assign atan_table[00] = 32'b00100000000000000000000000000000; // 45.000 degrees -> atan(2^0)
   assign atan_table[01] = 32'b00010010111001000000010100011101; // 26.565 degrees -> atan(2^-1)
   assign atan_table[02] = 32'b00001001111110110011100001011011; // 14.036 degrees -> atan(2^-2)
   assign atan_table[03] = 32'b00000101000100010001000111010100; // atan(2^-3)
   assign atan_table[04] = 32'b00000010100010110000110101000011;
   assign atan_table[05] = 32'b00000001010001011101011111100001;
   assign atan_table[06] = 32'b00000000101000101111011000011110;
   assign atan_table[07] = 32'b00000000010100010111110001010101;
   assign atan_table[08] = 32'b00000000001010001011111001010011;
   assign atan_table[09] = 32'b00000000000101000101111100101110;
   assign atan_table[10] = 32'b00000000000010100010111110011000;
   assign atan_table[11] = 32'b00000000000001010001011111001100;
   assign atan_table[12] = 32'b00000000000000101000101111100110;
   assign atan_table[13] = 32'b00000000000000010100010111110011;
   assign atan_table[14] = 32'b00000000000000001010001011111001;
   assign atan_table[15] = 32'b00000000000000000101000101111101;
   assign atan_table[16] = 32'b00000000000000000010100010111110;
   assign atan_table[17] = 32'b00000000000000000001010001011111;
   assign atan_table[18] = 32'b00000000000000000000101000101111;
   assign atan_table[19] = 32'b00000000000000000000010100011000;
   assign atan_table[20] = 32'b00000000000000000000001010001100;
   assign atan_table[21] = 32'b00000000000000000000000101000110;
   assign atan_table[22] = 32'b00000000000000000000000010100011;
   assign atan_table[23] = 32'b00000000000000000000000001010001;
   assign atan_table[24] = 32'b00000000000000000000000000101000;
   assign atan_table[25] = 32'b00000000000000000000000000010100;
   assign atan_table[26] = 32'b00000000000000000000000000001010;
   assign atan_table[27] = 32'b00000000000000000000000000000101;
   assign atan_table[28] = 32'b00000000000000000000000000000010;
   assign atan_table[29] = 32'b00000000000000000000000000000001; // atan(2^-29)
   assign atan_table[30] = 32'b00000000000000000000000000000000;



   //Now the x,y and z registers
   // we have 16 register each is 32 bit for the angle
   // we have 16 register each is 17 bit for the x and y
   //This is called pipelining where we have a set of register each iteration instead of single register
   // This can allow us to perform an operation each clock cycle , but the first operation is delayed by 16 cycles

   //stage outputs
   reg signed [XY_WIDTH :0]       X [0:stages-1];
   reg signed [XY_WIDTH :0]       Y [0:stages-1];
   reg signed [angle_WIDTH -1 :0] Z [0:stages-1]; 


      //------------------------------------------------------------------------------
   //                               stage 0
   //------------------------------------------------------------------------------
   wire[1:0] quadrant;
   assign    quadrant = angle[31:30];
   
   always @(posedge CLK)
   begin // make sure the rotation angle is in the -pi/2 to pi/2 range.  If not then pre-rotate
      case (quadrant)
         2'b00,
         2'b11:   // no pre-rotation needed for these quadrants
         begin    // X[n], Y[n] is 1 bit larger than Xin, Yin, but Verilog handles the assignments properly
            X[0] <= X_in;
            Y[0] <= Y_in;
            Z[0] <= angle;
         end
         
         2'b01:
         begin
            X[0] <= -Y_in;
            Y[0] <= X_in;
            Z[0] <= {2'b00,angle[29:0]}; // subtract pi/2 from angle for this quadrant
         end
         
         2'b10:
         begin
            X[0] <= Y_in;
            Y[0] <= -X_in;
            Z[0] <= {2'b11,angle[29:0]}; // add pi/2 to angle for this quadrant
         end
         
      endcase
   end


   //------------------------------------------------------------------------------
   //                           generate stages 1 to STG-1
   //------------------------------------------------------------------------------
   genvar i;

   generate // from 1 t0 15 because er already made stage 0
      for (i=0; i < (stages-1); i=i+1) // from 1 t0 15 because er already made stage 0
      begin:XYZ 
   	   wire direction;
   	   wire signed [XY_WIDTH:0] X_shift_right,Y_shift_right;

   	   assign X_shift_right = X[i]>>>i;
   	   assign Y_shift_right = Y[i]>>>i;
   	   assign direction=Z[i][31];//// direction = 1 if Z[i] < 0

       always @(posedge CLK) begin
       	X[i+1]<= direction ? X[i] + Y_shift_right : X[i] - Y_shift_right;
       	Y[i+1]<= direction ? Y[i] - X_shift_right : Y[i] + X_shift_right;
       	Z[i+1]<= direction ? Z[i] + atan_table[i] : Z[i] - atan_table[i];


       end
   end

   endgenerate


      //------------------------------------------------------------------------------
   //                                 output
   //------------------------------------------------------------------------------
   assign X_out = X[stages-1];
   assign Y_out = Y[stages-1];

endmodule
