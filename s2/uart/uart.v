module uart(
    input            reset          ,  //input  reset
    input            txclk          ,  //input  buadrate clk
    input            ld_tx_data     ,  //input  pulse to load data to send
    input [7:0]      tx_data        ,  //input  8bit data to send
    input            tx_enable      ,  //input  enable for sending serial data 
    output reg       tx_out         ,  //output connect to serial port
    output reg       tx_empty       ,  //output indicates data has been sent
    input            rxclk          ,  //input  baudrate clk (set to be 16X faster than desired buadrate)
    input            uld_rx_data    ,  //input  causes serial in register to copy to output rx_data
    output reg [7:0] rx_data        ,  //output 8bit incoming data
    input            rx_enable      ,  //input  enable for recieving serial data 
    input            rx_in          ,  //input  connect to serial port
    output reg       rx_empty          //output indicates no incoming data is available
);

    always @(reset) begin
        tx_out = 1; // idle
        tx_empty = 1;
        rx_data = 0;
        rx_empty = 1;
        rcvd_data = 0;
    end
    
    // ******** TX ******** 
    
    // How to use TX:
    // Set tx_data to the byte you want to send, set ld_tx_data to 1 to load the
    // byte and start sending the byte, while sending, tx_empty will be 0 (since
    // tx contains and is sending data). After the byte is send, tx_empty will be
    // 1, and you can send the next byte
    
    // To disable data sending, set tx_enable <= 0

    reg [3:0] i,j;

    // output/send data
    always @(posedge ld_tx_data) begin
        if (tx_enable) begin
            tx_empty <= 0;

            // start bit
            @(posedge txclk);
            tx_out <= 0;

            for (i=0;i<8;i++) begin
                @(posedge txclk);
                tx_out <= tx_data[i];
            end

            // stop bit and idle 
            @(posedge txclk);
            tx_out <= 1; 

        end else begin
            $display("DATA SENDING IS NOT ENABLED");
        end

        tx_empty <= 1;
    end



    // ******** RX ******** 
    
    // How to use RX:
    // Check when rx_empty is 0, because it means that data is available (stored in rcvd_data register)/
    // Quickly set uld_rx_data from 0 to 1 to copy the data from rcvd_data to rx_data, rcvd_data will now
    // become 0, rx_empty will be set to 1, and you can read the byte by checking the rx_data output
    // If this isn't done fast enough, new incoming data might overwrite rcvd_data (either a few bits or
    // the whole thing)
    
    // Set rx_enable to 0 to disable data reading (stop reading into rcvd_data etc)

    reg [7:0] rcvd_data; 
    reg idle;

    initial 
        idle = 1;
    
    always @(posedge rxclk && idle == 1) begin
        // start bit
        // don't know if there is a better way to do this, but found timing issues
        // between the rx and tx clks in certain cases if @(negedge rx_in) is done 
        
        // this way works when rx and tx are async,which uart should
        // supposedly be that way
        if (rx_in == 0)
            idle <= 0;
    end

    always @(negedge idle) begin
        if (rx_enable) begin
            for (j=0;j<8;j++) begin
                @(posedge rxclk);
                rcvd_data[j] <= rx_in;
            end

            // stop bit
            // stop bit is important for situations where a uart frame is just side by side each other,
            // without the stop bit in these cases, can't really detect the falling edge
            
            @(posedge rxclk);
            if (rx_in) begin
                rx_empty <= 0;
                idle = 1;
            end else begin
                $display("ERROR: STOP BIT NOT FOUND");
                $stop;
            end
        end else begin
            $display("DATA RECEIVING IS NOT ENABLED");
        end
    end

    always @(posedge uld_rx_data) begin 
        rx_data <= rcvd_data;
        rcvd_data <= 0;
        rx_empty <= 1;
    end
         

endmodule

// TODO
// - Experiment with <= and =, see the difference
// - Is there a better way to implement the idle thing
// - Are there any edge cases that will wreck the reset feature and rethink
//   about the stop bit thing.
