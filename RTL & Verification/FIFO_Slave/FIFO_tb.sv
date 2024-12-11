module FIFO_tb ();
    logic  start;
    logic [7:0] Data;
    logic clk, rst;
    logic [7:0] received_data;

    I2C_Wrapper dut (.*);

    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end
    initial begin
        rst = 0;
        #20;
        rst = 1;
        // FIFO
        // fourth scenario is to write two values into our FIFO slave with it's unique address
        start = 1; 
        Data = 8'b00110010; // FIFO address with first bit low to indicate a writing proccess
        #20;
        start = 0;
        #410;
        Data = 8'b00101111;
        #700;
        start = 1;
        Data = 8'b00110010; // FIFO address with first bit low to indicate a writing proccess
        #20;
        start = 0;
        #410;
        Data = 8'b10101110;
        #800;
        // fifth scenario is to read data from the slave's FIFO
        start = 1;
        Data = 8'b00110011; // same address with first bit high to indicate a reading proccess
        #20;
        start = 0;
        #1300;
        $stop;
    end
endmodule