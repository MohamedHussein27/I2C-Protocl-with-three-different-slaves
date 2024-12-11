module Memory_tb ();
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
        // first scenario is to write data into the memory of our first memory slave
        start = 1; 
        Data = 8'b00111110; // first address with first bit low to indicate a writing proccess
        #20;
        start = 0;
        #410;
        Data = 8'b00001110;
        #800; // wait some time between each scenario
        // second scenario is to read data from the slave's memory with the same address we wrote data in
        start = 1;
        Data = 8'b00111111; // same address with first bit high to indicate a reading proccess
        #20;
        start = 0;
        #1300;
        // third scenario is to insert a wrong address 
        start =1;
        Data = 8'b11000111;
        #20;
        start = 0;
        #800;
        $stop;
    end
endmodule