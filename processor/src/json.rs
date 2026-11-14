use std::slice::Iter;

#[derive(Debug, PartialEq)]
pub enum Data {
    Null,
    Bool(bool),
    Int(i64),
    Float(f64),
    String(String),
    Array(Array),
    Object(Object),
}

#[derive(PartialEq, Debug)]
pub struct Object(Box<[(String, Data)]>);

impl Object {
    pub fn get(&self, key: &str) -> Option<&Data> {
        for (k, v) in &self.0 {
            if key == k {
                return Some(v);
            }
        }

        None
    }
}

impl From<Vec<(String, Data)>> for Object {
    fn from(value: Vec<(String, Data)>) -> Self {
        Self(value.into_boxed_slice())
    }
}

#[derive(PartialEq, Debug)]
pub struct Array(Box<[Data]>);

impl Array {
    pub fn iter(&self) -> Iter<'_, Data> {
        self.0.iter()
    }
}

impl From<Vec<Data>> for Array {
    fn from(value: Vec<Data>) -> Self {
        Self(value.into_boxed_slice())
    }
}

#[derive(PartialEq, Debug)]
enum Number {
    Int(i64),
    Float(f64),
}

struct Parser<'a> {
    json: &'a [u8],
    position: usize,
}

pub fn parse_json(json: &str) -> Result<Data, String> {
    parse_value(&mut Parser {
        json: json.as_bytes(),
        position: 0,
    })
}

fn parse_value(parser: &mut Parser) -> Result<Data, String> {
    if parser.position >= parser.json.len() {
        return Err("Invalid value".to_string());
    }

    match parser.json[parser.position] {
        b'n' | b'N' => parse_null(parser).map(|_| Data::Null),
        b't' | b'T' | b'f' | b'F' => parse_bool(parser).map(Data::Bool),
        b'0'..=b'9' => parse_number(parser).map(|number| match number {
            Number::Int(number) => Data::Int(number),
            Number::Float(number) => Data::Float(number),
        }),
        b'"' => parse_string(parser).map(Data::String),
        b'[' => parse_array(parser).map(Data::Array),
        b'{' => parse_object(parser).map(Data::Object),
        b' ' | b'\n' => {
            parser.position += 1;
            parse_value(parser)
        }
        ch => return Err(format!("Invalid character: {}", ch)),
    }
}

fn parse_null(parser: &mut Parser) -> Result<(), String> {
    if parser.position + 3 >= parser.json.len()
        || (parser.json[parser.position] != b'n' && parser.json[parser.position] != b'N')
        || (parser.json[parser.position + 1] != b'u' && parser.json[parser.position + 1] != b'U')
        || (parser.json[parser.position + 2] != b'l' && parser.json[parser.position + 2] != b'L')
        || (parser.json[parser.position + 3] != b'l' && parser.json[parser.position + 3] != b'L')
    {
        return Err("Invalid null".to_string());
    }

    parser.position += 4;

    Ok(())
}

fn parse_bool(parser: &mut Parser) -> Result<bool, String> {
    if parser.position >= parser.json.len() {
        return Err("Invalid boolean".to_string());
    }

    let boolean = match parser.json[parser.position] {
        b't' | b'T' => true,
        b'f' | b'F' => false,
        _ => return Err("Invalid boolean".to_string()),
    };

    parser.position += 1;

    Ok(match boolean {
        true => {
            if parser.position + 2 >= parser.json.len()
                || (parser.json[parser.position] != b'r' && parser.json[parser.position] != b'R')
                || (parser.json[parser.position + 1] != b'u'
                    && parser.json[parser.position + 1] != b'U')
                || (parser.json[parser.position + 2] != b'e'
                    && parser.json[parser.position + 2] != b'E')
            {
                return Err("Invalid boolean".to_string());
            }

            parser.position += 3;

            true
        }
        false => {
            if parser.position + 3 >= parser.json.len()
                || (parser.json[parser.position] != b'a' && parser.json[parser.position] != b'A')
                || (parser.json[parser.position + 1] != b'l'
                    && parser.json[parser.position + 1] != b'L')
                || (parser.json[parser.position + 2] != b's'
                    && parser.json[parser.position + 2] != b'S')
                || (parser.json[parser.position + 3] != b'e'
                    && parser.json[parser.position + 3] != b'E')
            {
                return Err("Invalid boolean".to_string());
            }

            parser.position += 4;

            false
        }
    })
}

