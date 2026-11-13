use std::collections::HashMap;

#[derive(Debug, PartialEq)]
pub enum Data {
    Null,
    Bool(bool),
    Int(i64),
    Float(f64),
    String(String),
    Array(Vec<Data>),
    Object(HashMap<String, Data>),
}

#[derive(PartialEq, Debug)]
enum Number {
    Int(i64),
    Float(f64),
}

struct Parser {
    json: Vec<char>,
    position: usize,
}

pub fn parse_json(json: Vec<char>) -> Result<Data, String> {
    parse_value(&mut Parser { json, position: 0 })
}

fn parse_value(parser: &mut Parser) -> Result<Data, String> {
    if parser.position >= parser.json.len() {
        return Err("Invalid value".to_string());
    }

    match parser.json[parser.position] {
        'n' | 'N' => parse_null(parser).map(|_| Data::Null),
        't' | 'T' | 'f' | 'F' => parse_bool(parser).map(Data::Bool),
        '0'..='9' => parse_number(parser).map(|number| match number {
            Number::Int(number) => Data::Int(number),
            Number::Float(number) => Data::Float(number),
        }),
        '"' => parse_string(parser).map(Data::String),
        '[' => parse_array(parser).map(Data::Array),
        '{' => parse_object(parser).map(Data::Object),
        ' ' => {
            parser.position += 1;
            parse_value(parser)
        }
        ch => return Err(format!("Invalid character: {}", ch)),
    }
}

fn parse_null(parser: &mut Parser) -> Result<(), String> {
    if parser.position + 3 >= parser.json.len()
        || (parser.json[parser.position] != 'n' && parser.json[parser.position] != 'N')
        || (parser.json[parser.position + 1] != 'u' && parser.json[parser.position + 1] != 'U')
        || (parser.json[parser.position + 2] != 'l' && parser.json[parser.position + 2] != 'L')
        || (parser.json[parser.position + 3] != 'l' && parser.json[parser.position + 3] != 'L')
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
        't' | 'T' => true,
        'f' | 'F' => false,
        _ => return Err("Invalid boolean".to_string()),
    };

    parser.position += 1;

    Ok(match boolean {
        true => {
            if parser.position + 2 >= parser.json.len()
                || (parser.json[parser.position] != 'r' && parser.json[parser.position] != 'R')
                || (parser.json[parser.position + 1] != 'u'
                    && parser.json[parser.position + 1] != 'U')
                || (parser.json[parser.position + 2] != 'e'
                    && parser.json[parser.position + 2] != 'E')
            {
                return Err("Invalid boolean".to_string());
            }

            parser.position += 3;

            true
        }
        false => {
            if parser.position + 3 >= parser.json.len()
                || (parser.json[parser.position] != 'a' && parser.json[parser.position] != 'A')
                || (parser.json[parser.position + 1] != 'l'
                    && parser.json[parser.position + 1] != 'L')
                || (parser.json[parser.position + 2] != 's'
                    && parser.json[parser.position + 2] != 'S')
                || (parser.json[parser.position + 3] != 'e'
                    && parser.json[parser.position + 3] != 'E')
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

        let ch = parser.json[parser.position];

        match ch {
            ch @ '0'..='9' => {
                number.push(ch);
                parser.position += 1;
            }
            '.' => {
                number.push('.');
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
    if parser.position >= parser.json.len() || parser.json[parser.position] != '"' {
        return Err("Invalid string".to_string());
    }

    parser.position += 1;

    let mut string = String::new();

    loop {
        if parser.position >= parser.json.len() {
            return Err("Invalid string".to_string());
        }

        let ch = parser.json[parser.position];
        parser.position += 1;

        if ch == '"' {
            return Ok(string);
        }

        string.push(ch);
    }
}

fn parse_array(parser: &mut Parser) -> Result<Vec<Data>, String> {
    if parser.position >= parser.json.len() || parser.json[parser.position] != '[' {
        return Err("Invalid array".to_string());
    }

    parser.position += 1;

    let mut array: Vec<Data> = vec![];

    loop {
        if parser.position >= parser.json.len() {
            return Err("Invalid array".to_string());
        }

        let ch = parser.json[parser.position];

        if ch == ',' {
            parser.position += 1;
            continue;
        }

        if ch == ']' {
            parser.position += 1;
            return Ok(array);
        }

        array.push(parse_value(parser)?);
    }
}

fn parse_object(parser: &mut Parser) -> Result<HashMap<String, Data>, String> {
    todo!()
}

#[cfg(test)]
mod tests {
    use crate::json::{self, Data, Number};

    fn get_parser(json_string: &str) -> json::Parser {
        json::Parser {
            json: json_string.chars().collect(),
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
    fn parse_number_float() {
        let value = json::parse_number(&mut get_parser("2.72"));
        assert_eq!(value, Ok(Number::Float(2.72)));
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
        assert_eq!(value, Ok(vec![]));
    }

    #[test]
    fn parse_array() {
        let value = json::parse_array(&mut get_parser("[1, null, true, [1.2, \"hi\"]]"));
        assert_eq!(
            value,
            Ok(vec![
                Data::Int(1),
                Data::Null,
                Data::Bool(true),
                Data::Array(vec![Data::Float(1.2), Data::String("hi".to_string())]),
            ])
        );
    }
}
