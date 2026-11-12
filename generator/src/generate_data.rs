use rand::rngs::StdRng;
use rand::{RngExt, SeedableRng};
use serde::Serialize;

use crate::haversine::{EARTH_RADIUS_KM, compute_haversine};

#[derive(Debug, Serialize)]
pub struct Data {
    pub pairs: Vec<PointPair>,

    #[serde(skip_serializing)]
    pub average: f64,
}

#[derive(Debug, Serialize)]
pub struct PointPair {
    pub x0: f64,
    pub y0: f64,
    pub x1: f64,
    pub y1: f64,

    #[serde(skip_serializing)]
    pub haversine: f64,
}

pub fn generate_data(count: u32, seed: u64) -> Data {
    let mut pairs = vec![];
    let mut sum = 0.0;

    let mut rng = StdRng::seed_from_u64(seed);

    for _ in 0..count {
        let x0 = rng.random_range(0.0..360.0);
        let x1 = rng.random_range(0.0..360.0);
        let y0 = rng.random_range(0.0..360.0);
        let y1 = rng.random_range(0.0..360.0);

        let haversine = compute_haversine(x0, y0, x1, y1, EARTH_RADIUS_KM);

        pairs.push(PointPair {
            x0,
            x1,
            y0,
            y1,
            haversine,
        });
        sum += haversine;
    }

    Data {
        pairs,
        average: sum / count as f64,
    }
}
