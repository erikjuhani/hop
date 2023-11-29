# hop

`hop` is a shell-script utility designed for downloading Advent of Code puzzles
and inputs, as well as submitting answers for the puzzles directly from the
command line.

The name abbreviation is from words *h*oliday *o*f *p*uzzles!

⚠️ `hop` is only tested on MacOS and thus is only expected to work on MacOS.

## Prerequisites

Both [aoc-cli](https://github.com/scarvalhojr/aoc-cli/blob/main/aoc-client) and [sqlite3](https://formulae.brew.sh/formula/sqlite) must be installed to use this script!

## Installation

Easiest way to install `hop` is with [shm](https://github.com/erikjuhani/shm).

To install `shm` run either one of these oneliners:

curl:

```sh
curl -sSL https://raw.githubusercontent.com/erikjuhani/shm/main/shm.sh | sh
```

wget:

```sh
wget -qO- https://raw.githubusercontent.com/erikjuhani/shm/main/shm.sh | sh
```

then run:

```sh
shm get erikjuhani/hop
```

to get the latest version of `hop`.


## Usage

### Session token

If running the script on MacOS and you have Firefox as the default browser,
`hop` is able to fetch the session token automatically from the cookies sqlite
database, if the cookie is not found `hop` opens the default browser for user
to login.

Otherwise the session token should be provided in the `~/.adventofcode.session`
file.

### Puzzles and Inputs

`hop` installs the puzzles and inputs in a specific format. The structure is as follows:

```
2015
 ├── inputs
 │    └── day1
 └── puzzles
      └── day1.md
```

This structure allows for less duplication, but still having the files locally.
For example multiple programming languages can be put under the YEAR folder,
but still take advantage of the previously downloaded puzzle inputs:

```
2015
 ├── inputs
 │    └── day1
 ├── puzzles
 │    └── day1.md
 ├── rust
 │    ├── day1
 │    └── day2
 ├── go
 │    └── day1
 └── haskell
      └── day1
```

The current puzzle and input can be download with the following command (The current month must be December):

```sh
hop puzzle
```

To get a specific puzzle and input:

```sh
hop puzzle --year 2022 --day 1
```

### Submitting Answer

Submitting answer for the current puzzle:

```sh
hop answer 31122023
```

Submitting answer for the part 2 of the puzzle:

```sh
hop answer --part 2 31122023
```

Submitting answer for a specific puzzle:

```sh
hop answer --year 2022 --day 14 31122023
```
