# [Minimal Timer](https://codelove.space/minimal-timer.html)

A minimalist zeroconfig command-line timer with smart time parsing and system integration.



[![PyPI](https://img.shields.io/pypi/v/minimal-timer?color=blue&label=pypi%20package)](https://pypi.org/project/minimal-timer/)
[![Homebrew](https://img.shields.io/badge/homebrew-dandaniel5%2Ftimer-orange)](https://github.com/dandaniel5/homebrew-timer)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

## ✨ Features

- 🕐 **Smart time parsing** - Natural language input: `10m`, `1h 30s`, `2d 5h`
- 📝 **Optional labels** - Name your timers with `-n` flag
- 🔄 **Sync mode** - Loop timer with beep using `-sync` flag
- 💤 **Sleep integration** - Auto-sleep system (`-s`) or display (`-sd`) when done
- 🚀 **Execute command** - Run any command when timer finishes (`-e "say done"`)
- 📋 **Multiple timers** - Run multiple timers and list them with `-ls`
- 🗂️ **Groups** - `-g` / `--group` (default group name: `default`, like a primary group)
- 🎛️ **Batch control** - stop/pause/resume/reset all or per group; `--adjust` to add/subtract remaining time
- ⚡ **Minimal output** - Clean, distraction-free countdown
- 🔔 **Audio notification** - Bell sound on completion
- 🌍 **Universal** - Works in bash, zsh, fish, and other shells
- 🔍 **Spotlight support** - Launch from macOS Spotlight

## 📦 Installation

### 🐍 PyPI (Universal)
```bash
pip install minimal-timer
```

### 🍺 Homebrew (macOS)
```bash
brew install dandaniel5/timer/timer
```

### 📸 Snap Store (Linux)
```bash
snap install minimal-timer
```

### 🪟 Winget (Windows)
```bash
winget install DanilKodolov.MinimalTimer
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

# Execute command after timer
timer 5m -e "say 'Timer finished'"
timer 10m -e "open https://google.com"

# Sync mode (beep every 3 minutes)
timer 3m -sync

# List all running timers
timer -ls

# List only timers in a group
timer -ls -g work

# Start in a group (default group is "default" if -g omitted)
timer 45m -n "Standup" -g work
```

### Groups and managing running timers

```bash
# Stop every running timer (kills process, removes state)
timer --stop-all

# Stop all timers in one group
timer --stop-group work

# Stop one named timer (optional -g to disambiguate)
timer --stop -n "Pomodoro" -g work

# Pause / resume (works while timer runs in another terminal)
timer --pause-all
timer --pause-group work
timer --pause -n "Pomodoro"
timer --resume-all
timer --resume-group work
timer --resume -n "Pomodoro"

# Reset to the original duration (needs internal duration_seconds; new timers have it)
timer --reset-all
timer --reset-group work
timer --reset -n "Pomodoro"

# Add or subtract from remaining time (+/- uses the same time parser as starting a timer)
timer --adjust +10d -n "Vacation"
timer --adjust -5m -n "Pomodoro" -g work

# Aliases: same as --stop-all / --stop-group
timer --clear-all
timer --clear-group work
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
#   [default]  Meeting  59m 30s  (running)  pid=...
#   [default]  Pomodoro  24m 15s  (running)  pid=...
#   [default]  Break  9m 45s  (running)  pid=...

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

Run `timer --help` for the full list (groups, `--stop-all`, `--pause-group`, `--adjust`, etc.).

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
2. **Countdown**: Updates about every 120ms; the process re-reads its JSON state so pause/resume/adjust from another shell apply without signals
3. **Tracking**: Saves timer info to temp directory (`/tmp/smart_timers/`) for multi-timer support
4. **Sleep Integration**: Uses macOS `pmset` commands to trigger system or display sleep
5. **Cleanup**: Automatically removes timer info on completion or cancellation

## 🤝 Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest new features
- Submit pull requests

## 📄 License

GPL v3 License - see [LICENSE](LICENSE) file for details.

## 👤 Author

Created by [Danil Kodolov](https://github.com/dandaniel5)

---

**Tip**: Add `alias t='timer'` to your shell config for even faster access! 🚀
