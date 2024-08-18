// File : vector_cordic.v
// Author :
// Date : 28/4/2024
// Version : 1
// Abstract : this file contains a fixed-point implementation of vector_cordic used in QR decomposition
// 

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////// Module ports list, declaration, and data type ///////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

module vector_cordic #(
        parameter NUMBER_OF_ITERATIONS = 7,
        parameter INT_WIDTH = 6,
        parameter FRACT_WIDTH = 12,
        parameter DATA_WIDTH = INT_WIDTH + FRACT_WIDTH
    )(
        ///////////////////////////// Inputs /////////////////////////////
        input   wire                           clk,
        input   wire                           rst_n,
        input   wire                           vector_cordic_enable,
        input   wire signed [DATA_WIDTH-1 : 0] input_1,
        input   wire signed [DATA_WIDTH-1 : 0] input_2,
        
        ///////////////////////////// Outputs /////////////////////////////
        output  reg                            vector_cordic_valid,
        output  reg  signed [DATA_WIDTH-1 : 0] ouput_mag,
        output  reg  signed [DATA_WIDTH-1 : 0] output_angle
    );
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////             Constants            ///////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // pi in radian
    localparam PI = 'b000011_001001000011; // pi with integer part = 6 && fraction part = 12
    
    // Number of Quadriants is 4
    localparam NUM_OF_QUADRANTS = 'd4;
    
    // Scaling
    // since we will work with Number of iterations = 7 --> therefore scaling = 0.6073
    localparam SCALING = 'b000000_100110110111; // scaling with integer part = 6 && fraction part = 12
    
    //////////////////////////////////////// arctan memory //////////////////////////////////////// 
    // WIDTH = DATA_WIDTH
    // DEPTH = Number_of_Iterations
    reg [DATA_WIDTH-1 : 0] arctan_mem [0 : NUMBER_OF_ITERATIONS-1];
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////// Signals and Internal Connections ///////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    
    //////////////////////////// Operands ////////////////////////////
    // Operands of CORDIC
    reg signed [DATA_WIDTH-1 : 0] opr_1_reg;
    reg signed [DATA_WIDTH-1 : 0] opr_2_reg;
    
    // Shifted operands
    wire signed [DATA_WIDTH-1 : 0] opr_1_shifted_wire;
    wire signed [DATA_WIDTH-1 : 0] opr_2_shifted_wire;
    
    // Multiply Operand 1 by Scaling
    wire    signed      [DATA_WIDTH*2-1 : 0]      output_mag_long;
    wire    signed      [DATA_WIDTH-1 : 0]        output_mag_short;
    
    //////////////////////////// Quadriant Value ////////////////////////////
    // To determine quadriant where we are
    wire [$clog2(NUM_OF_QUADRANTS)-1 : 0] quadr_wire;
    
    //////////////////////////// Enable register ////////////////////////////
    // Used to instialize operands of CORDIC
    reg vector_cordic_enable_reg;
    
    //////////////////////////// Done Signals ////////////////////////////
    // Used to determine whether CORDIC finished or not
    wire done_wire;
    
    //////////////////////////// Counter register ////////////////////////////
    reg [$clog2(NUMBER_OF_ITERATIONS)-1 : 0] count_reg;
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////// Sequential Logic //////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    
    always@(posedge clk or negedge rst_n)
    begin
        // if reset clear the registers
        if (!rst_n)
        begin
            // Clear outputs
            ouput_mag    <= 'b0;
            output_angle <= 'b0;
            vector_cordic_valid <= 'b0;
            
            // Clear CORDIC operands
            opr_1_reg <= 'b0;
            opr_2_reg <= 'b0;
            
            // Clear enable register
            vector_cordic_enable_reg <= 'b0;
            
            // Clear counter register
            count_reg <= 'b0;
            
            //////////////////////////////////////// arctan memory ////////////////////////////////////////
            arctan_mem[0] <= 'b000000_110010010000; // value of arctan with integer part = 6 && fraction part = 12
            arctan_mem[1] <= 'b000000_011101101011; // value of arctan with integer part = 6 && fraction part = 12
            arctan_mem[2] <= 'b000000_001111101011; // value of arctan with integer part = 6 && fraction part = 12
            arctan_mem[3] <= 'b000000_000111111101; // value of arctan with integer part = 6 && fraction part = 12
            arctan_mem[4] <= 'b000000_000011111111; // value of arctan with integer part = 6 && fraction part = 12
            arctan_mem[5] <= 'b000000_000001111111; // value of arctan with integer part = 6 && fraction part = 12
            arctan_mem[6] <= 'b000000_000000111111; // value of arctan with integer part = 6 && fraction part = 12
        end
        else
        begin
            
            // Store Old value of Enable signal
            vector_cordic_enable_reg <= vector_cordic_enable;
            
            // initailizations for CORDIC
            if (vector_cordic_enable && (!vector_cordic_enable_reg))
            begin
                
                // Clear counter
                count_reg <= 'b0;
                
                // operand 2 = input 2
                opr_2_reg <= input_2;
                
                // Clear outputs
                ouput_mag <= 'b0;
                output_angle <= 'b0;
                vector_cordic_valid <= 'b0;
                
                // If input 1 is negative
                if(input_1[DATA_WIDTH-1])
                begin
                    
                    // operand 1 equals -ve input 1
                    opr_1_reg <= -input_1;
                end
                // else input 1 is positive
                else begin
                    
                    // operand 1 equal input 1
                    opr_1_reg <= input_1;
                end
            end
            
            // CORDIC Operation
            if(vector_cordic_enable_reg && (count_reg != NUMBER_OF_ITERATIONS))
            begin
                
                // Increment counter
                count_reg <= count_reg + 'b1;
                
                // determine direction from sign of operand 2
                /*
                    if Operand 2 is -ve:
                        operand 1 = operand 1 - operand 2 * 2^(-i)
                        operand 2 = operand 2 + operand 1 * 2^(-i)
                        angle = angle - atan(2^(-i))
                */
                if (opr_2_reg[DATA_WIDTH-1])
                begin
                    
                    // Operand 1
                    opr_1_reg <= opr_1_reg - opr_2_shifted_wire;
                    
                    // Operand 2
                    opr_2_reg <= opr_2_reg + opr_1_shifted_wire;
                    
                    // Angle
                    output_angle <= output_angle - arctan_mem[count_reg];
                end
                /*
                    if Operand 2 is +ve:
                        operand 1 = operand 1 + operand 2 * 2^(-i)
                        operand 2 = operand 2 - operand 1 * 2^(-i)
                        angle = angle + atan(2^(-i))
                */
                else
                begin
                    
                    // Operand 1
                    opr_1_reg <= opr_1_reg + opr_2_shifted_wire;
                    
                    // Operand 2
                    opr_2_reg <= opr_2_reg - opr_1_shifted_wire;
                    
                    // Angle
                    output_angle <= output_angle + arctan_mem[count_reg];
                end
                
            end
            
            /*
                If done_wire == 1
                    1) Set Valid Signal
                    2) multply operand 1 by scale to get output magnitude
                    3) determine the quadriant to determine final value of ceta
            */
            if(done_wire && !(vector_cordic_valid))
            begin
                
                // Set output done signal
                vector_cordic_valid <= 'b1;
                
                // Multply the magnitude by scaling
                ouput_mag <= output_mag_short;
                
                // Determine Which quadriant using Case statement
                /*
                    Quadriant where we are:
                        if x is +ve and y +ve ---> 1st quadriant ---> quadr_wire = 'b00
                        if x is -ve and y +ve ---> 2nd quadriant ---> quadr_wire = 'b10
                        if x is -ve and y -ve ---> 3rd quadriant ---> quadr_wire = 'b11
                        if x is +ve and y -ve ---> 4th quadriant ---> quadr_wire = 'b01
                */
                case (quadr_wire)
                    
                    // If we are at 3rd quadriant
                    'b11:
                    begin
                        
                        // Ceta = -(pi + Ceta)
                        output_angle <= -(PI + output_angle);
                    end
                    // If we are at 2nd quadriant
                    'b10:
                    begin
                        
                        // Ceta = (pi - Ceta)
                        output_angle <= PI - output_angle;
                    end
                    // If we are 1st or 4th quadriant
                    default:
                    begin
                        
                        // Ceta = Ceta
                        output_angle <= output_angle;
                    end
                endcase
            end
        end
    end
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////// Combinational Logic ////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    
    //////////////////////////// Done Wire ////////////////////////////
    // Rise done signal if counter == Number of iterations
    assign done_wire = (count_reg == NUMBER_OF_ITERATIONS)? 'b1 : 'b0;
    
    //////////////////////////// Shifting the operands ////////////////////////////
    assign opr_1_shifted_wire = opr_1_reg >>> count_reg;
    assign opr_2_shifted_wire = opr_2_reg >>> count_reg;
    
    //////////////////////////// Multiplying Operand 1 by scaling ////////////////////////////
    assign output_mag_long = opr_1_reg * SCALING;
    assign output_mag_short = output_mag_long >>> FRACT_WIDTH;
    
    //////////////////////////// Quadriant Wire ////////////////////////////
    /*
        Quadriant where we are:
            if x is +ve and y +ve ---> 1st quadriant ---> quadr_wire = 'b00
            if x is -ve and y +ve ---> 2nd quadriant ---> quadr_wire = 'b10
            if x is -ve and y -ve ---> 3rd quadriant ---> quadr_wire = 'b11
            if x is +ve and y -ve ---> 4th quadriant ---> quadr_wire = 'b01
    */
    assign quadr_wire = {input_1[DATA_WIDTH-1], input_2[DATA_WIDTH-1]};
    
endmodule
