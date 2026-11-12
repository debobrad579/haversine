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

pub fn generate_data(count: u32, seed: u64, cluster: bool) -> Data {
    let mut pairs = vec![];
    let mut sum = 0.0;

    let mut rng = StdRng::seed_from_u64(seed);

    if cluster {
        const CLUSTERS: u32 = 64;

        let per_cluster = count.div_ceil(CLUSTERS);

        let mut generated = 0;
        while generated < count {
            let half = rng.random_range(2.0..60.0);

            let c0x = rng.random_range(half..360.0 - half);
            let c0y = rng.random_range(half..360.0 - half);
            let c1x = rng.random_range(half..360.0 - half);
            let c1y = rng.random_range(half..360.0 - half);

            let n = per_cluster.min(count - generated);
            for _ in 0..n {
                let x0 = c0x + rng.random_range(-half..half);
                let y0 = c0y + rng.random_range(-half..half);
                let x1 = c1x + rng.random_range(-half..half);
                let y1 = c1y + rng.random_range(-half..half);

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

            generated += n;
        }
    } else {
        for _ in 0..count {
            let x0 = rng.random_range(0.0..360.0);
            let y0 = rng.random_range(0.0..360.0);
            let x1 = rng.random_range(0.0..360.0);
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
    }

    Data {
        pairs,
        average: sum / count as f64,
    }
}
