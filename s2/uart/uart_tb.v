// SOURCE: https://www.csee.umbc.edu/~tinoosh/cmpe691/hw/HW2/uart_tb.v
// Made minor changes


`timescale 1ns / 1ps
//testbench for uart.v
//Loopback test (tx_out connected to rx_in)
//Sends data using tx portion of UART and wait until data is recieved


/*
Nardware or software flow control on the serial-port side. 
See: http://www.mathworks.com/help/techdoc/matlab_external/f85300.html#f85402
This uart only using a two-wire interface on the serial port side and doesn't send any extra start and stop characters:
http://www.asic-world.com/examples/verilog/uart.html
Note, start and stop bits are required as normal (false to start a frame and true to terminate one)

One the other side of the UART, the side you are interfacing to inside the FPGA, handshaking is quite necessary.

Here is some more explanation about the UART that my help:

Note:
tx refers to outgoing data
rx refers in incoming data
The RX and TX units operate essentially independently, though they packaged in one module

//This uart module does not expect a partity bit.
//It does expect the rx_in to go from true to false to start a frame
//http://en.wikipedia.org/wiki/Asynchronous_serial_communication

module uart (
reset          ,  //input  reset
txclk          ,  //input  buadrate clk
ld_tx_data     ,  //input  pulse to load data to send
tx_data        ,  //input  8bit data to send
tx_enable      ,  //input  enble for sending serial data
tx_out         ,  //output connect to serial port
tx_empty       ,  //output indicates data has been sent
rxclk          ,  //input  baudrate clk (set to be 16X faster than desired buadrate)
uld_rx_data    ,  //input  causes serial in register to copy to output rx_data
rx_data        ,  //output 8bit incoming data
rx_enable      ,  //input  enable for recieving serial data  
rx_in          ,  //input  connect to serial port
rx_empty          //output indicates no incoming data is available
);


baudrate clks:
You need to create a module to generate the baud rate clocks.  It should have a registered output to avoid any glitches.
I recommend a baudrate of 115200 Hz.
the frequency of txclk should be set equal to the baudrate
the frequency of txclk rxclk should be 16X faster than the baudrate
TODO: why? should it be like this? shouldnt they have the same baudrates

TX:
You need to use tx_empty to determine when you can load the next data to be sent.
If tx_empty is high and ld_tx_data is set high, tx_data is loaded into the serial out register and tx_empty is set low
tx_data stays low until the outgoing data is sent serially.
Thereafter, tx_data goes high and the precess may repeat

RX:
You need to use !rx_empty to determine when data is available.
When it is available, you should use uld_rx_data to have it copied to rx_data before new incoming data overwrites it.  rx_empty then goes high. 
If you don't do this fast enough, new incoming data may overwrite the serial register (you could use rx_enable to disable reading of new data, but then you are ignoring incoming data)
The process may repeat.
*/





module uart_tb;

	// Inputs
	reg reset;
	reg txclk;
	reg ld_tx_data;
	reg [7:0] tx_data;
	reg tx_enable;
	reg rxclk;
	reg uld_rx_data;
	reg rx_enable;
	reg rx_in;

	// Outputs
	wire tx_out;
	wire tx_empty;
	wire [7:0] rx_data;
	wire rx_empty;


  // uncomment lines for convenient access to internal var
  //wire [7:0] rx_reg = uut.rx_reg;
  //wire [3:0] rx_cnt = uut.rx_cnt;
  //wire [3:0] rx_sample_cnt = uut.rx_sample_cnt;
  //wire rx_d2 = uut.rx_d2;
  //wire rx_busy = uut.rx_busy;
  
	// Instantiate the Unit Under Test (UUT)
	uart uut (
		.reset(reset), 
		.txclk(clk),  // TODO: USED THE SAME CLOCKS AS rxclk, dk why need diff baudrates?
		.ld_tx_data(ld_tx_data), 
		.tx_data(tx_data), 
		.tx_enable(tx_enable), 
		.tx_out(tx_out), 
		.tx_empty(tx_empty), 
		.rxclk(clk), 
		.uld_rx_data(uld_rx_data), 
		.rx_data(rx_data), 
		.rx_enable(rx_enable), 
		.rx_in(rx_in), 
		.rx_empty(rx_empty)
	);

  //generate a master clk
  reg clk;
  //setup clocks
  initial clk=0;
  always #10 clk = ~clk;  //this speed is somewhat arbitrary for the purposes of this sim...clk should be 16X faster than desired baud rate.  I like my simulation time to match the physical system.

  //generate rxclk and txclk so that txclk is 16 times slower than rxclk
  reg [3:0] counter;
  initial begin
    rxclk=0;
    txclk=0;
    counter=0;
  end
  always @(posedge clk) begin
    counter<=counter+1;
    if (counter == 15) txclk <= ~txclk;
    rxclk<= ~rxclk;
  end

task send_n_recv (input [7:0] data);
    begin
		tx_data=data;
		#500;
        wait (tx_empty==1);  //make sure data can be sent
        ld_tx_data = 1;      //load data to send
        wait (tx_empty==0);  //wait until data loaded for send
        ld_tx_data = 0;
        wait (tx_empty==1);  //wait for flag of data to finish sending
        $display("Data sent");
        wait (rx_empty==0);  //wait for 
        $display("RX Byte Ready");
	    uld_rx_data = 1;
        wait (rx_empty==1);
        $display("RX Byte Unloaded: %b",rx_data);
        uld_rx_data = 0;
        #100;

    end
endtask

  reg [7:0] data1,data2,data3;
  
  //setup loopback
  always @ (tx_out) rx_in=tx_out;

	initial begin
		// Initialize Inputs
		reset = 1;
		ld_tx_data = 0;
		tx_data = 0;
		tx_enable = 1;
		uld_rx_data = 0;
		rx_enable = 1;
//		rx_in = 1;

		// Wait 100 ns for global reset to finish
		#500;
		reset = 0;


		// Add stimulus here 
        // Send data using tx portion of UART and wait until data is recieved
        data1 = 8'b0101_0101;
        data2 = 8'b0100_0001;
        data3 = 8'b0111_1101;

        send_n_recv(data1);
        send_n_recv(data2);
        send_n_recv(data3);
	   
    $finish;

end
      
endmodule
