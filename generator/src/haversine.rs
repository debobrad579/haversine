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

#[cfg(test)]
mod tests {
    use super::*;
    use std::f64::consts::PI;

    fn assert_close(actual: f64, expected: f64, tolerance: f64) {
        assert!(
            (actual - expected).abs() <= tolerance,
            "expected {expected} ± {tolerance}, got {actual}"
        );
    }

    #[test]
    fn identical_points() {
        assert_close(
            compute_haversine(12.34, 56.78, 12.34, 56.78, EARTH_RADIUS_KM),
            0.0,
            1e-9,
        );
    }

    #[test]
    fn origin_to_origin() {
        assert_close(
            compute_haversine(0.0, 0.0, 0.0, 0.0, EARTH_RADIUS_KM),
            0.0,
            1e-9,
        );
    }

    #[test]
    fn one_degree_along_equator() {
        assert_close(
            compute_haversine(0.0, 0.0, 1.0, 0.0, EARTH_RADIUS_KM),
            EARTH_RADIUS_KM * PI / 180.0,
            1e-9,
        );
    }

    #[test]
    fn one_degree_along_meridian() {
        assert_close(
            compute_haversine(10.0, 0.0, 10.0, 1.0, EARTH_RADIUS_KM),
            EARTH_RADIUS_KM * PI / 180.0,
            1e-9,
        );
    }

    #[test]
    fn quarter_circumference_equator_to_90_east() {
        assert_close(
            compute_haversine(0.0, 0.0, 90.0, 0.0, EARTH_RADIUS_KM),
            EARTH_RADIUS_KM * PI / 2.0,
            1e-9,
        );
    }

    #[test]
    fn pole_to_equator() {
        assert_close(
            compute_haversine(0.0, 90.0, 0.0, 0.0, EARTH_RADIUS_KM),
            EARTH_RADIUS_KM * PI / 2.0,
            1e-9,
        );
    }

    #[test]
    fn antipodal_points() {
        let expected = EARTH_RADIUS_KM * PI;
        assert_close(
            compute_haversine(0.0, 0.0, 180.0, 0.0, EARTH_RADIUS_KM),
            expected,
            1e-9,
        );
        assert_close(
            compute_haversine(0.0, 90.0, 0.0, -90.0, EARTH_RADIUS_KM),
            expected,
            1e-9,
        );
        assert_close(
            compute_haversine(30.0, 45.0, -150.0, -45.0, EARTH_RADIUS_KM),
            expected,
            1e-9,
        );
    }

    #[test]
    fn longitude_wraps_across_antimeridian() {
        assert_close(
            compute_haversine(179.0, 0.0, -179.0, 0.0, EARTH_RADIUS_KM),
            2.0 * EARTH_RADIUS_KM * PI / 180.0,
            1e-9,
        );
    }

    #[test]
    fn all_longitudes_converge_at_the_pole() {
        assert_close(
            compute_haversine(-120.0, 90.0, 75.0, 90.0, EARTH_RADIUS_KM),
            0.0,
            1e-9,
        );
    }

    #[test]
    fn known_distance_london_to_paris() {
        assert_close(
            compute_haversine(-0.1278, 51.5074, 2.3522, 48.8566, EARTH_RADIUS_KM),
            343.6,
            1.0,
        );
    }

    #[test]
    fn known_distance_new_york_to_los_angeles() {
        assert_close(
            compute_haversine(-74.0060, 40.7128, -118.2437, 34.0522, EARTH_RADIUS_KM),
            3937.0,
            1.0,
        );
    }

    #[test]
    fn zero_radius() {
        assert_eq!(
            compute_haversine(-74.0060, 40.7128, -118.2437, 34.0522, 0.0),
            0.0,
        );
    }
}
