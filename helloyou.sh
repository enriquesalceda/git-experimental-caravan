#!/bin/bash

readonly CO_AUTHOR_TRAILER_TOKEN="Co-authored-by"
readonly CARD_TRAILER_TOKEN="Card"
readonly USAGE="usage: git idc"

# Initialize an empty array for users and an empty string for card
users=()
card=""

# Parsing options manually, because `getopts` has limitations for our use case
main() {
  if [[ $# -eq 0 ]]
  then
    current_trailers
    exit 0
  fi

  while [[ $# -gt 0 ]]; do
      key="$1"
      
      case $key in
          clean)
            remove_trailers
            ;;
          -a)
              shift # remove -a from the list of arguments
              # While there are arguments and the next one doesn't start with '-'
              while [[ $# -gt 0 ]] && [[ "$1" != -* ]]; do
                  users+=("$1")
                  shift # remove the current user from the list of arguments
              done
              ;;
          -c)
              card="$2"
              shift # remove -c
              shift # remove its argument
              ;;
          *)
              echo "Invalid option: $1" >&2
              exit 1
              ;;
      esac
  done

  update_trailers
}

current_trailers() {
  ensure_template_file
  print_trailers
  exit 0
}

print_trailers() {
  sed -n "/$CO_AUTHOR_TRAILER_TOKEN/p" "$template_file"
  sed -n "/$CARD_TRAILER_TOKEN/p" "$template_file"
}

ensure_template_file() {
  must_have_config "commit.template" "commit template is not configured

Example:
  git config --global commit.template '~/.git-commit-template'"

  template_file=$(git config commit.template)
  template_file="${template_file/#\~/$HOME}"

  touch "$template_file"
}

must_have_config() {
  local key=$1
  local error=$2
  if ! git config "$key" &> /dev/null
  then
    abort "$error"
  fi

  if [[ -z $(git config "$key") ]]
  then
    abort "$error"
  fi
}

add_co_authors() {
  for initials in "${users[@]}"
  do
    value=$(git config "co-authors.$initials")
    git interpret-trailers --trailer "$CO_AUTHOR_TRAILER_TOKEN: $value" --in-place "$template_file"
  done
}

add_card() {
  git interpret-trailers --trailer "$CARD_TRAILER_TOKEN: $card" --in-place "$template_file"
}

update_trailers() {
  ensure_template_file
  remove_trailers

  if [[ $users ]]; then
    add_co_authors
  fi

  if [[ $card ]]; then
    add_card
  fi

  print_trailers

  exit 0
}

remove_trailers() {
  ensure_template_file
  remove_trailers
  exit 0
}

remove_trailers() {
  local temp_file
  temp_file=$(mktemp)
  sed -e "/$CARD_TRAILER_TOKEN/d" -e "/$CO_AUTHOR_TRAILER_TOKEN/d" "$template_file" > "$temp_file"
  mv "$temp_file" "$template_file"
}

main "$@"
