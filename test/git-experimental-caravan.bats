#!/usr/bin/env bats

setup() {
  PATH="$BATS_TEST_DIRNAME/..:$PATH"

  test_dir="$BATS_TMPDIR/test-git-co-author"
  template_file="$test_dir/test-commit-template"
  template_file_in_home="$HOME/test-commit-template"

  mkdir -p "$test_dir"
  cd "$test_dir" || exit 1

  rm -rf .git/

  rm -rf .git/

  git init
  git config --local commit.template "$template_file"
  git config --local user.name 'Ann Author'
  git config --local user.email 'ann.author@example.com'
  git config --local co-authors.aa 'Ann Author <ann.author@example.com>'
  git config --local co-authors.bb 'Bob Book <bob.book@example.com>'
  git config --local --unset co-authors.ab || true
  git config --local --unset co-authors.bb-2 || true

  touch "$template_file"
  touch "$template_file_in_home"
}

teardown() {
  rm -rf "$template_file"
  rm "$template_file_in_home"
}

@test "no arguments prints nothing when there are no trailers" {
  run git-experimental-caravan
  [ $status -eq 0 ]
  [ "$output" = "" ]
}

@test "no arguments prints co-author trailers when there are co-authors" {
  echo "

Some-token: some value
Co-authored-by: Ann Author <ann.author@example.com>
Co-authored-by: Bob Book <bob.book@example.com>
Card: [pd-01]" > "$template_file"

  run git-experimental-caravan
  [ $status -eq 0 ]
  [ "$output" = "Co-authored-by: Ann Author <ann.author@example.com>
Co-authored-by: Bob Book <bob.book@example.com>
Card: [pd-01]" ]
}

@test "add one mobster and a card to trailers when they are given" {
  run git-experimental-caravan --mob bb --card pd-01

  [ $status -eq 0 ]
  [ "$output" = "Co-authored-by: Bob Book <bob.book@example.com>
Card: [PD-01]" ]
}

@test "add two mobsters and a card to trailers when they are given" {
  run git-experimental-caravan --mob aa bb --card pd-01

  [ $status -eq 0 ]
  [ "$output" = "Co-authored-by: Ann Author <ann.author@example.com>
Co-authored-by: Bob Book <bob.book@example.com>
Card: [PD-01]" ]
}

@test "add a card to trailers when it is given" {
  run git-experimental-caravan --card pd-01

  [ $status -eq 0 ]
  [ "$output" = "Card: [PD-01]" ]
}

@test "add a mobster when it is given" {
  run git-experimental-caravan --mob bb 

  [ $status -eq 0 ]
  [ "$output" = "Co-authored-by: Bob Book <bob.book@example.com>" ]
}
