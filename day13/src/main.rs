use std::fs;

#[derive(Debug)]
pub struct Position {
    x: u32,
    y: u32,
}

impl Position {
    pub fn new(x: u32, y: u32) -> Position {
        Position { x, y }
    }
}

#[derive(Debug)]
pub struct Game {
    button_a: Position,
    button_b: Position,

    target: Position,
}

fn main() {
    let data: String = fs::read_to_string("test-input.txt").expect("failed to read file");
    println!("{}", data);
    for part in data.split("\n\n") {
        println!("{:?}", part);
    }
    // TODO: this is a linear programming question
    // fuck it brute force, loop until one of the buttons is greater than X or Y
}
