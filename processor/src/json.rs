use std::collections::HashMap;

#[derive(Debug)]
pub enum Data {
    Null,
    Bool(bool),
    Int(i64),
    Float(f64),
    String(String),
    Array(Vec<Data>),
    Object(HashMap<String, Data>),
}

struct Parser {
    json: String,
    position: usize,
}

pub fn parse_json(json: String) -> Result<HashMap<String, Data>, String> {
    parse_object()
}

pub fn parse_null() -> Result<(), String> {
    todo!()
}

pub fn parse_bool() -> Result<bool, String> {
    todo!()
}

pub fn parse_int() -> Result<i64, String> {
    todo!()
}

pub fn parse_float() -> Result<i64, String> {
    todo!()
}

pub fn parse_string() -> Result<String, String> {
    todo!()
}

pub fn parse_array() -> Result<Vec<Data>, String> {
    todo!()
}

pub fn parse_object() -> Result<HashMap<String, Data>, String> {
    todo!()
}
