use crate::json::Data;

pub struct Pair {
    pub x0: f64,
    pub y0: f64,
    pub x1: f64,
    pub y1: f64,
}

pub fn get_pairs(data: Data) -> Result<Box<[Pair]>, String> {
    if let Data::Object(ref hash_map) = data
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

                Ok(Pair {
                    x0: get_float("x0")?,
                    y0: get_float("y0")?,
                    x1: get_float("x1")?,
                    y1: get_float("y1")?,
                })
            })
            .collect::<Result<Box<_>, String>>()
    } else {
        Err("Invalid data".to_string())
    }
}
