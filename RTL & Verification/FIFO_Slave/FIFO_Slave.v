// this module represents one of I2C Bus slaves which is a FIFO slave stores data sent by master and send data to be read by master using FIFO technique.
// address to FIFO_Slave is: 7'b0011001 (hard coded)
module FIFO_Slave  #(parameter FIFO_WIDTH = 8, FIFO_DEPTH = 16)(
    input rst,
    input SCL_I, // Serial Clock (from master to slave)
    input SDA_I, // Serial Data (from Master to Slave)
    //output reg ACK, NACK, // to be sent to master
    //output reg stop // signal to master to stop the transaction with this slave
    output reg SCL_O, // SCL (serial clock) (from slave to master)
    output reg SDA_O // Serial Data (from Slave to Master)
);
    // Creating memory array
    reg [FIFO_WIDTH-1:0] fifo [FIFO_DEPTH-1:0]; //address size is the same as memory width
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
    // extra internal signals for FIFO
    reg [$clog2(FIFO_DEPTH)-1:0] write_counter = 0; 
    reg [$clog2(FIFO_DEPTH)-1:0] read_counter = 0;
    reg full;
    reg empty;

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
                if (slave_address[7:1] == 7'b0011001) // if the address is correct, address for this slave is 0x1f and it's hard coded , added the address thing as there will be some manipulating with addresses
                    correct <= 1;
                else if (slave_address[7:1] != 7'b0011001 && slave_counter == 0)
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
                if (slave_address[0] && !empty)
                    slave_data <= fifo[read_counter]; 
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
                SDA_O <= 1;
                SCL_O <= 1;
                if (!slave_address[0] && !full)  //writing data to memory if write enable is on and the FIFO is not full, (!slave_address[0] && cs == STOP) indicates a writing process
                    fifo[write_counter] <= slave_data;
            end
        endcase
    end   
    // always block for fifo transactions
    always @ (negedge SCL_I or negedge rst) begin
        if (~rst) begin
            write_counter <= 0;
            read_counter <= 0;
            empty <= 1;
            full <= 0;
        end
        else if ((!slave_address[0] && cs == STOP) && !full) begin //writing data to memory if write enable is on and the FIFO is not full, (!slave_address[0] && cs == STOP) indicates a writing process
            empty <= 0;
            //fifo[write_counter] <= slave_data; put it in STOP state to avoid multidriven on slave_data
            write_counter <= write_counter + 1;
            if (write_counter + 1 == read_counter || ((write_counter == FIFO_DEPTH -1 ) && (read_counter == 0))) //the first condition is an indication that it might be a full state while the second condition is a special case usually happens at the beginning 
                                                                                                             //I forced the case where read counter is zero and and it's supposed that when we add 1 to the write counter it goes back to zero but that is not what really happens, so when adding 1 it's actually 8 not zero so that's why i putted this condition 
                full <= 1;
        end
        else if ((slave_address[0] && cs == ACK_S) && !empty) begin  //same flow as writing stage
            full <= 0;
            //slave_data <= fifo[read_counter];  put it in ACK_S state to avoid multidriven on slave_data
            read_counter <= read_counter + 1;
            if (read_counter + 1 == write_counter || ((read_counter == FIFO_DEPTH-1) && (write_counter == 0)))
                empty <= 1;
        end
    end
endmodule