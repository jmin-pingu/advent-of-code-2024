use std::fs::File;
use std::io::{self, BufRead};
use std::path::Path;
use itertools::Itertools;

fn main() {
    part1();
    part2();
}

fn part2() {
    let mut total: i32 = 0;
    if let Ok(lines) = read_lines("./input.txt") {
        // Consumes the iterator, returns an (Optional) String
        total = lines
            .flatten()
            .map(|line| {
                let line: Vec<i32> = line
                    .split_whitespace()
                    .map(|x| x.parse::<i32>().unwrap())
                    .collect();
                problem_dampener(&line, true, None)
            })
            .map(|v|
                match v {
                    true => 1,
                    false => 0,
            })
            .sum();
    }
    println!("Part 2 Total: {}", total);
}
fn problem_dampener(v: &[i32], first_pass: bool, prev_increasing: Option<bool>) -> bool {
    let mut prev_increasing: Option<bool> = prev_increasing;
    for i in 0..(v.len() - 1) {
        let (valid, increasing) = compare_entry(v[i], v[i+1], prev_increasing);
        if valid {
            prev_increasing = Some(increasing);
        }

        if !valid {
            if first_pass == false {
                return false;
            }
            // If this is the first pass, we can retry with different permutations
            if i == 0 {
                // For i == 0, there is no history of whether the levels are increasing/decreasing
                return problem_dampener(&v[i + 1..], false, None) || problem_dampener(&[&v[i..=i], &v[i + 2..]].concat(), false, None)
            } else if i == 1 {
                // For i == 1, we can "restart" the history of whether the levels are increasing/decreasing

                return problem_dampener(&v[i..], false, None) || problem_dampener(&[&v[i-1..=i - 1], &v[i + 1..]].concat(), false, None)             
            }
            else {
                // For i > 1, we need to follow the history that has been established of whether the levels are increasing/decreasing
                return problem_dampener(&[&v[i - 1..=i], &v[i + 2..]].concat(), false, prev_increasing) || problem_dampener(&[&v[i-1..=i - 1], &v[i + 1..]].concat(), false, prev_increasing)
            }

        }
    }
    return true;
}

fn compare_entry(l: i32, r: i32, prev_increasing: Option<bool>) -> (bool, bool) {
    if (l - r).abs() <= 3 && (l - r).abs() >= 1 && (prev_increasing == None || prev_increasing.unwrap() == (r - l > 0)) {
        return (true, r - l > 0);
    }
    return (false, r - l > 0);
}

fn part1() {
    let mut total: i32 = 0;
    if let Ok(lines) = read_lines("./input.txt") {
        // Consumes the iterator, returns an (Optional) String
        lines.flatten().for_each(|line| {
            let mut monotonic: Vec<bool> = Vec::new();
            let difference_condition = line
                .split_whitespace()
                .map(|x| x.parse::<i32>().unwrap())
                .tuple_windows()
                .all(|(y, x)| {
                    let _ = &monotonic.push(x - y > 0);
                    (x - y).abs() >= 1 && (x - y).abs() <= 3
                });
            if monotonic.windows(2).all(|w| w[0] == w[1]) && difference_condition {
                total += 1;
            }
        });
    }
    println!("Part 1 Total: {}", total);
}

fn read_lines<P>(filename: P) -> io::Result<io::Lines<io::BufReader<File>>>
where P: AsRef<Path>, {
    let file = File::open(filename)?;
    Ok(io::BufReader::new(file).lines())
}
