#!/bin/bash

readonly CO_AUTHOR_TRAILER_TOKEN="Co-authored-by"
readonly CARD_TRAILER_TOKEN="Card"
readonly USAGE="usage: git caravan show all trailer in commit template
  or: git caravan -m <initials>...      add the mob that contributed to the commit
  or: git caravan -c <card>             add the jira, trello, whatever you use card
  or: git caravan -w                    wash the caravan! clean all trailers
  or: git caravan -fm                   find mobster
"

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

  if [[ $# -eq 1 ]]; then
    if [[ $1 == "-w" || $1 == "--wash"  ]]; then
      wash_the_caravan
    fi

    if [[ $1 == "-fm" || $1 == "--findmobsters"  ]]; then
      find_mobsters
    fi
  fi
 

  while [[ $# -gt 0 ]]; do
      key="$1"
      
      case $key in
          -m|--mob)
              shift # remove -a from the list of arguments
              # While there are arguments and the next one doesn't start with '-'
              while [[ $# -gt 0 ]] && [[ "$1" != -* ]]; do
                  users+=("$1")
                  shift # remove the current user from the list of arguments
              done
              ;;
          -c|--card)
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
  ensure_git_commit_template_exists
  print_trailers
  exit 0
}

print_trailers() {
  sed -n "/$CO_AUTHOR_TRAILER_TOKEN/p" "$template_file"
  sed -n "/$CARD_TRAILER_TOKEN/p" "$template_file"
}

ensure_git_commit_template_exists() {
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
  uppercase_card=$(echo "$card" | tr 'a-z' 'A-Z')
  git interpret-trailers --trailer "$CARD_TRAILER_TOKEN: [$uppercase_card]" --in-place "$template_file"
}

update_trailers() {
  ensure_git_commit_template_exists
  find_and_remove_current_trailers

  if [[ $users ]]; then
    add_co_authors
  fi

  if [[ $card ]]; then
    add_card
  fi

  print_trailers

  exit 0
}

wash_the_caravan() {
  ensure_git_commit_template_exists
  find_and_remove_current_trailers
  exit 0
}

find_and_remove_current_trailers() {
  local temp_file
  temp_file=$(mktemp)
  sed -e "/$CARD_TRAILER_TOKEN/d" -e "/$CO_AUTHOR_TRAILER_TOKEN/d" "$template_file" > "$temp_file"
  mv "$temp_file" "$template_file"
}

find_mobsters() {
  {
    git log --pretty="%an <%ae>";
    git log --pretty="%(trailers:key=Co-authored-by,valueonly,only)" | awk NF;
  } | sort | uniq
  exit 0
}

main "$@"
