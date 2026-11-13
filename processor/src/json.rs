use std::collections::HashMap;

#[derive(Debug)]
pub enum Data {
    Object(HashMap<String, Data>),
    Array(Vec<Data>),
    String(String),
    Int(i64),
    Float(f64),
    Bool(bool),
}

pub fn parse_json(json: Vec<char>) -> HashMap<String, Data> {
    let hashmap = HashMap::new();

    json.iter().for_each(|byte| match *byte {
        '{' => {}
        '}' => {}
        '[' => {}
        ']' => {}
        '"' => {}
        '.' => {}
        '0'..='9' => {}
        'a'..='z' | 'A'..='Z' | '_' => {}
        _ => {}
    });

    println!("{:?}, {:?}", json, hashmap);

    hashmap
}
