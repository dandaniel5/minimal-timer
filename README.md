# Smart Timer

A minimalist command-line timer with smart time parsing.

## Features

- 🕐 **Smart time parsing**: `10m`, `1h 30s`, `2d 5h`, etc.
- 📝 **Optional labels**: Add names to your timers with `-n`
- ⚡ **Minimal output**: Clean, distraction-free display
- 🔔 **Audio notification**: Bell sound when timer completes
- 🌍 **Universal**: Works in bash, zsh, and other shells

## Installation

### Homebrew (macOS/Linux)

```bash
brew tap danilkodolov/timer
brew install timer
```

### Manual Installation

```bash
git clone https://github.com/danilkodolov/timer.git
cd timer
chmod +x timer
cp timer /usr/local/bin/
```

## Usage

```bash
# Simple timer (defaults to minutes)
timer 5

# With time units
timer 10m
timer 1h 30m
timer 2d 5h 30m

# With a label
timer 25m -n "Pomodoro"
timer 1h -n "Meeting"

# Mix and match
timer 1w 2d 3h -n "Vacation countdown"
```

### Supported Time Units

- `s` - seconds
- `m` - minutes (default)
- `h` - hours
- `d` - days
- `w` - weeks
- `y` - years

## Examples

```bash
# 5 minute timer
timer 5m
# Output: 4m 59s

# Named timer
timer 25m -n Work
# Output: Work  24m 59s

# Complex duration
timer 1h 30m 45s
# Output: 1h 29m 44s
```

## Requirements

- Python 3.6+

## License

MIT License - see LICENSE file for details.

## Author

Created by Danil Kodolov
