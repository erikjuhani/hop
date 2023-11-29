#!/usr/bin/env sh

set -e

err() {
  printf >&2 "error: %s\n" "$@"
  exit 1
}

require() {
  for arg; do
    if ! command -v "${arg}" >/dev/null; then
      missing_commands="${missing_commands}\"${arg}\" "
    fi
  done

  if [ -n "${missing_commands}" ]; then
    printf "%s\n" "cannot find command ${missing_commands}"
    help
  fi
}

require aoc sqlite3

help() {
  cat <<EOF
hop
Get advent of code puzzle description and input data or submit answers to
puzzles! By default gets advent of code puzzle and input by current date. Give
year and day as an input to get a specific puzzle. This shell script uses
https://github.com/scarvalhojr/aoc-cli/blob/main/aoc-client under the hood.

Other then puzzle and answer commands will be redirected to aoc-cli. For
example you can check the current calendar by calling "hop calendar".

USAGE
	hop [<command>] [<args>] [-h | --help]

COMMANDS
	puzzle	Get puzzle by given year and day or current date.
	answer	Submit puzzle solution for given year and day or current date, by default answers the first available part.

OPTIONS
	-h --help	Show help

For additional help use hop <command> -h
EOF
  exit 2
}

help_puzzle() {
  cat <<EOF
hop puzzle
Gets current puzzle and input or specific puzzle with year and day input.

USAGE
	puzzle [-d | --day <day>] [-y | --year <year>] [-h | --help]

OPTIONS
	-d --day	<day> puzzle and input day
	-y --year	<year> puzzle and input year
	-h --help	Show help

EXAMPLES
	Fetch the current puzzle and input
	hop puzzle

	Fetch a specific puzzle and input
	hop puzzle --year 2022 --day 14

For additional help use hop <command> -h
EOF
  exit 2
}

help_answer() {
  cat <<EOF
hop answer
Anwer to current puzzle or a specific puzzle with year and day input. The
answer is given as an argument. To send answers subsequent parts, you need
provide the --part option as --part 2.

USAGE
	answer [-p | --part <part>] [-d | --day <day>] 
        [-y | --year <year>] [-h | --help] [<answer>]

OPTIONS
	-p --part	puzzle part
	-d --day	puzzle day
	-y --year	puzzle year
	-h --help	Show help

EXAMPLES
	Sending an answer to the current puzzle
	hop answer 311223

	Sending an answer to a specific puzzle, when the first part is completed
	hop answer --part 2 --year 2022 --day 14 311223

For additional help use hop <command> -h
EOF
  exit 2
}

enum() {
  enum_str="$1"
  shift
  for arg; do
    enum_str="${enum_str}|${arg}"
  done

  printf "^(%s)$" "${enum_str}"
}

parse_command() {
  if printf "%s" "$1" | grep -qE "$2"; then
    readonly CMD="$1"
  fi
}

# TODO get operating system and decide which operation to use
get_default_browser() {
  # macos only
  defaults read ~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure | awk -F'"' '/http;/{print window[(NR)-1]}{window[NR]=$2}'
}

get_firefox_session_cookie() {
  cookies_db="$(find "${HOME}/Library/Application Support/Firefox" -name cookies.sqlite)"
  query="SELECT value FROM moz_cookies WHERE name = 'session' AND host = '.adventofcode.com' LIMIT 1;"

  # This is needed if the requested browser is already running since it will lock the cookie database
  tmp_cookies_db="$(mktemp)"

  cat "${cookies_db}" >"${tmp_cookies_db}"

  sqlite3 -list "${tmp_cookies_db}" "${query}"
}

set_session_cookie() {
  browser="$(get_default_browser)"

  case "${browser}" in
    *firefox)
      browser=${browser##*.}
      get_firefox_session_cookie >"${HOME}/.adventofcode.session"
      ;;
    *)
      printf "%s\n" "Default browser not found or not supported, got ${browser}, expected firefox"
      printf "%s\n" "If not using firefox the SESSION COOKIE needs to be set manually to ${HOME}/.adventofcode.session"
      ;;
  esac

  if [ -z "$(cat "${HOME}/.adventofcode.session")" ]; then
    printf "%s" "Please login to ${AOC_BASE_URL}, then try to run this script again"
    # TODO: Use the auth method from flag if specified $AUTH_METHOD=$(enum github google twitter reddit)
    auth="${AUTH_METHOD:-login}"
    open -a "${browser}" "${AOC_BASE_URL}/auth/${auth}"
    exit 1
  fi
}

DECEMBER=12

