module LIFO_tb ();
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
        // LIFO
        // sixth scenario is to write two values into our LIFO slave with it's unique address
        start = 1; 
        Data = 8'b11110010; // LIFO address with first bit low to indicate a writing proccess
        #20;
        start = 0;
        #410;
        Data = 8'b01111010;
        #700;
        start = 1;
        Data = 8'b11110010; // LIFO address with first bit low to indicate a writing proccess
        #20;
        start = 0;
        #410;
        Data = 8'b01011010;
        #800;
        // seventh scenario is to read data from the slave's LIFO
        start = 1;
        Data = 8'b11110011; // same address with first bit high to indicate a reading proccess
        #20;
        start = 0;
        #1300;
        $stop;
    end
endmodule