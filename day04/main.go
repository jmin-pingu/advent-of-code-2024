package main

import (
	"fmt"
	"os"
	"strings"
)

type Grid struct {
	data []string
}

func NewGrid(data []string) Grid {
	return Grid{data: data}
}

func main() {
	data, err := os.ReadFile("./input.txt")
	if err != nil {
		fmt.Println("Error:", err)
		return
	}

	var lines []string = strings.Split(string(data), "\n")

	part1(lines)
	part2(lines)
}

func (b *Grid) pad(padding int) {
	height_pad := strings.Repeat("0", padding*2+len(b.data[0]))
	for i, _ := range b.data {
		b.data[i] = "000" + b.data[i] + "000"
	}

	for k := 0; k < padding; k++ {
		b.data = append([]string{height_pad}, b.data...)
		b.data = append(b.data, height_pad)
	}
}

// Part 1 Code
func part1(lines []string) {
	grid := NewGrid(lines[:len(lines)-1])
	grid.pad(3)
	total := grid.part1_search("XMAS")
	fmt.Printf("Part 1 Answer: %v\n", total)
}

func (b *Grid) part1_search(s string) int {
	total := 0
	var count int
	for y, line := range b.data {
		for x, _ := range line {
			count = 0
			if b.data[y][x] == s[0] {
				count = b.star_search(x, y, s)
				// fmt.Printf("X:%v ", count)
				total += count
			} else {
				// fmt.Printf("    ")
			}
		}
		// fmt.Println("")
	}
	return total
}

func (b *Grid) star_search(x int, y int, s string) int {
	total := 0
	var x_movement, y_movement []int
	var k, init_x, init_y, x_dir, y_dir int
	x_movement = []int{-1, 0, 1}
	y_movement = []int{-1, 0, 1}
	init_x = x
	init_y = y

out:
	for _, permutation := range permute(x_movement, y_movement) {
		x = init_x
		y = init_y

		x_dir = permutation[0]
		y_dir = permutation[1]
		for k = 1; k < len(s); k++ {
			x += x_dir
			y += y_dir
			if s[k] != b.data[y][x] {
				continue out
			}
		}
		total += 1
	}
	return total
}

func permute(t1 []int, t2 []int) [][]int {
	var permutations [][]int
	for _, v1 := range t1 {
		for _, v2 := range t2 {
			if v1 == 0 && v2 == 0 {
				continue
			}
			permutations = append(permutations, []int{v1, v2})
		}
	}
	return permutations
}

// Part 2: Code
func part2(lines []string) {
	grid := NewGrid(lines[:len(lines)-1])
	grid.pad(1)
	total := grid.part2_search("A", []string{"M", "S"})
	fmt.Printf("Part 2 Answer: %v\n", total)
}

func (b *Grid) part2_search(center string, ends []string) int {
	total := 0
	var count int
	for y, line := range b.data {
		for x, _ := range line {
			count = 0
			if b.data[y][x] == center[0] {
				count = b.cross_search(x, y, ends)
				total += count
			}
		}
	}
	return total
}

func (b *Grid) cross_search(x int, y int, ends []string) int {
	for _, p := range [][]int{[]int{-1, 1}, []int{1, 1}} {
		if (ends[0] != string(b.data[y+p[0]][x+p[1]]) || ends[1] != string(b.data[y-p[0]][x-p[1]])) && (ends[1] != string(b.data[y+p[0]][x+p[1]]) || ends[0] != string(b.data[y-p[0]][x-p[1]])) {
			return 0
		}
	}
	return 1
}