# The year when the Advent of Code started
MIN_YEAR=2015

# The maximum day value in the advent calendar in Advent of Code
MAX_DAY=25

# The puzzle opens at 00:00 UTC-5
# The constant is used to check that the current UTC date is greater or equal to this value
TIMEZONE_DIFFERENCE=5

puzzle() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --help | -h)
        help_puzzle
        ;;
      --day | -d)
        [ -z "$2" ] && err "No value provided for flag, expected $1 <value>, got $1"
        day_arg="$2"
        shift
        ;;
      --year | -y)
        [ -z "$2" ] && err "No value provided for flag, expected $1 <value>, got $1"
        year_arg="$2"
        shift
        ;;
    esac
    shift
  done

  dates="$(parse_dates "${year_arg}" "${day_arg}")"

  year="$(printf "%s" "${dates}" | cut -d ';' -f 1)"
  day="$(printf "%s" "${dates}" | cut -d ';' -f 2)"

  input_path="${year}/input"
  puzzle_path="${year}/puzzle"

  printf "🧩 %s\n" "Fetching puzzle description and input for day ${day}, ${year}"

  mkdir -p "${input_path}"
  mkdir -p "${puzzle_path}"

  aoc download --year "${year}" --day "${day}" --input-file "${input_path}/day${day}" --puzzle-file "${puzzle_path}/day${day}.md"
}

parse_dates() {
  year_arg="$1"
  day_arg="$2"

  current_year="$(date +%Y)"
  current_day="$(date +%d)"
  current_month="$(date +%m)"
  current_utc_hour="$(date -u +%H)"

  year_arg="${year_arg:-$current_year}"

  [ "${current_month}" -eq 12 ] && day_arg="${day_arg:-$current_day}"

  if [ -n "${year_arg}" ] && [ -z "${day_arg}" ]; then
    err "Day value must also be supplied if year was given."
  fi

  if [ -n "${year_arg}" ]; then
    year="${year_arg}"
    day="${day_arg}"
  fi

  [ "${year}" -lt "${MIN_YEAR}" ] && err "Invalid year, got ${year}, expected minimum year ${MIN_YEAR}"
  [ "${day}" -gt "${MAX_DAY}" ] && err "Invalid day, got ${day}, expected maximum day ${MAX_DAY}"

  if [ "${year}" = "${current_year}" ] && [ "${current_month}" != "${DECEMBER}" ]; then
    err "This years Advent of Code is not yet opened! Wait till December!"
  fi

  if [ "${current_day}" = "${day}" ] && [ "${current_utc_hour}" -lt "${TIMEZONE_DIFFERENCE}" ]; then
    err "Todays (${day}) puzzle is not yet opened. The puzzle opens at UTC 05:00."
  fi

  printf "%s;" "${year}" "${day}"
}

answer() {
  part=1
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --help | -h)
        help_answer
        ;;
      --part | -p)
        [ -z "$2" ] && err "No value provided for $1, expected $1 <value>, got $1"
        part="$2"
        shift
        ;;
      --answer | -a)
        [ -z "$2" ] && err "No value provided for $1, expected $1 <value>, got $1"
        part="$2"
        shift
        ;;
      --day | -d)
        [ -z "$2" ] && err "No value provided for flag, expected $1 <value>, got $1"
        day_arg="$2"
        shift
        ;;
      --year | -y)
        [ -z "$2" ] && err "No value provided for flag, expected $1 <value>, got $1"
        year_arg="$2"
        shift
        ;;
      *)
        [ -n "${answer}" ] && err "Got multiple answers, expected 1, got ${answer} and $1"
        answer="$1"
        ;;
    esac
    shift
  done

  dates="$(parse_dates "${year_arg}" "${day_arg}")"

  year="$(printf "%s" "${dates}" | cut -d ';' -f 1)"
  day="$(printf "%s" "${dates}" | cut -d ';' -f 2)"

  aoc submit "${part}" "${answer}" --year "${year}" --day "${day}"
}

hop() {
  [ "$#" -eq 0 ] && help

  commands="$(enum puzzle answer)"

  if [ -z "$(cat "${HOME}/.adventofcode.session")" ]; then
    set_session_cookie
  fi

  for arg; do
    if [ -z "${CMD}" ]; then
      parse_command "${arg}" "${commands}"
      if [ -n "${CMD}" ]; then
        shift
      fi
    fi
  done

  case "${CMD}" in
    puzzle) puzzle "$@" ;;
    answer) answer "$@" ;;
    *)
      aoc "$@"
      ;;
  esac
}

hop "$@"
