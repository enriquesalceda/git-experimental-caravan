#!/usr/bin/env bats

@test "1 + 1 equals 2" {
  result="$(echo 1 + 1 | bc)"
  [ "$result" -eq 2 ]
}
