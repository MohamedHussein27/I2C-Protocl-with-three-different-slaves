# I2C-Protocl-with-three-different-slaves

## Overview
The Inter-Integrated Circuit (I2C) is a widely used serial communication protocol designed for short-distance communication between microcontrollers, sensors, memory devices, and other peripherals. It supports multiple master and multiple slave configurations, enabling efficient data exchange in embedded systems.

This repository contains the implementation of I2C bus system with a master and three distinct slaves: Memory, FIFO, and LIFO.

---

## I2C Structure

> **Note:** Each slave device (Memory, FIFO, and LIFO) will undergo individual verification to ensure its functionality and compliance with the I2C protocol.

**General Structure** 
![I2C general](https://github.com/MohamedHussein27/UART-With-FIFOs/blob/main/Structure/UART%20Structure.png)

**Implemented Structure**
![I2C implemented](https://github.com/MohamedHussein27/UART-With-FIFOs/blob/main/Structure/UART%20Structure.png)

## Work Idea

### I2C Master
- Controls the communication by generating the clock (SCL) and initiating read/write operations.
- Supports **start** and **stop** conditions for bus arbitration.
- Implements an addressing mechanism to select one of the three slaves (**Memory, FIFO, or LIFO**).
- Handles **ACK/NACK** responses to ensure successful communication.
- Can perform both **single-byte** and **multi-byte** transactions.

### I2C Slave - Memory
- Acts as a storage unit where the master can **read from** or **write data** to specific memory locations.
- Uses an internal register to store incoming **address and data**.
- Implements **sequential and random access** read operations.

### I2C Slave - FIFO (First In First Out)
- Operates as a queue where **data written first is read first**.
- Supports **write operations** from the master that push data into the FIFO buffer.
- Read operations retrieve the **oldest stored data**.
- Generates a **FIFO Full** flag when it reaches its storage limit.
- Generates a **FIFO Empty** flag when there is no data to read.

### I2C Slave - LIFO (Last In First Out)
- Works as a stack where **the last written data is read first**.
- The master can **push data** into the LIFO structure.
- Read operations retrieve the **most recently written data**.
- Provides **LIFO Full** and **LIFO Empty** flags for flow control.

### Addressing & Communication
- Each slave has a unique **7-bit I2C address** to differentiate them.
- The master sends the **slave address + read/write bit** to select the target slave.
- After selection, data transfer follows the **ACK-based** handshake mechanism.

### Error Handling & Status Flags
- **ACK/NACK** handling ensures data integrity.
- **Bus Arbitration** prevents conflicts when multiple masters exist (if applicable).
- Each slave implements **overflow/underflow protection** to prevent invalid operations.

---

## Verifying Functionality

> **Note:** In QuestaSim simulation snapshots, the Master will be highlighted in gold, while the Slave (any of the three) will be highlighted in blue for clarity and differentiation.

in this section we will have a quick view on the full waveforms for each slave, for more details try to check the I2C documentation: link

