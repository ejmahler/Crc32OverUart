use std::{arch::x86_64::_mm_crc32_u8, collections::HashMap, io::{ErrorKind, Read}, sync::{LazyLock, Mutex}, time::Duration};

use rand::prelude::*;
use serialport::SerialPort;

fn main() {
    #[cfg(not(target_arch = "x86_64"))]
    {
        println!("This program only supports the x86_64 architecture, due to the _mm_crc32_u8 intrinsic. Aarch64 has __crc32cb but it hasn't been tested.");
        return;
    }

    // Connect to a port, using the command line arguments for settings
    let port = {
        let args: Vec<String> = std::env::args().collect();
        let maybe_device_name = args.get(1);
        let maybe_baud = args.get(2);

        let parsed_baud = maybe_baud.and_then(|b| b.parse::<u32>().ok());

        let (device_name, baud) = match (maybe_device_name, parsed_baud) {
            (Some(name), Some(baud)) => (name, baud),
            _ => {
                println!("Usage: cargo run -- <string device_name> <integer baud_rate>");
                return;
            }
        };

        let port = match serialport::new(device_name, baud).open() {
            Ok(port) => port,
            Err(_) => {
                println!("Error: Failed to connect to port \"{device_name}\". Available devices:");
                let ports = serialport::available_ports().expect("\t(No devices avialable)");
                if ports.is_empty() {
                    println!("\t(No devices avialable)");
                } else {
                    for p in ports {
                        println!("\t{}", p.port_name);
                    }
                }
                return;
            }
        };

        port
    };

    // Start a new thread to do the writing half
    let clone = port.try_clone().expect("Failed to clone port");
    std::thread::spawn(move || writer_thread(clone));

    // Begin the reading half
   reader_thread(port);
}

static SHARED_DATA : LazyLock<Mutex<HashMap<u8, u32>>> = LazyLock::new(|| Mutex::new(HashMap::new()));

fn reader_thread(mut port: Box<dyn SerialPort>) {
    let local_shared_data  = LazyLock::force(&SHARED_DATA);
    loop {
        // Read the next response from the serial port
        let mut buffer = [0; 5];
        read_exact_no_timeout(&mut port, &mut buffer).expect("Failed to read");

        // The first byte is the request id. Use the request id to look up the expected crc32 hash
        let request_id = buffer[0];
        let expected_hash = {
            let mut locked_map = local_shared_data.lock().unwrap();
            match locked_map.remove(&request_id) {
                Some(hash) => hash,
                None => panic!("Received an unexpected request id from device: {request_id}"),
            }
        };

        // The next 4 bytes is the computed hash in little endian order. Extract it and verify that it matches the expected hash
        let received_hash = u32::from_le_bytes(buffer[1..].try_into().unwrap());

        assert_eq!(expected_hash, received_hash, "expected: 0x{expected_hash:08x}, received: 0x{received_hash:08x}");

        println!("Request id {request_id}: Verified");
    }
}

// Reads an exact amount of bytes from the reader. Blocks until the exact number of bytes is read, with no timeout
fn read_exact_no_timeout(reader: &mut impl Read, mut buffer: &mut [u8]) -> Result<(), std::io::Error> {
    while !buffer.is_empty() {
        let bytes_read = match reader.read(buffer) {
            Ok(bytes) => bytes,
            Err(e) => {
                if e.kind() == ErrorKind::TimedOut {
                    0
                } else {
                    return Err(e);
                }
            }
        };

        buffer = &mut buffer[bytes_read..];
    }
    Ok(())
} 


fn writer_thread(mut port: Box<dyn SerialPort>) {
    let local_shared_data  = LazyLock::force(&SHARED_DATA);
    let mut rng = rand::rng();

    let mut next_request_id : u8 = 0;
    let mut message = Vec::with_capacity(1 << 25);
    loop {
        message.clear();

        // Simple looping request id to distinguish between one message and another
        let request_id = next_request_id;
        next_request_id = next_request_id.wrapping_add(1);
        message.push(request_id);

        // Determine how long our message will be. We want to bias towards smaller messages, but have some longer ones in there
        // Our algorithm will be 
        // val = random(1.0 to 4.5)
        // length = 2 ^ (val ^ 2)
        // This will give us a message length anywhre from 1 byte to ~2^20 bytes, heavily biased to the lower end
        let sqrt_bits = rng.random_range(1.0..=4.5);
        let message_length = 2.0f64.powf(sqrt_bits * sqrt_bits) as usize;

        // Fill in our message with our request id, followed by random data. Also compute a running crc32 of the message as we go
        let mut crc = 0xFFFFFFFF;

        for _ in 0..message_length {
            let byte : u8 = rng.random();
            crc = unsafe { _mm_crc32_u8(crc, byte) };
            if byte == 0xff {
                message.push(0xff);
                message.push(0xff);
            } else {
                message.push(byte);
            }
        }
        crc = crc ^ 0xFFFFFFFF;

        // End message control code
        message.push(0xff);
        message.push(0x00);


        // We're almost ready. Store this message's crc with its request id for the reader to verify
        {
            let mut locked_map = local_shared_data.lock().unwrap();
            let replaced = locked_map.insert(request_id, crc);
            assert!(replaced.is_none(), "Request id {request_id} didn't get a response from device!");
        }
                
        println!("Request id {request_id}: Sending request, size: {:.1}KB", message.len() as f32 / 1000.0);
        port.write_all(&message).expect("Failed to write");
    }
}