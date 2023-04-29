
use std::io::{prelude::*, BufReader};
use std::error::Error;
use std::{env, str};
use std::process::{Command, Stdio, exit};
use std::{thread, time};
use ethabi::{encode, Token};
use hex;
use rand::prelude::*;

#[cfg(debug_assertions)]
use std::fs::OpenOptions;


use interprocess::local_socket::{LocalSocketStream, NameTypeSupport};

fn connect<'a>(name: &str, retry: u32, retry_interval: u64) -> LocalSocketStream {
    let connection_attempt = LocalSocketStream::connect(name);
    let conn = match connection_attempt {
        Ok(conn) => conn,
        // in case of error we retry `retry_interval` later
        Err(error) => {
            if retry == 0 {
                panic!("Failed to connect: {:?}", error);
            }
            thread::sleep(time::Duration::from_millis(retry_interval));
            return connect(name, retry -1, retry_interval);
        }
    };
    return conn;
}

fn connect_and_send(name: &str, retry: u32, retry_interval: u64, message_buffer: &[u8]) -> Result<String, Box<dyn Error>>{
    let mut buffer = String::with_capacity(16777216);

    let conn = connect(name, retry, retry_interval);
    
    // Wrap it into a buffered reader right away so that we could write and read
    let mut conn = BufReader::new(conn);

    conn.get_mut().write_all(message_buffer)?;
    conn.get_mut().write_all(b"\n")?; // we add a new line as this act as our delimitter for messages

    
    conn.read_line(&mut buffer)?;

    let mut str = buffer.chars();
    str.next_back();
    return Ok(String::from(str.as_str()));
}


fn main() -> Result<(), Box<dyn Error>> {

#[cfg(debug_assertions)]
let mut file = OpenOptions::new()
.create(true)
.append(true)
.open(".rust-executor.log")
.unwrap();

    
let args: Vec<String> = env::args().collect();
let command = &args[1];

#[cfg(debug_assertions)]
writeln!(file, "{}", args.join(","))?;


if command.eq("connect") {
    // debugging command
    let args: Vec<String> = env::args().collect();
    let socket_id = &args[2];

    connect(socket_id, 300, 10);

    #[cfg(debug_assertions)]
    writeln!(file, "connected!")?;
    
    #[cfg(debug_assertions)]
    writeln!(file,"------------------ CONNECT ------------------")?;
} else if command.eq("init") {
    
    let mut rng = rand::thread_rng();
    let y: u32 = rng.gen();
    let name = {
        use NameTypeSupport::*;
        match NameTypeSupport::query() {
            OnlyPaths | Both => format!("/tmp/app.world-{}", y),
            OnlyNamespaced => format!("@app.world-{}", y),
        }
    }.to_string();

    let program = &args[2];
    let mut program_args = Vec::with_capacity(args[3 .. ].len() + 1);
    for i in 3..args.len() {
        program_args.push(&args[i]);
    }
    let last_arg = format!("ipc:{}", name);
    program_args.push(&last_arg);

    #[cfg(debug_assertions)]
    writeln!(file, "spawn {} {}", program, name)?;

    // we execute the program as specified 
    // This is assumed the program in question is also running an ipc server on socket/mamed pipe idified by `name`
    let _child = Command::new(program)
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::null())
    .args(program_args)
    .spawn()
    .expect("failed to execute child");

    #[cfg(debug_assertions)]
    writeln!(file, "child PID {}", _child.id())?;

    // we attempt to connect, we retry 300 times with an interval of 10ms
    // the process has 3 seconds to establish an IPC server
    // this is plenty of time
    connect(&name, 300, 10);

    #[cfg(debug_assertions)]
    writeln!(file, "connected!")?;
    
    // we write the name abi-encoded as a string to stdout for forge to pick it up
    print!("0x{}", hex::encode(encode(&[Token::String(String::from(name))])));
    // and we quit.

    #[cfg(debug_assertions)]
    writeln!(file,"------------------ INIT ------------------")?;

} else {
    let name = args[2].as_str();
    if command.eq("exec") {
        let data = format!("response:{}", args[3].as_str());
        
        // we send the data from forge to our running process (who is also running an ipc server on socket/mamed pipe idified by `name`)
        let request = connect_and_send(name, 0, 10, data.as_bytes())?;

        // we write the request to stdout for forge to pick it up
        print!("{}", request);
        // and we quit.

        #[cfg(debug_assertions)]
        writeln!(file,"NEW REQUEST: {}", request)?;
        #[cfg(debug_assertions)]
        writeln!(file,"------------------ EXEC ------------------")?;
    
    } else if command.eq("terminate") {
        let error_message = match args.len() > 3 {
            true => args[3].as_str(),
            false => "termination",
        };
         
        let mut msg: String = "terminate:".to_owned();
        msg.push_str(error_message);

        // we send the `terminate:<error message>` string to our running process
        connect_and_send(name, 0,10,msg.as_bytes())?;

        // we ignore whatever the program replies here and we simply print 0x
        print!("0x");
        // and we quit.

        #[cfg(debug_assertions)]
        writeln!(file,"------------------ TERMINATE ------------------")?;

    } else {
        #[cfg(debug_assertions)]
        writeln!(file,"------------------ UNKNOWN ------------------")?;

        // exiting with error
        exit(1);
    }
}

Ok(())
}