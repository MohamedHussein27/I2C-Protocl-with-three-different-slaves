// SCL & SDA signals are not special and they are used for every slave, you should uncomment the slave you want to check and comment the other two slave, as if they were in a high-impedance state, to check on your demanded slave
module I2C_Wrapper (
    input start,
    input [7:0] Data,
    input clk, rst,
    output [7:0] received_data // data comes to master from slave when it's a read operation
);   
    // Signals between Master and Slaves
    // Master
    wire SDA_M_S; // Master to slave
    wire SDA_S_M; // Slave to master
    wire SCL_M_S; // From master to slaves
    wire SCL_S_M; // From slaves to master

    // Master Instantiation
    I2C_Master Master(
        .start(start),
        .Data(Data),
        .clk(clk),
        .rst(rst),
        .SCL_I(SCL_S_M),
        .SDA_I(SDA_S_M),
        .SCL_O(SCL_M_S),
        .SDA_O(SDA_M_S),
        .received_data(received_data)
    );

    /*// Memory Instantiation
    Memory_Slave m_slave(
        .rst(rst),
        .SCL_I(SCL_M_S),
        .SDA_I(SDA_M_S),
        .SCL_O(SCL_S_M),
        .SDA_O(SDA_S_M)
    );

    // FIFO Instantiation
    FIFO_Slave f_slave(
        .rst(rst),
        .SCL_I(SCL_M_S),
        .SDA_I(SDA_M_S),
        .SCL_O(SCL_S_M),
        .SDA_O(SDA_S_M)
    );*/   

    // LIFO Instantiation
    LIFO_Slave l_slave(
        .rst(rst),
        .SCL_I(SCL_M_S),
        .SDA_I(SDA_M_S),
        .SCL_O(SCL_S_M),
        .SDA_O(SDA_S_M)
    );
endmodule