module blink (clk,out);
    input clk;
    output reg out; // Connect out to led
    
    initial
        out = 0;

    always @(posedge clk)
        out <= ~out; 
   
endmodule