fn parse_number(parser: &mut Parser) -> Result<Number, String> {
    let mut is_float = false;

    let mut number = String::new();

    loop {
        if parser.position >= parser.json.len() {
            return Ok(if is_float {
                Number::Float(number.parse().map_err(|_| "Invalid number".to_string())?)
            } else {
                Number::Int(number.parse().map_err(|_| "Invalid number".to_string())?)
            });
        }

        let ch = parser.json[parser.position] as char;

        match ch {
            ch @ ('-' | '0'..='9') => {
                number.push(ch);
                parser.position += 1;
            }
            ch @ ('.' | 'e' | 'E') => {
                number.push(ch);
                is_float = true;
                parser.position += 1;
            }
            _ => {
                return Ok(if is_float {
                    Number::Float(number.parse().map_err(|_| "Invalid number".to_string())?)
                } else {
                    Number::Int(number.parse().map_err(|_| "Invalid number".to_string())?)
                });
            }
        }
    }
}

fn parse_string(parser: &mut Parser) -> Result<String, String> {
    if parser.position >= parser.json.len() || parser.json[parser.position] != b'"' {
        return Err("Invalid string".to_string());
    }

    parser.position += 1;

    let mut string = String::new();

    loop {
        if parser.position >= parser.json.len() {
            return Err("Invalid string".to_string());
        }

        let ch = parser.json[parser.position] as char;
        parser.position += 1;

        if ch == '"' {
            return Ok(string);
        }

        string.push(ch);
    }
}

fn parse_array(parser: &mut Parser) -> Result<Array, String> {
    if parser.position >= parser.json.len() || parser.json[parser.position] != b'[' {
        return Err("Invalid array".to_string());
    }

    parser.position += 1;

    let mut array: Vec<Data> = vec![];

    loop {
        if parser.position >= parser.json.len() {
            return Err("Invalid array".to_string());
        }

        let ch = parser.json[parser.position];

        if ch == b',' || ch == b' ' || ch == b'\n' {
            parser.position += 1;
            continue;
        }

        if ch == b']' {
            parser.position += 1;
            return Ok(Array::from(array));
        }

        array.push(parse_value(parser)?);
    }
}

fn parse_object(parser: &mut Parser) -> Result<Object, String> {
    if parser.position >= parser.json.len() || parser.json[parser.position] != b'{' {
        return Err("Invalid object".to_string());
    }

    parser.position += 1;

    let mut object: Vec<(String, Data)> = vec![];

    loop {
        if parser.position >= parser.json.len() {
            return Err("Invalid object".to_string());
        }

        let ch = parser.json[parser.position];

        if ch == b',' || ch == b' ' || ch == b'\n' {
            parser.position += 1;
            continue;
        }

        if ch == b'}' {
            parser.position += 1;
            return Ok(Object::from(object));
        }

        let key = parse_string(parser).map_err(|_| "Invalid object".to_string())?;

        if parser.position >= parser.json.len() || parser.json[parser.position] != b':' {
            return Err("Invalid object".to_string());
        }

        parser.position += 1;

        let value = parse_value(parser)?;

        object.push((key, value));
    }
}

#[cfg(test)]
mod tests {
    use crate::json::{self, Array, Data, Number, Object};

