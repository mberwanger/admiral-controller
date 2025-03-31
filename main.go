package main

import "fmt"

var (
	version = "dev"
	commit  = "none"
	date    = "unknown"
	builtBy = "unknown"
)

func main() {
	fmt.Printf("%s, %s, %s, %s, %s", "Admiral Controller", version, commit, date, builtBy)
}
