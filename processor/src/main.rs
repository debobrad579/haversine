use std::{env, fs, process};

use haversine_processor::json::parse_json;

fn main() -> Result<(), String> {
    let args = env::args().collect::<Vec<String>>();

    if args.len() != 2 {
        eprintln!("Usage: haversine-processor <path/to/json>");
        process::exit(1);
    }

    let json = fs::read_to_string(&args[1])
        .unwrap_or_else(|_| {
            eprintln!("Failed to read json file");
            process::exit(1);
        })
        .chars()
        .collect();

    parse_json(json)?;

    Ok(())
}
