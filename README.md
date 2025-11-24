# ⏰ Minimal Timer

A minimalist command-line timer with smart time parsing and system integration.

[![Homebrew](https://img.shields.io/badge/homebrew-dandaniel5%2Ftimer-orange)](https://github.com/dandaniel5/homebrew-timer)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## ✨ Features

- 🕐 **Smart time parsing** - Natural language input: `10m`, `1h 30s`, `2d 5h`
- 📝 **Optional labels** - Name your timers with `-n` flag
- 💤 **Sleep integration** - Auto-sleep system (`-s`) or display (`-sd`) when done
- 📋 **Multiple timers** - Run multiple timers and list them with `-ls`
- ⚡ **Minimal output** - Clean, distraction-free countdown
- 🔔 **Audio notification** - Bell sound on completion
- 🌍 **Universal** - Works in bash, zsh, fish, and other shells
- 🔍 **Spotlight support** - Launch from macOS Spotlight

## 📦 Installation

### Homebrew (Recommended)

```bash
brew tap dandaniel5/timer
brew install timer
```

### Manual Installation

```bash
git clone https://github.com/dandaniel5/minimal-timer.git
cd minimal-timer
chmod +x timer
cp timer /usr/local/bin/
```

### macOS Spotlight Integration

After installation, you can also launch Timer from Spotlight:
1. Press `Cmd + Space`
2. Type "Timer"
3. Press Enter

## 🚀 Usage

### Basic Examples

```bash
# Simple timer (defaults to minutes)
timer 5
# Output: 4m 59s

# With time units
timer 10m
timer 1h 30m
timer 2d 5h 30m

# With a label
timer 25m -n "Pomodoro"
# Output: Pomodoro  24m 59s

# Sleep system after timer
timer 1h -s

# Sleep display only after timer
timer 30m -sd

# List all running timers
timer -ls
```

### Advanced Usage

```bash
# Run multiple timers in background
timer 1h -n "Meeting" &
timer 25m -n "Pomodoro" &
timer 10m -n "Break" &

# Check running timers
timer -ls
# Output:
# Running timers:
#   Meeting  59m 30s
#   Pomodoro  24m 15s
#   Break  9m 45s

# Complex duration with sleep
timer 1w 2d 3h -n "Vacation countdown" -sd
```

### Supported Time Units

| Unit | Aliases | Example |
|------|---------|---------|
| Seconds | `s`, `sec`, `second`, `seconds` | `30s` |
| Minutes | `m`, `min`, `minute`, `minutes` | `10m` (default) |
| Hours | `h`, `hour`, `hours` | `2h` |
| Days | `d`, `day`, `days` | `3d` |
| Weeks | `w`, `week`, `weeks` | `1w` |
| Years | `y`, `year`, `years` | `1y` |

### Command-Line Options

```
usage: timer [-h] [-n NAME] [-s] [-sd] [-ls] [time_input ...]

positional arguments:
  time_input            Time to count down (e.g. '10m', '1h 30s', '5')

optional arguments:
  -h, --help            Show help message
  -n NAME, --name NAME  Timer name/label
  -s, --sleep           Sleep system after timer completes
  -sd, --sleep-display  Sleep display only after timer completes
  -ls, --list           List all running timers
```

## 🎯 Use Cases

### Pomodoro Technique
```bash
timer 25m -n "Work" && timer 5m -n "Break"
```

### Meeting Reminder
```bash
timer 1h -n "Team Meeting" -s
```

### Screen Break
```bash
timer 20m -n "Eye Rest" -sd
```

### Cooking
```bash
timer 12m -n "Pasta" &
timer 15m -n "Sauce" &
timer -ls
```

## 🛠️ Requirements

- Python 3.6+
- macOS (for sleep functionality)

## 📝 How It Works

1. **Parsing**: The timer uses regex to parse natural language time input, supporting multiple units in a single command
2. **Countdown**: Updates every 100ms for smooth display, showing only non-zero time units
3. **Tracking**: Saves timer info to temp directory (`/tmp/smart_timers/`) for multi-timer support
4. **Sleep Integration**: Uses macOS `pmset` commands to trigger system or display sleep
5. **Cleanup**: Automatically removes timer info on completion or cancellation

## 🤝 Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest new features
- Submit pull requests

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 👤 Author

Created by [Danil Kodolov](https://github.com/dandaniel5)

---

**Tip**: Add `alias t='timer'` to your shell config for even faster access! 🚀
