use std::collections::{HashMap, HashSet};
use strum::IntoEnumIterator; 
use strum_macros::EnumIter;

#[derive(Clone, Debug, Eq, Hash, PartialEq)]
pub struct Coordinate {
    pub x: i32,
    pub y: i32,
}

impl Coordinate {
    pub fn new(x: i32, y: i32) -> Coordinate {
        Coordinate {x, y}
    }

    pub fn add(&self, coordinate: &Coordinate) -> Coordinate {
        Coordinate::new(self.x + coordinate.x, self.y + coordinate.y)
    }
}

#[derive(Debug)]
struct Bound {
    lower: i32, 
    upper: i32, 
}

impl Bound {
    pub fn new(lower: i32, upper: i32) -> Bound {
        Bound {lower, upper}
    }

    pub fn in_bound(&self, value: i32) -> bool {
        value <= self.upper && value >= self.lower
    }
}

#[derive(Debug, EnumIter)]
enum Direction{
    Up, 
    Down, 
    Left, 
    Right
}

#[derive(Debug)]
pub struct Grid {
    layout: Vec<Vec<i32>>,
    x_bound: Bound,
    y_bound: Bound,
    end_value: i32,
}

impl Grid {
    pub fn new(layout: Vec<Vec<i32>>) -> Grid {
        let x_upper = layout[0].len() as i32 - 1;
        let y_upper = layout.len() as i32 - 1;
        Grid {
            layout,
            x_bound: Bound::new(0, x_upper),
            y_bound: Bound::new(0, y_upper),
            end_value: 9
        }
    }

    pub fn valid_point(&self, coordinate: &Coordinate) -> bool {
        self.x_bound.in_bound(coordinate.x) && self.y_bound.in_bound(coordinate.y)
    }

    pub fn get(&self, coordinate: &Coordinate) -> Option<i32> {
        if !self.valid_point(coordinate) { return None; }
        Some(self.layout[coordinate.y as usize][coordinate.x as usize])
    }

    pub fn search(&self, coordinate: Coordinate, reachable: &mut HashSet<Coordinate>) -> () {
        if let Some(value) = self.get(&coordinate) {
            if value == self.end_value { 
                reachable.insert(coordinate);
                return;
            }
        } else {
            return;
        }

        Direction::iter().for_each(|direction| {
            let new_coordinate = match direction {
                Direction::Up => {
                    coordinate.add(&Coordinate::new(0, 1))
                },
                Direction::Down => {
                    coordinate.add(&Coordinate::new(0, -1))
                },
                Direction::Left => {
                    coordinate.add(&Coordinate::new(-1, 0))
                },
                Direction::Right => {
                    coordinate.add(&Coordinate::new(1, 0))
                }
            };
            if let (Some(new_value), Some(old_value)) = (self.get(&new_coordinate), self.get(&coordinate)) {
                if new_value == old_value + 1 && self.valid_point(&new_coordinate) { 
                    self.search(new_coordinate, reachable)
                }
            }
        })
    }

    pub fn search_rating(&self, coordinate: Coordinate, rating: &mut HashMap<Coordinate, u32>) -> () {
        if let Some(value) = self.get(&coordinate) {
            if value == self.end_value { 
                *rating.entry(coordinate).or_insert(0) += 1;
                return;
            }
        } else {
            return;
        }

        Direction::iter().for_each(|direction| {
            let new_coordinate = match direction {
                Direction::Up => {
                    coordinate.add(&Coordinate::new(0, 1))
                },
                Direction::Down => {
                    coordinate.add(&Coordinate::new(0, -1))
                },
                Direction::Left => {
                    coordinate.add(&Coordinate::new(-1, 0))
                },
                Direction::Right => {
                    coordinate.add(&Coordinate::new(1, 0))
                }
            };
            if let (Some(new_value), Some(old_value)) = (self.get(&new_coordinate), self.get(&coordinate)) {
                if new_value == old_value + 1 && self.valid_point(&new_coordinate) { 
                    self.search_rating(new_coordinate, rating)
                }
            }
        })
    }
}
