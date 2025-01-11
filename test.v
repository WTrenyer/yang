module test;


reg   clk;
reg   rst_n;
wire [15:0] led;
 
 led_cercle uut(
    .clk(clk),
    .rst_n(rst_n),
    .led(led) 
 );


    initial 
        begin
                $dumpfile("top.vcd");
                $dumpvars(0,uut);
           clk=1'b1;
           rst_n<=1'b0;
           #20
           rst_n<=1'b1;
		#100000
	$finish;
        end
always#10  clk<=~clk;



endmodule