    fn get_parser(json_string: &str) -> json::Parser<'_> {
        json::Parser {
            json: json_string.as_bytes(),
            position: 0,
        }
    }

    #[test]
    fn parse_null() {
        let value = json::parse_null(&mut get_parser("null"));
        assert_eq!(value, Ok(()));
    }

    #[test]
    fn parse_null_caps() {
        let value = json::parse_null(&mut get_parser("NULL"));
        assert_eq!(value, Ok(()));
    }

    #[test]
    fn parse_null_invalid() {
        let value = json::parse_null(&mut get_parser("NIL"));
        assert!(value.is_err());
    }

    #[test]
    fn parse_bool_true() {
        let value = json::parse_bool(&mut get_parser("true"));
        assert_eq!(value, Ok(true));
    }

    #[test]
    fn parse_bool_true_caps() {
        let value = json::parse_bool(&mut get_parser("TRUE"));
        assert_eq!(value, Ok(true));
    }

    #[test]
    fn parse_bool_false() {
        let value = json::parse_bool(&mut get_parser("false"));
        assert_eq!(value, Ok(false));
    }

    #[test]
    fn parse_bool_false_caps() {
        let value = json::parse_bool(&mut get_parser("FALSE"));
        assert_eq!(value, Ok(false));
    }

    #[test]
    fn parse_bool_invalid() {
        let value = json::parse_bool(&mut get_parser("not bool"));
        assert!(value.is_err());
    }

    #[test]
    fn parse_number_int() {
        let value = json::parse_number(&mut get_parser("1234"));
        assert_eq!(value, Ok(Number::Int(1234)));
    }

    #[test]
    fn parse_number_negative_int() {
        let value = json::parse_number(&mut get_parser("-1234"));
        assert_eq!(value, Ok(Number::Int(-1234)));
    }

    #[test]
    fn parse_number_float() {
        let value = json::parse_number(&mut get_parser("2.72"));
        assert_eq!(value, Ok(Number::Float(2.72)));
    }

    #[test]
    fn parse_number_scientific_notation() {
        let value = json::parse_number(&mut get_parser("1e-9"));
        assert_eq!(value, Ok(Number::Float(1e-9)));
    }

    #[test]
    fn parse_number_invalid() {
        let value = json::parse_number(&mut get_parser(""));
        assert!(value.is_err());
    }

    #[test]
    fn parse_string() {
        let value = json::parse_string(&mut get_parser("\"Hello, world!\""));
        assert_eq!(value, Ok("Hello, world!".to_string()));
    }

    #[test]
    fn parse_string_no_leading_quote() {
        let value = json::parse_string(&mut get_parser("Hello, world!\""));
        assert!(value.is_err());
    }

    #[test]
    fn parse_string_no_trailing_quote() {
        let value = json::parse_string(&mut get_parser("\"Hello, world!"));
        assert!(value.is_err());
    }

    #[test]
    fn parse_array_empty() {
        let value = json::parse_array(&mut get_parser("[]"));
        assert_eq!(value, Ok(Array::from(vec![])));
    }

    #[test]
    fn parse_array() {
        let value = json::parse_array(&mut get_parser("[1, null, true, [1.2, \"hi\"]]"));
        assert_eq!(
            value,
            Ok(Array::from(vec![
                Data::Int(1),
                Data::Null,
                Data::Bool(true),
                Data::Array(Array::from(vec![
                    Data::Float(1.2),
                    Data::String("hi".to_string())
                ])),
            ]))
        );
    }

    #[test]
    fn parse_object_empty() {
        let value = json::parse_object(&mut get_parser("{}"));
        assert_eq!(value, Ok(Object::from(vec![])));
    }

    #[test]
    fn parse_object() {
        let value = json::parse_object(&mut get_parser(
            "{\"Int\": 1, \"Null\": null, \"Bool\": true, \"Array\": [{\"Float\": 1.2}, \"hi\"]}",
        ));
        assert_eq!(
            value,
            Ok(Object::from(vec![
                ("Int".to_string(), Data::Int(1)),
                ("Null".to_string(), Data::Null),
                ("Bool".to_string(), Data::Bool(true)),
                (
                    "Array".to_string(),
                    Data::Array(Array::from(vec![
                        Data::Object(Object::from(vec![("Float".to_string(), Data::Float(1.2)),])),
                        Data::String("hi".to_string()),
                    ])),
                ),
            ]))
        );
    }
}
