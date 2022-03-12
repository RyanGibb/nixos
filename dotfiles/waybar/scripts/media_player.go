package main

import (
	"fmt"
	"os/exec"
	"strings"
	"time"
)

func main() {
	const NUM_PLAYERS int = 1
	const SLEEP_TIME time.Duration = time.Second;
	const MAX_WIDTH int = 24

	var prev_player_string string = ""
	var i int = 0

	for {
		cmd := exec.Command("playerctl", "-l")
		stdout, _ := cmd.Output()

		player := strings.Split(string(stdout),"\n")[0]

		if player == "" {
			time.Sleep(SLEEP_TIME)
			fmt.Println("")
			continue
		}

		title, _ :=  exec.Command("playerctl", fmt.Sprintf("--player=%s", player), "metadata", "title").Output()
		artist, _ := exec.Command("playerctl", fmt.Sprintf("--player=%s", player), "metadata", "artist").Output()
		seperator := " "
		if len(title) > 0 {
			seperator = " - "
		}
		player_string := fmt.Sprintf(
			"%s%s%s",
			strings.TrimSuffix(string(title), "\n"),
			seperator,
			strings.TrimSuffix(string(artist), "\n"),
		)

		if prev_player_string != player_string {
			prev_player_string = player_string
			i = 0
		}

		if len(player_string) >= MAX_WIDTH {
			player_string += " | "
		}

		player_string_rune := []rune(player_string)

		if strings.Contains(player, "spotify") {
			fmt.Print("")
		}
		if strings.Contains(player, "firefox") {
			fmt.Print("")
		}
		if strings.Contains(player, "kde") {
			fmt.Print("")
		}

		fmt.Print(string(player_string_rune[i:min(len(player_string_rune), i+MAX_WIDTH)]))
		fmt.Println(string(player_string_rune[0:min(max(0, MAX_WIDTH-len(player_string_rune)+i), i)]))
		i = (i + 1) % len(player_string_rune)

		time.Sleep(SLEEP_TIME)
	}
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}

