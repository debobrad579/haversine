use std::{env, fs, process};

use haversine_processor::json::parse_json;

fn main() {
    let args = env::args().collect::<Vec<String>>();

    if args.len() != 2 {
        eprintln!("Usage: haversine-processor <path/to/json>");
        process::exit(1);
    }

    let json: Vec<char> = fs::read(&args[1]).into().unwrap_or_else(|_| {
        eprintln!("Failed to read json file");
        process::exit(1);
    });

    parse_json(json);
}
