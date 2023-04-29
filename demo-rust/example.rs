use anyhow::Context;
use interprocess::local_socket::{LocalSocketListener, LocalSocketStream};
use std::{
    io::{self, prelude::*, BufReader},
    env
};
// use hex;
// use ethabi::{encode, Token};
// use std::fmt::Write as _;
use std::process;

#[cfg(debug_assertions)]
use std::fs::OpenOptions;

pub fn main() -> anyhow::Result<()> {

#[cfg(debug_assertions)]
let mut file = OpenOptions::new()
.create(true)
.append(true)
.open(".rust-ipc-server.log")
.unwrap();

#[cfg(debug_assertions)]
writeln!(file, "My pid is {}", process::id())?;

// Define a function that checks for errors in incoming connections. We'll use this to filter
// through connections that fail on initialization for one reason or another.
fn handle_error(conn: io::Result<LocalSocketStream>) -> Option<LocalSocketStream> {
    match conn {
        Ok(c) => Some(c),
        Err(e) => {
            eprintln!("Incoming connection failed: {}", e);
            None
        }
    }
}


let args: Vec<String> = env::args().collect();

let mut splitted = args[1].split(":");
let socket_id = match splitted.next() {
    None => panic!("Expect to run with an ipc: arg"),
    Some("ipc") => match splitted.next() {
        None => panic!("no ipc path/name specified"),
        Some(str) => str,
    }
    Some(_) => panic!("Expect to run with an ipc: arg"),
};

// Bind our listener.
let listener = match LocalSocketListener::bind(socket_id.to_string()) {
    Err(e) if e.kind() == io::ErrorKind::AddrInUse => {
        eprintln!(
            "\
Error: could not start server because the socket file is occupied. Please check if {} is in use by \
another process and try again.",
        socket_id.to_string(),
        );
        return Err(e.into());
    }
    x => x?,
};



#[cfg(debug_assertions)]
writeln!(file, "Server running at {}", socket_id.to_string())?;

// max msg size
let mut buffer = String::with_capacity(16777216);

let mut counter = 0;
let valid_request=  "0x0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000001c0000000000000000000000000ffffffffffffffffffffffffffffffffffffffff0000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000116608060405234801561001057600080fd5b5060f78061001f6000396000f3fe6080604052348015600f57600080fd5b5060043610603c5760003560e01c80633fb5c1cb1460415780638381f58a146053578063d09de08a14606d575b600080fd5b6051604c3660046083565b600055565b005b605b60005481565b60405190815260200160405180910390f35b6051600080549080607c83609b565b9190505550565b600060208284031215609457600080fd5b5035919050565b60006001820160ba57634e487b7160e01b600052601160045260246000fd5b506001019056fea2646970667358221220f0cfb2159c518c3da0ad864362bad5dc0715514a9ab679237253d506773a0a1b64736f6c6343000813003300000000000000000000\n";
let valid_termination = "0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000060000000000000000000000000b318d82866cd9f7d7a55dbbf0a80f787b72bf97c000000000000000000000000a34794dff7e5d2b06f5b98f3b27aae9b919f3469000000000000000000000000105dbc34f9cc0608c1682ad5bea456e29bd0a70a\n";

for conn in listener.incoming().filter_map(handle_error) {
    // connection incoming, we create a read buffer
    let mut conn = BufReader::new(conn);

    // we read the first line
    conn.read_line(&mut buffer)
        .context("Socket receive failed")?;

    #[cfg(debug_assertions)]
    writeln!(file, "from client {}", buffer)?;

    if buffer.len() > 0 {
        // if there is something we reply with our request
        if counter == 0 {
            conn.get_mut().write_all(valid_request.as_bytes())?;
        } else if counter == 1 {
            conn.get_mut().write_all(valid_request.as_bytes())?;
        } else if counter == 2 {
            conn.get_mut().write_all(valid_request.as_bytes())?;
        } else if counter == 3 {
            conn.get_mut().write_all(valid_termination.as_bytes())?;
            break;
        }
        
        

        counter = counter +1;
        writeln!(file, "counter {}", counter)?;
    } else {
        // else this is was just a connection attempt and we can skip
    }
    
    // clear the buffer for the next incoming client read/write operations
    buffer.clear();
}
Ok(())
}
