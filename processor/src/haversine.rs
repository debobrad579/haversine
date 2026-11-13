use std::f64::consts::PI;

pub const EARTH_RADIUS_KM: f64 = 6372.8;

pub fn compute_haversine(x0: f64, y0: f64, x1: f64, y1: f64, radius: f64) -> f64 {
    let d_lat = (y1 - y0) * PI / 180.0;
    let d_lon = (x1 - x0) * PI / 180.0;
    let lat1 = y0 * PI / 180.0;
    let lat2 = y1 * PI / 180.0;

    let a = square(f64::sin(d_lat / 2.0))
        + f64::cos(lat1) * f64::cos(lat2) * square(f64::sin(d_lon / 2.0));
    let c = 2.0 * f64::asin(f64::sqrt(a));

    radius * c
}

fn square(x: f64) -> f64 {
    x * x
}
