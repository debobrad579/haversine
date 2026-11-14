use clap::Parser;
use std::{fs, path::PathBuf};

use haversine_processor::{
    haversine::{EARTH_RADIUS_KM, compute_haversine},
    json::parse_json,
    pairs::get_pairs,
};

fn main() -> Result<(), String> {
    let args = Args::parse();

    let pairs = {
        let json = fs::read_to_string(&args.path).map_err(|e| e.to_string())?;
        get_pairs(parse_json(&json)?)?
    };

    let answers = if let Some(answers_path) = args.answers_path
        && let Ok(answers) = fs::read(answers_path)
    {
        Some(answers)
    } else {
        None
    };

    let mut sum = 0.0;
    let mut count = 0;

    for (i, pair) in pairs.iter().enumerate() {
        let haversine = compute_haversine(pair.x0, pair.y0, pair.x1, pair.y1, EARTH_RADIUS_KM);

        if let Some(ref answers) = answers {
            let offset = i * 8;

            let answer = f64::from_le_bytes(answers[offset..offset + 8].try_into().unwrap());
            let difference = (answer - haversine).abs();

            if difference > args.tolerance {
                println!(
                    "Difference ({}): {:.16}\n    Haversine: {:.16}\n    Reference: {:.16}",
                    i + 1,
                    difference,
                    answer,
                    haversine
                );
            }
        }

        sum += haversine;
        count += 1;
    }

    let average = sum / count as f64;

    if let Some(ref answers) = answers {
        let answer_average = f64::from_le_bytes(*answers.last_chunk::<8>().unwrap());

        println!(
            "Difference: {:.16}\nAverage:    {:.16}\nReference:  {:.16}",
            (answer_average - average).abs(),
            average,
            answer_average,
        );
    } else {
        println!("Average: {}", average);
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
