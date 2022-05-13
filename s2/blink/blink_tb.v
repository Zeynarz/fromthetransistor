module blink_tb;

wire out;

reg clk = 0;
always #5 clk = ~clk;

blink b0 (clk,out);

initial begin
    $monitor("LED: %d",out);
    #500 $stop;
end

endmodule
