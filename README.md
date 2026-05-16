# Crc32 Over Uart
This is a beginner VHDL project targeting the ICE40 HX1K fpga. My goal was to teach myself VHDL by building my own UART and FIFO entities, as well as building something to make use of them.

This repository includes a VHDL program that receives a stream of bytes over UART, computes the crc32 of those bytes, then returns the hash back over UART. It also includes a Rust program that generates the stream of data and sends it to the FPGA, and verifies the responses.

## VHDL OVerview
In order of data flow, the VHDL program contains the following entities:
1. **UartRx** is a UART receiver. It emits a notification whenever it receives a byte of data.
2. **InputFSM** processes input bytes into structured messages. It uses the input stream to determine when to start a new hash, which bytes to include in the hash, and when a message is complete and thus the hash should be sent back to the caller.
3. **ComputeCRC32** computes a CRC32 hash, at a rate of up to one byte per cycle.
4. **OutputFSM** awaits a trigger from the InputFSM. When triggered, it takes the most recent CRC32 hash, as well as a user-defined request ID, and breaks them into a stream of bytes for output.
5. **UartTxBuffered** wraps a FIFO and a UART transmitter, allowing for bursts of bytes to be queued for transmission.

The project also contains a top entity that wires everything together, as well as test benches for all of the above entities.

## Input message structure
 - Each message starts with a one-byte "Request ID". It has no meaning within the program, but it's returned with each output message as a way of disambiguating multiple messages in flight at once.
 - Next, the message contains an arbitrary sequence of bytes to be hashed. 
 - The byte 0xFF is treated as a control code instead of being added to the hash, with the subsequent byte giving a command to the program:
   - If the subsequent byte is 0x00, the message will be ended, and any following inputs will be treated as the start of a new message.
   - Any other byte will be simply added to the hash as if it was a normal byte (IE, to hash the byte 0xFF, it must be escaped by sending two 0xFF back to back)

## Output message structure
After each input message ends, five bytes are sent back to the caller. The first is the request ID passed in with the input message. The remaining four are the crc32 hash of the message, in little endian order.

## Timeout
While the input FSM is processing an input message, it tracks a timeout value. If 2.5 milliseconds pass without receiving the next byte in the message, it cancels the message and begins waiting for a new message to start.
