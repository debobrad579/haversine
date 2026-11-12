use clap::Parser;

fn main() {
    let options = Args::parse();
    println!("{:?}", options);
}

#[derive(Parser, Debug)]
#[clap()]
struct Args {
    count: u32,

    #[clap(short, long, default_value_t = false)]
    cluster: bool,

    #[clap(short, long, default_value_t = 12345678)]
    seed: u32,
}
