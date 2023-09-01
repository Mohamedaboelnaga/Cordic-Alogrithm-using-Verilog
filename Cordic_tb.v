`timescale 1 ns/100 ps

module My_Cordic_tb();

parameter input_width=16;
parameter angle_width=32;
localparam input_value= 32000/1.647;

reg [angle_width -1 :0] angle_tb;
reg [input_width -1:0] Xin_tb,Yin_tb;
reg                    CLK_tb;
wire [input_width :0] Xout_tb,Yout_tb;

reg start;
reg signed [63:0] count_angle;

initial begin
	start=1'b0;
	$display("Simulation Started");
	CLK_tb=1'b0;
	angle_tb=0;
	Xin_tb=input_value;
	Yin_tb=0;

#1000
@(posedge CLK_tb)
start=1'b1;
for(count_angle=0;count_angle<360;count_angle=count_angle+1)begin
    @(posedge CLK_tb)
	start=1'b0;
	angle_tb=((1<<32)*count_angle)/360;
	$display("angle = %d , %d",angle_tb,count_angle);
end

#500;
$display("Simulation Stopped");
$finish;
end


always #5  CLK_tb = !CLK_tb ;   // period = 10 ns


My_Cordic My_cordic_DUT (
	.CLK(CLK_tb),
	.angle(angle_tb),
	.X_in(Xin_tb),
	.Y_in(Yin_tb),
	.X_out(Xout_tb),
	.Y_out(Yout_tb)
	);

endmodule