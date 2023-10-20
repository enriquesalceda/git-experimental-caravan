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
    ensure_template_file
    # echo "nothing to do"
    exit 0
  fi

  while [[ $# -gt 0 ]]; do
      key="$1"
      
      case $key in
          -a)
              shift # remove -a from the list of arguments
              # While there are arguments and the next one doesn't start with '-'
              while [[ $# -gt 0 ]] && [[ "$1" != -* ]]; do
                  users+=("$1")
                  shift # remove the current user from the list of arguments
              done
              show_users
              ;;
          -c)
              card="$2"
              shift # remove -c
              shift # remove its argument
              show_card
              ;;
          *)
              echo "Invalid option: $1" >&2
              exit 1
              ;;
      esac
  done
}

# Print the results
show_users() {
  echo "Users are:"
  for user in "${users[@]}"; do
      echo "- $user"
  done
}

show_card() {
  echo ""
  echo "Card: $card"
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

main "$@"
