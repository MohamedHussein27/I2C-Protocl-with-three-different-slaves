// this module represents one of I2C Bus slaves which is a memory slave stores data sent by master and send data to be read by master 
// address to Memory_Slave is: 7'b0011111 (hard coded)
module Memory_Slave #(
    parameter MEM_DEPTH = 64,
    parameter ADDR_SIZE = 8
)(
    input rst,
    input SCL_I, // Serial Clock (from master to slave)
    input SDA_I, // Serial Data (from Master to Slave)
    //output reg ACK, NACK, // to be sent to master
    //output reg stop // signal to master to stop the transaction with this slave
    output reg SCL_O, // SCL (serial clock) (from slave to master)
    output reg SDA_O // Serial Data (from Slave to Master)
);
    // Creating memory array
    reg [ADDR_SIZE-1:0] memory [MEM_DEPTH-1:0]; //address size is the same as memory width
    reg [2:0] slave_counter; // to assign the serial data to be parallel so we can process it

    parameter IDLE = 0,
              CHK_ADDR = 1, //state for checking the slave address to know if it's the demanded one or not
              ACK_S = 2, // state for sending acknowledge to master
              NACK_S = 3, // state for sending not acknowledge to master
              WAIT = 4, // state to add a clock cycle delay to synchronize between master and slave
              R = 5, // state for reading 
              W = 6, // state for writing
              STOP = 7; // state for sending stop signal to master
    
    reg [2:0] cs , ns;
    // internal signals
    reg ack_flag; // flag indicates that this is the second ACK signal so it's time for termination
    reg correct; // flag indicates that this slave is the required slave by the master if it's address matches the master address
    reg not_correct; // flag indicates that this slave is not the required slave by the master
    reg [7:0] slave_address; // signal to be filled with serial data (for address checking) 
    reg [7:0] slave_data;  // data to be filled with serial data (for regular data)
    reg done; // flag indicating that the transaction is completed


    // state memory
    always @(negedge SCL_I , negedge rst) begin // negedge SCL as SDA is only allowed to change while the SCL is low
        if(~rst) 
            cs <= IDLE;
        else 
            cs <= ns ;
    end

    // next state logic
    always @ (*) begin
        case(cs)
            IDLE: begin
                if (!SDA_I)
                    ns = CHK_ADDR;
                else
                    ns = IDLE;
            end
            CHK_ADDR: begin
                if (correct)
                    ns = ACK_S;
                else if (not_correct)
                    ns = NACK_S;
                else
                    ns = CHK_ADDR;
            end
            ACK_S: begin
                if (ack_flag)
                    ns = STOP;
                else
                    ns = WAIT;
            end
            WAIT: begin 
                if(slave_address[0]) // read process 
                    ns = R;
                else
                    ns = W;
            end
            NACK_S: ns = IDLE;
            R: begin
                if (done) // done reading or writing
                    ns = ACK_S;
                else
                    ns = R;
            end
            W: begin
                if (done) // done reading or writing
                    ns = ACK_S;
                else
                    ns = W;
            end
            STOP: begin
                ns = IDLE;
            end
        endcase
    end

    // output logic
    always @(negedge SCL_I) begin // negedge as transactions take place when SCL_I is low 
        case(cs)
            IDLE: begin
                slave_address = 0;
                slave_counter = 7;
                correct <= 0;
                not_correct <= 0;
                ack_flag <= 0;
                done <= 0;
                SDA_O <= 1; // default to high
                SCL_O <= 0; // default to low
            end
            CHK_ADDR: begin
                if (slave_address[7:1] == 7'b0011111) // if the address is correct, address for this slave is 0x1f and it's hard coded , added the address thing as there will be some manipulating with addresses
                    correct <= 1;
                else if (slave_address[7:1] != 7'b0011111 && slave_counter == 0)
                    not_correct = 1;
                slave_address[slave_counter] <= SDA_I;
                slave_counter <= slave_counter - 1;
            end
            ACK_S: begin
                slave_counter <= 7;
                ack_flag <= 1;
                SDA_O <= 0;
                correct <= 0;
                not_correct <= 0;
                if(slave_address[0]) // read process
                    slave_data <= memory[slave_address>>1]; // had to add this here to make just 8 bit transaction between the two ACKs
            end
            WAIT: begin
                SDA_O <= 1; // default to high
                SCL_O <= 0; // default to low
            end
            NACK_S: begin
                SDA_O <= 0;
                SCL_O <= 1;
                correct <= 0;
                not_correct <= 0;
            end
            R: begin // reading process
                //SDA_O <= 1; // default to high
                SCL_O <= 0; // default to low
                    if (slave_counter == 0) 
                        done <= 1;
                    SDA_O <= slave_data[slave_counter]; // data is being sent serially
                    slave_counter <= slave_counter - 1;
            end
            W: begin
                SDA_O <= 1; // default to high
                SCL_O <= 0; // default to low
                if (slave_counter == 0) 
                    done <= 1;
                slave_data[slave_counter] <= SDA_I ;
                slave_counter <= slave_counter - 1;
            end
            STOP: begin
                if (~slave_address[0])
                    memory[slave_address>>1] <= slave_data; // at this moment data will be fully transmitted to slave data
                SDA_O <= 1;
                SCL_O <= 1;
            end
        endcase
    end   
endmodule