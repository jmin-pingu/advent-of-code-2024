use std::fs::File;
use std::io::{self, BufRead};
use std::path::Path;
 
// first, need to parse "compressed" input 
// then, need to move file blocks to end to left-most free space block,
// likely use double pointer logic
// then \sum fileID * index as a checksum

fn main() {
    part1("./input.txt");
    part2("./input.txt");
}

#[derive(Debug, Clone)]
struct Block {
    id: i32, 
    index: usize, 
    capacity: usize,
}

impl Block {
    pub fn new(id: i32, index: usize, capacity: usize) -> Block {
        Block {
            id,
            index,
            capacity
        }
    }

    pub fn can_fit(&self, other: &Block) -> bool {
        self.capacity >= other.capacity
    }

    pub fn fill_with(&mut self, other: &Block) -> Option<Block> {
        if self.id == -1 && other.id >= 0 && self.can_fit(other) {
            let new_block_idx = self.index;
            self.capacity -= other.capacity;
            self.index += other.capacity;
            Some(Block::new(other.id, new_block_idx, other.capacity))
        } else {
            None
        }
    }
}

fn part2(path: &str) {
    let lines = read_lines(path).expect("file should read");     
    let input: String = lines.flatten().collect::<Vec<String>>()[0].clone();

    // Can use another way to solve this problem with two vectors of index, ID, capacity
    // Can let ID = -1 be '.' free space
    let mut free_layout: Vec<Block> = vec!();
    let mut file_layout: Vec<Block> = vec!();
    let mut idx: usize = 0;

    for (i, c) in input.chars().enumerate() {
        let n = str::parse::<usize>(&c.to_string()).unwrap();
        if n == 0 { continue };
        if i % 2 == 0 {
            file_layout.push(Block::new((i/2).try_into().unwrap(), idx, n));
        } else {
            free_layout.push(Block::new(-1, idx, n));
        }
        idx += n;
    }

    let mut l: usize = 0;
    let mut r = file_layout.len();
    'outer: while r > 0 {
        r -= 1;
        while l < free_layout.len() {
            // Only span free space TO THE LEFT of a fil 
            if free_layout[l].index > file_layout[r].index {
                l = 0;
                continue 'outer;
            }

            while let Some(moved_block) = free_layout[l].fill_with(&file_layout[r]) {
                if free_layout[l].capacity == 0 {free_layout.remove(l);};
                file_layout.remove(r);
                file_layout.push(moved_block);
                l = 0;
                continue 'outer;
            } 
            l += 1;
        }
        l = 0
    }

    let total: u64 = file_layout.into_iter().map(
        |block| {
            (block.index..block.index+block.capacity).map(|v| v as u64 * block.id as u64).sum::<u64>()
        }).sum();
    println!("Part 2 Total: {:?}", total);
}

fn part1(path: &str) {
    let lines = read_lines(path).expect("file should read");     
    let input: String = lines.flatten().collect::<Vec<String>>()[0].clone();

    let mut block_layout: Vec<String> = vec!();
    for (i, c) in input.chars().enumerate() {
        if i % 2 == 0 {
            // input
            block_layout
                .append(
                    &mut [(i/2)]
                    .repeat(
                        str::parse::<usize>(&c.to_string()).unwrap())
                    .into_iter()
                    .map(|v| v.to_string())
                    .collect()
                    );
        } else {
            block_layout
                .append(
                    &mut ["."]
                    .repeat(
                        str::parse::<usize>(&c.to_string()).unwrap())
                    .into_iter()
                    .map(|v| v.to_string())
                    .collect()
                    );
        }
    }

    let mut l: usize = 0;
    let mut r: usize = block_layout.len()-1;
    while l < r-1 {
        // Move left forward to find the first '.' to replace
        while block_layout[l] != "." {
            l += 1;
        } 

        // Move right backward to find the first '.' to replace
        while block_layout[r] == "." {
            r -= 1;
        }
        block_layout[l] = block_layout[r].clone();
        block_layout[r] = ".".to_string();
        r -= 1;
    }

    let block_layout = block_layout.into_iter().filter(|v| v != ".").collect::<Vec<String>>();
    let mut total = 0;
    block_layout
        .into_iter()
        .enumerate()
        .for_each(
            |(i, file_id)| {
                total += i * str::parse::<usize>(&file_id).unwrap();
            }
        );

    println!("Part 1 Total: {:?}", total);
}

// The output is wrapped in a Result to allow matching on errors.
// Returns an Iterator to the Reader of the lines of the file.
fn read_lines<P>(filename: P) -> io::Result<io::Lines<io::BufReader<File>>>
where P: AsRef<Path>, {
    let file = File::open(filename)?;
    Ok(io::BufReader::new(file).lines())
}
