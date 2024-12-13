mod grid;

use std::fs::File;
use std::io::{self, BufRead};
use std::path::Path;
use std::collections::{HashMap, HashSet};

fn main() {
    part1("input.txt");
    part2("input.txt");
}

fn part2(path: &str) {
    let lines = read_lines(path).expect("file should read");     
    let mut start_coords: HashSet<grid::Coordinate> = HashSet::new();
    let layout: Vec<Vec<i32>> = lines
        .flatten()
        .enumerate()
        .map(
            |(y_idx, v)| v.chars().enumerate().map(
                |(x_idx, ch)| {
                    let d = ch.to_digit(10).unwrap() as i32;
                    if d == 0 {start_coords.insert(grid::Coordinate::new(x_idx.try_into().unwrap(), y_idx.try_into().unwrap()));}
                    d 
                }).collect::<Vec<i32>>()
            )
        .collect();
    let grid = grid::Grid::new(layout);

    let mut start_coords_it = start_coords.drain();
    let mut total = 0;
    while let Some(coord) = start_coords_it.next() {
        let mut ratings: HashMap<grid::Coordinate, u32> = HashMap::new();
        grid.search_rating(coord, &mut ratings);
        total += ratings.into_iter().map(|(_, v)| v).sum::<u32>();
    }
    println!("Total Part 2: {:?}", total);
}


fn part1(path: &str) {
    let lines = read_lines(path).expect("file should read");     
    let mut start_coords: HashSet<grid::Coordinate> = HashSet::new();
    let layout: Vec<Vec<i32>> = lines
        .flatten()
        .enumerate()
        .map(
            |(y_idx, v)| v.chars().enumerate().map(
                |(x_idx, ch)| {
                    let d = ch.to_digit(10).unwrap() as i32;
                    if d == 0 {start_coords.insert(grid::Coordinate::new(x_idx.try_into().unwrap(), y_idx.try_into().unwrap()));}
                    d 
                }).collect::<Vec<i32>>()
            )
        .collect();
    let grid = grid::Grid::new(layout);

    let mut start_coords_it = start_coords.drain();
    let mut total = 0;
    while let Some(coord) = start_coords_it.next() {
        let mut reachable: HashSet<grid::Coordinate> = HashSet::new();
        grid.search(coord, &mut reachable);
        total += reachable.len();
    }
    println!("Total Part 1: {:?}", total);
}

// The output is wrapped in a Result to allow matching on errors.
// Returns an Iterator to the Reader of the lines of the file.
fn read_lines<P>(filename: P) -> io::Result<io::Lines<io::BufReader<File>>>
where P: AsRef<Path>, {
    let file = File::open(filename)?;
    Ok(io::BufReader::new(file).lines())
}
