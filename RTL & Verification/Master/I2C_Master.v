// this module represents the Master in I2C bus where the commands will be given be me in the test bench to the master
module I2C_Master (
    input start, // to start the transaction between the master and any slave
    input [7:0] Data, // data will be slave address 7 bits with R/W bit or regular data to one of the slaves
    input clk, // internal clock in the master to control FSM and SCL
    input rst, // reset signal 
    input SCL_I, SDA_I, // (from Slave to Master)
    output reg SCL_O, SDA_O, // SCL (serial clock) and SDA (serial data) (from Master to Slave)
    output reg [7:0] received_data // to store the received data from the slave
);
    //defining our states
    parameter IDLE = 2'b00,
              START = 2'b01,
              ACTIVE = 2'b10,
              ACK = 2'b11,
              NACK = 3'B100,
              RECEIVING = 3'b101, // receiving data from the slave
              WAITING = 3'b110,
              STOP = 3'b111;
    
    reg [2:0] ns, cs; // next state, current state
    
    reg [2:0] counter; // to send bits serially to the slaves
    reg V_SCL ; // virtual SCL is just the same as SCL_O but of type reg
    reg receive ; // flag to alert we are in the receiving state
    //reg [7:0] received_data; // to store the received data from the slave
    reg done_receiving; // flag to indicate the completness of the reception
    reg begin_rec; // just to add delay to synchronize with slave is receiving state
    reg writing; // flag to indicate it's a writing process
    //state memory 
    always @(posedge clk , negedge rst)
    begin
        if(~rst) 
            cs <= IDLE;
        else 
            cs <= ns ;
    end

    // next state logic
    always @(*) begin
        case(cs)
            IDLE: begin
                if (start)
                    ns = START;
                else
                    ns = IDLE;
            end 
            START: ns = ACTIVE;
            ACTIVE: begin
                if (!SDA_I && !SCL_I) // !SDA_I && !SCL_I is an indication of an Acknowledgement 
                    ns = ACK;
                else if (!SDA_I && SCL_I) // !SDA_I && SCL_I is an indication of a not Acknowledgement 
                    ns = NACK;
                else
                    ns = ACTIVE;
            end
            ACK: begin
                if (receive && SCL_I)
                    ns = STOP;
                else if (SCL_I && SDA_I)
                    ns = STOP;
                else if (Data[0] && !writing)
                    ns = RECEIVING;
                else
                    ns = ACTIVE;
            end
            NACK: ns = STOP;
            RECEIVING: begin
                if (done_receiving) // done receiving 
                    ns = WAITING;
                else
                    ns = RECEIVING;
            end
            WAITING: begin
                if (receive && SCL_I)
                    ns = ACK;
                else 
                    ns = WAITING;
            end
            STOP: ns = IDLE;
        endcase
    end

    // output logic
    always @(posedge clk) begin
        case(cs)
            IDLE: begin // initially SCL and SDA are both high
                SCL_O <= 1'b1;
                SDA_O <= 1'b1;
                V_SCL <= 1'b1; // defualt is the same as SCL_O
                counter <= 7; // we send MSB first
                receive <= 0; // back again to zero
                done_receiving <= 0; 
                begin_rec <= 0;
                writing <= 0;
            end
            START: begin // start condition when SDA is pulled down while SCL is high
                SCL_O <= 1'b1;
                SDA_O <= 1'b0;
            end
            ACTIVE: begin
                if (!Data[0])
                    writing <= 1; // indicate it's a writing process
                SCL_O <= ~SCL_O; // SCL will be clock activated now
                V_SCL <= ~SCL_O; // we will need it in the next conition to synchronize between master and slaves
                if (!V_SCL) begin
                    SDA_O <= Data[counter];
                    counter <= counter - 1;
                end
            end
            ACK: begin
                SDA_O <= 1'b0;
                counter <= 7;
            end
            NACK: begin
                SCL_O <= 1'b1;
                SDA_O <= 1'b1;
            end
            RECEIVING: begin
                receive <= 1;
                SCL_O <= ~SCL_O; // SCL will be clock activated now
                V_SCL <= ~SCL_O; // we will need it in the next conition to synchronize between master and slaves
                if (SDA_I && !SCL_I) // to add a delay so it synchronizes with the slave
                    begin_rec <= 1;
                if(begin_rec) begin 
                    if (counter == 0)
                        done_receiving <= 1;
                    if (!V_SCL) begin // to synchronize between master and slaves
                        received_data[counter] <= SDA_I;
                        counter <= counter - 1;
                    end
                end
            end
            WAITING: SCL_O <= ~SCL_O;
            STOP: begin
                SCL_O <= 1'b1;
                SDA_O <= 1'b1;
            end
        endcase
    end
endmodule