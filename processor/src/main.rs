use std::{env, fs, process};

use haversine_processor::{
    haversine::{EARTH_RADIUS_KM, compute_haversine},
    json::{Data, parse_json},
};

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

    let data = parse_json(json)?;

    let pairs = if let Data::Object(ref hash_map) = data
        && let Some(pairs) = hash_map.get("pairs")
        && let Data::Array(pairs) = pairs
    {
        pairs
    } else {
        return Err("Invalid data".to_string());
    };

    let mut sum = 0.0;
    let mut count = 0;

    for pair in pairs {
        let (x0, y0, x1, y1) = if let Data::Object(hash_map) = pair {
            (
                if let Some(x0) = hash_map.get("x0")
                    && let Data::Float(x0) = x0
                {
                    *x0
                } else {
                    return Err("Invalid pair".to_string());
                },
                if let Some(y0) = hash_map.get("y0")
                    && let Data::Float(y0) = y0
                {
                    *y0
                } else {
                    return Err("Invalid pair".to_string());
                },
                if let Some(x1) = hash_map.get("x1")
                    && let Data::Float(x1) = x1
                {
                    *x1
                } else {
                    return Err("Invalid pair".to_string());
                },
                if let Some(y1) = hash_map.get("y1")
                    && let Data::Float(y1) = y1
                {
                    *y1
                } else {
                    return Err("Invalid pair".to_string());
                },
            )
        } else {
            return Err("Invalid pair".to_string());
        };

        let haversine = compute_haversine(x0, y0, x1, y1, EARTH_RADIUS_KM);

        sum += haversine;
        count += 1;
    }

    println!("Average: {}", sum / count as f64);

    Ok(())
}
