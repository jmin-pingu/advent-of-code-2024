use std::fs::File;
use std::io::{self, BufRead};
use std::path::Path;
use std::collections::{HashMap, BinaryHeap};
 
fn main() {
    part1();
    part2();
}

fn part1() {
    let mut left_heap = BinaryHeap::new();
    let mut right_heap = BinaryHeap::new();
    let mut total: i32 = 0;
    // File hosts.txt must exist in the current path
    if let Ok(lines) = read_lines("./input.txt") {
        // Consumes the iterator, returns an (Optional) String
        lines.flatten().for_each(|line| {
            let split: Vec<&str> = line.split_whitespace().collect();
            left_heap.push(split[0].parse::<i32>().unwrap());
            right_heap.push(split[1].parse::<i32>().unwrap());
        });
    }
    while let (Some(left_val), Some(right_val)) = (left_heap.pop(), right_heap.pop()){
        total += (left_val - right_val).abs();
    }
    println!("Part 1 Answer: {}", total);
}

fn part2() {
    let mut left_counts: HashMap<i32, i32> = HashMap::new();
    let mut right_counts: HashMap<i32, i32> = HashMap::new();
    let mut total: i32 = 0;
    // File hosts.txt must exist in the current path
    if let Ok(lines) = read_lines("./input.txt") {
        // Consumes the iterator, returns an (Optional) String
        lines.flatten().for_each(|line| {
            let split: Vec<&str> = line.split_whitespace().collect();
            *left_counts.entry(split[0].parse::<i32>().unwrap()).or_insert(0) += 1;
            *right_counts.entry(split[1].parse::<i32>().unwrap()).or_insert(0) += 1;
        });
    }
 
    for (num, multiplicity) in left_counts.into_iter() {
        total += num * multiplicity * *right_counts.entry(num).or_insert(0);
    }

    println!("Part 2 Answer: {}", total);
}

// The output is wrapped in a Result to allow matching on errors.
// Returns an Iterator to the Reader of the lines of the file.
fn read_lines<P>(filename: P) -> io::Result<io::Lines<io::BufReader<File>>>
where P: AsRef<Path>, {
    let file = File::open(filename)?;
    Ok(io::BufReader::new(file).lines())
}
