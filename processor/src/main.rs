use clap::Parser;
use std::{fs, path::PathBuf, process};

use haversine_processor::{
    haversine::{EARTH_RADIUS_KM, compute_haversine},
    json::{Data, parse_json},
};

fn main() -> Result<(), String> {
    let args = Args::parse();

    let json = fs::read_to_string(args.path)
        .unwrap_or_else(|_| {
            eprintln!("Failed to read json file");
            process::exit(1);
        })
        .chars()
        .collect();

    let data = parse_json(json)?;

    let mut haversines: Vec<f64> = vec![];

    let pairs: Vec<(f64, f64, f64, f64)> = if let Data::Object(ref hash_map) = data
        && let Some(Data::Array(pairs)) = hash_map.get("pairs")
    {
        pairs
            .iter()
            .map(|pair| {
                let Data::Object(hash_map) = pair else {
                    return Err("Invalid data".to_string());
                };

                let get_float = |key: &str| -> Result<f64, String> {
                    match hash_map.get(key) {
                        Some(Data::Float(value)) => Ok(*value),
                        _ => Err("Invalid data".to_string()),
                    }
                };

                Ok((
                    get_float("x0")?,
                    get_float("y0")?,
                    get_float("x1")?,
                    get_float("y1")?,
                ))
            })
            .collect::<Result<Vec<_>, String>>()?
    } else {
        return Err("Invalid data".to_string());
    };

    let mut sum = 0.0;
    let mut count = 0;

    for pair in pairs {
        let (x0, y0, x1, y1) = pair;

        let haversine = compute_haversine(x0, y0, x1, y1, EARTH_RADIUS_KM);

        haversines.push(haversine);
        sum += haversine;
        count += 1;
    }

    let average = sum / count as f64;

    println!("Average: {}", average);

    if let Some(answers_path) = args.answers_path
        && let Ok(answers) = fs::read(answers_path)
    {
        for (i, haversine) in haversines.iter().enumerate() {
            let offset = i * 8;

            let answer = f64::from_le_bytes(answers[offset..offset + 8].try_into().unwrap());

            if (answer - haversine).abs() > args.tolerance {
                println!(
                    "Difference > {:.1e}:\n    Precomputed Haversine: {}\n    Haversine: {}",
                    args.tolerance, answer, haversine
                );
            }
        }

        let answer_average = f64::from_le_bytes(*answers.last_chunk::<8>().unwrap());

        println!(
            "Precomputed Average: {}\nDifference: {}",
            answer_average,
            answer_average - average
        );
    }

    Ok(())
}

#[derive(Parser)]
#[clap()]
struct Args {
    path: PathBuf,
    answers_path: Option<PathBuf>,

    #[clap(short, long, default_value_t = 1e-9)]
    tolerance: f64,
}
