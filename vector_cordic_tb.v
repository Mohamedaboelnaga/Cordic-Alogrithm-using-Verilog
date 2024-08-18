`timescale 1 ns / 1 ps

module vector_cordic_tb();
    
    parameter INT_WIDTH                 = 6;
    parameter FRACT_WIDTH               = 12;
    parameter DATA_WIDTH                = INT_WIDTH + FRACT_WIDTH;
    parameter NUM_ITERATIONS            = 7;
    
    parameter T_CLK = 2.71267;
    
    reg clk_tb;
    reg rst_n_tb;
    
    reg                           vector_cordic_enable_tb;
    reg signed [DATA_WIDTH-1 : 0] input_1_tb;
    reg signed [DATA_WIDTH-1 : 0] input_2_tb;
    
    wire                           vector_cordic_valid_tb;
    wire  signed [DATA_WIDTH-1 : 0] ouput_mag_tb;
    wire  signed [DATA_WIDTH-1 : 0] output_angle_tb;
    
    // Registers For Checking
    reg signed [DATA_WIDTH-1 : 0] expected_mag;
    reg signed [DATA_WIDTH-1 : 0] expected_angle;
    
    // Initial Block For Generating Stimulus
    initial
    begin
        $dumpfile("vector_cordic_tb.vcd");
        $dumpvars;
        initialize();
        reset();
        test();
        #100
        $stop;
    end
    
    task initialize;
        begin
            clk_tb       = 1'b0;
            rst_n_tb     = 1'b1;
            vector_cordic_enable_tb = 1'b0;
            
            @(posedge clk_tb);
        end
    endtask
    
    task reset;
        begin
            rst_n_tb = 1'b1;
            @(posedge clk_tb);
            rst_n_tb = 1'b0;
            @(posedge clk_tb);
            rst_n_tb = 1'b1;
        end
    endtask
    
    task test;
        begin
            
            @(posedge clk_tb);
            
            // Set Enable
            vector_cordic_enable_tb = 'b1;
            
            // Adjust data
            input_1_tb = 'b111101000000000000;
            input_2_tb = 'b111111100000000000;
            
            // Wait for Valid signal
            @(posedge vector_cordic_valid_tb);
            
            // Clear Enable
            @(posedge clk_tb);
            vector_cordic_enable_tb = 1'b0;
            
            expected_mag = 'b000011000010100110;
            expected_angle = 'b111101000000110101;
            check(expected_mag, expected_angle);
        end
    endtask
    
    task check;
    
        input  [DATA_WIDTH-1:0]     expected_mag;
        input  [DATA_WIDTH-1:0]     expected_angle;
        
        begin
            
            if(ouput_mag_tb != expected_mag)
            begin
                
                $display("Wrong magnitude: MATLAB = %d while VERILOG = %d", expected_mag, ouput_mag_tb);
            end
            
            if(output_angle_tb != expected_angle)
            begin
                
                $display("Wrong angle: MATLAB = %d while VERILOG = %d", expected_angle, output_angle_tb);
            end
        end
    endtask
    
    always begin
        #(T_CLK/2.0) clk_tb = ~clk_tb;
    end
    
    vector_cordic #(
        .NUMBER_OF_ITERATIONS(NUM_ITERATIONS),
        .INT_WIDTH(INT_WIDTH),
        .FRACT_WIDTH(FRACT_WIDTH)
    ) DUT (
        .clk(clk_tb),
        .rst_n(rst_n_tb),
        .vector_cordic_enable(vector_cordic_enable_tb),
        .input_1(input_1_tb),
        .input_2(input_2_tb),
        .vector_cordic_valid(vector_cordic_valid_tb),
        .ouput_mag(ouput_mag_tb),
        .output_angle(output_angle_tb)
    );
    
endmodule
