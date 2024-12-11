package main

import (
	"fmt"
	"os"
	"regexp"
	"strconv"
)

func main() {
	data, err := os.ReadFile("./input.txt")
	if err != nil {
		fmt.Println("Error:", err)
		return
	}
	var input string = string(data)
	fmt.Printf("Part 1 Answer: %v\n", parse(input))

	r := regexp.MustCompile("(?s)don\\'t\\(\\).*?(do\\(\\)|$)")
	new_input := r.ReplaceAllString(input, "")
	fmt.Printf("Part 2 Answer: %v\n", parse(new_input))
	parse(new_input)
}

func parse(input string) int {
	r := regexp.MustCompile("mul\\(([0-9]{1,}),([0-9]{1,})\\)")
	matches := r.FindAllStringSubmatch(input, -1)

	var total int = 0
	for _, match := range matches {
		m1, _ := strconv.Atoi(match[1])
		m2, _ := strconv.Atoi(match[2])
		total += m1 * m2
	}

	return total
}
