use std::fs;
use std::io::{self, Write};
use std::path::PathBuf;

use clap::{Parser, value_parser};
use haversine_generator::generate_data::generate_data;

fn main() -> io::Result<()> {
    let args = Args::parse();
    let data = generate_data(args.count, args.seed, args.cluster);

    let mut binary_path = args.json_path.clone();
    binary_path.set_extension("answers.f64");

    let file = fs::File::create(binary_path)?;

    let mut writer = io::BufWriter::new(file);

    for pair in &data.pairs {
        writer.write_all(&pair.haversine.to_le_bytes())?;
    }

    writer.write_all(&data.average.to_le_bytes())?;

    writer.flush()?;

    fs::write(args.json_path, serde_json::to_string(&data).unwrap())?;

    println!("Average: {}", data.average);

    Ok(())
}

#[derive(Parser)]
#[clap()]
struct Args {
    #[arg(value_parser = value_parser!(u32).range(1..=10_000_000))]
    count: u32,

    #[clap(short, long, default_value_t = false)]
    cluster: bool,

    #[clap(short, long, default_value_t = 12345678)]
    seed: u64,

    #[clap(short = 'o', long = "output", default_value = "haversine.json")]
    json_path: PathBuf,
}
