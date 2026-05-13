#!/usr/bin/env python3
import sys
import time
import re
import argparse
import os
import subprocess
import tempfile
import json
import signal
from pathlib import Path

__version__ = "1.0.7"

DEFAULT_GROUP = "default"

def parse_time(time_str):
    """
    Parses a natural language time string into total seconds.
    Supports years, days, hours, minutes, seconds.
    Default unit is minutes if no unit is specified for a number.
    Raises ValueError if unrecognized content is found.
    """
    time_str = time_str.lower()

    pattern = r'(\d+(?:\.\d+)?)\s*([a-z]*)'

    matches = list(re.finditer(pattern, time_str))

    total_seconds = 0
    last_pos = 0

    units = {
        'y': 31536000, 'year': 31536000, 'years': 31536000,
        'w': 604800, 'week': 604800, 'weeks': 604800,
        'd': 86400, 'day': 86400, 'days': 86400,
        'h': 3600, 'hour': 3600, 'hours': 3600,
        'm': 60, 'min': 60, 'minute': 60, 'minutes': 60,
        's': 1, 'sec': 1, 'second': 1, 'seconds': 1
    }

    for match in matches:
        unrecognized = time_str[last_pos:match.start()].strip()
        if unrecognized:
            raise ValueError(f"Unrecognized input: '{unrecognized}'")

        amount_str = match.group(1)
        unit_str = match.group(2)

        amount = float(amount_str)
        unit = unit_str.strip()

        if not unit:
            multiplier = 60
        elif unit in units:
            multiplier = units[unit]
        else:
            raise ValueError(f"Unrecognized unit: '{unit}'")

        total_seconds += amount * multiplier
        last_pos = match.end()

    unrecognized = time_str[last_pos:].strip()
    if unrecognized:
        raise ValueError(f"Unrecognized input: '{unrecognized}'")

    return total_seconds

def format_duration_short(seconds):
    if seconds <= 0:
        return "0s"

    YEAR = 31536000
    WEEK = 604800
    DAY = 86400
    HOUR = 3600
    MINUTE = 60

    parts = []

    years = int(seconds // YEAR)
    seconds %= YEAR

    weeks = int(seconds // WEEK)
    seconds %= WEEK

    days = int(seconds // DAY)
    seconds %= DAY

    hours = int(seconds // HOUR)
    seconds %= HOUR

    minutes = int(seconds // MINUTE)
    seconds %= MINUTE

    secs = int(seconds)

    if years > 0:
        parts.append(f"{years}y")
    if weeks > 0:
        parts.append(f"{weeks}w")
    if days > 0:
        parts.append(f"{days}d")
    if hours > 0:
        parts.append(f"{hours}h")
    if minutes > 0:
        parts.append(f"{minutes}m")
    if secs > 0 or not parts:
        parts.append(f"{secs}s")

    return " ".join(parts)

TIMERS_DIR = Path(tempfile.gettempdir()) / "smart_timers"

def atomic_write_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
    tmp.replace(path)

def save_timer_info(name, pid, end_time, group=None, duration_seconds=None, paused=False, paused_remaining=None):
    TIMERS_DIR.mkdir(exist_ok=True)
    timer_file = TIMERS_DIR / f"timer_{pid}.json"
    if group is None:
        group = DEFAULT_GROUP

    old = {}
    if timer_file.exists():
        try:
            with open(timer_file, "r", encoding="utf-8") as f:
                old = json.load(f)
        except Exception:
            old = {}

    data = {
        "name": name,
        "pid": pid,
        "end_time": end_time,
        "group": group,
        "paused": bool(paused),
    }
    if paused:
        data["paused_remaining"] = float(paused_remaining if paused_remaining is not None else 0)

    if duration_seconds is not None:
        data["duration_seconds"] = duration_seconds
    elif "duration_seconds" in old:
        data["duration_seconds"] = old["duration_seconds"]

    atomic_write_json(timer_file, data)

def write_timer_state(data):
    """Write full timer record (used by management commands)."""
    pid = int(data["pid"])
    timer_file = TIMERS_DIR / f"timer_{pid}.json"
    atomic_write_json(timer_file, data)

def remove_timer_info(pid):
    timer_file = TIMERS_DIR / f"timer_{pid}.json"
    if timer_file.exists():
        timer_file.unlink()

def read_timer_json(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

def iter_timer_paths():
    if not TIMERS_DIR.exists():
        return
    for p in sorted(TIMERS_DIR.glob("timer_*.json")):
        yield p

def normalize_timer_record(data):
    data = dict(data)
    data.setdefault("group", DEFAULT_GROUP)
    data.setdefault("name", "")
    data.setdefault("paused", False)
    try:
        data["pid"] = int(data["pid"])
        data["end_time"] = float(data["end_time"])
    except (KeyError, TypeError, ValueError):
        return None
    if data.get("paused"):
        try:
            data["paused_remaining"] = float(data["paused_remaining"])
        except (KeyError, TypeError, ValueError):
            data["paused_remaining"] = 0.0
    if "duration_seconds" in data:
        try:
            data["duration_seconds"] = float(data["duration_seconds"])
        except (TypeError, ValueError):
            data.pop("duration_seconds", None)
    return data

def effective_remaining(data, now=None):
    if now is None:
        now = time.time()
    if data.get("paused"):
        return max(0.0, float(data.get("paused_remaining", 0)))
    return max(0.0, float(data["end_time"]) - now)

def list_timers(group_filter=None):
    if not TIMERS_DIR.exists():
        print("No running timers")
        return

    timer_files = list(TIMERS_DIR.glob("timer_*.json"))
    if not timer_files:
        print("No running timers")
        return

    rows = []
    for timer_file in sorted(timer_files):
        try:
            data = normalize_timer_record(read_timer_json(timer_file))
            if data is None:
                continue
            if group_filter is not None and data["group"] != group_filter:
                continue
            remaining = effective_remaining(data)
            if not data.get("paused") and remaining <= 0:
                timer_file.unlink()
                continue
            rows.append((data, remaining, timer_file))
        except Exception:
            continue

    if not rows:
        print("No running timers" + (f" in group '{group_filter}'" if group_filter else ""))
        return

    print("Running timers:" + (f" (group: {group_filter})" if group_filter else ""))
    for data, remaining, _ in rows:
        time_str = format_duration_short(remaining)
        name = data.get("name") or "Timer"
        grp = data.get("group", DEFAULT_GROUP)
        state = "paused" if data.get("paused") else "running"
        print(f"  [{grp}]  {name}  {time_str}  ({state})  pid={data['pid']}")

def sleep_system():
    try:
        subprocess.run(['pmset', 'sleepnow'], check=True)
    except Exception as e:
        print(f"Failed to sleep system: {e}")

def sleep_display():
    try:
        subprocess.run(['pmset', 'displaysleepnow'], check=True)
    except Exception as e:
        print(f"Failed to sleep display: {e}")

def _kill_pid(pid, grace=0.3):
    if pid == os.getpid():
        return
    try:
        if hasattr(signal, "SIGTERM"):
            os.kill(pid, signal.SIGTERM)
        else:
            os.kill(pid, signal.SIGKILL)
    except ProcessLookupError:
        return
    except PermissionError:
        pass
    except OSError:
        pass
    t0 = time.time()
    while time.time() - t0 < grace:
        try:
            os.kill(pid, 0)
        except ProcessLookupError:
            return
        except OSError:
            return
        time.sleep(0.05)
    try:
        if hasattr(signal, "SIGKILL"):
            os.kill(pid, signal.SIGKILL)
    except (ProcessLookupError, PermissionError, OSError):
        pass

def stop_timers(predicate):
    stopped = 0
    for path in list(iter_timer_paths()):
        try:
            data = normalize_timer_record(read_timer_json(path))
            if data is None or not predicate(data):
                continue
            _kill_pid(data["pid"])
            path.unlink(missing_ok=True)
            stopped += 1
        except Exception:
            continue
    return stopped

def set_pause_state(predicate, pause):
    changed = 0
    now = time.time()
    for path in list(iter_timer_paths()):
        try:
            data = normalize_timer_record(read_timer_json(path))
            if data is None or not predicate(data):
                continue
            if pause:
                if data.get("paused"):
                    continue
                rem = max(0.0, float(data["end_time"]) - now)
                data["paused"] = True
                data["paused_remaining"] = rem
                write_timer_state(data)
                changed += 1
            else:
                if not data.get("paused"):
                    continue
                rem = max(0.0, float(data.get("paused_remaining", 0)))
                data["paused"] = False
                data["end_time"] = now + rem
                if "paused_remaining" in data:
                    del data["paused_remaining"]
                write_timer_state(data)
                changed += 1
        except Exception:
            continue
    return changed

def reset_timers(predicate):
    changed = 0
    now = time.time()
    for path in list(iter_timer_paths()):
        try:
            data = normalize_timer_record(read_timer_json(path))
            if data is None or not predicate(data):
                continue
            dur = data.get("duration_seconds")
            if dur is None or dur <= 0:
                continue
            data["paused"] = False
            data.pop("paused_remaining", None)
            data["end_time"] = now + float(dur)
            write_timer_state(data)
            changed += 1
        except Exception:
            continue
    return changed

def parse_adjust_delta(s):
    s = s.strip()
    if not s:
        raise ValueError("empty adjust string")
    sign = 1.0
    if s[0] in "+-":
        if s[0] == "-":
            sign = -1.0
        s = s[1:].strip()
    sec = parse_time(s)
    return sign * sec

def adjust_timers_by_name(name, delta_seconds, group_filter=None):
    if not name:
        return 0
    now = time.time()
    changed = 0
    for path in list(iter_timer_paths()):
        try:
            data = normalize_timer_record(read_timer_json(path))
            if data is None:
                continue
            if group_filter is not None and data.get("group") != group_filter:
                continue
            if (data.get("name") or "") != name:
                continue
            if data.get("paused"):
                base = float(data.get("paused_remaining", 0))
            else:
                base = max(0.0, float(data["end_time"]) - now)
            new_rem = max(0.0, base + delta_seconds)
            if new_rem <= 0:
                new_rem = 0.0
            if data.get("paused"):
                data["paused_remaining"] = new_rem
            else:
                data["end_time"] = now + new_rem
            write_timer_state(data)
            changed += 1
        except Exception:
            continue
    return changed

class CustomArgumentParser(argparse.ArgumentParser):
    def error(self, message):
        sys.stderr.write(f"Error: {message}\n")
        sys.stderr.write("Try 'timer --help' for more information.\n")
        sys.exit(2)

def poll_timer_state(pid):
    path = TIMERS_DIR / f"timer_{pid}.json"
    if not path.exists():
        return None
    try:
        return normalize_timer_record(read_timer_json(path))
    except Exception:
        return None

def run_countdown_loop(args, pid, duration_seconds, initial_end_time):
    end_time = initial_end_time
    group = args.group or DEFAULT_GROUP

    def persist(end_t, dur=None, paused=False, paused_rem=None):
        save_timer_info(
            args.name,
            pid,
            end_t,
            group=group,
            duration_seconds=dur if dur is not None else duration_seconds,
            paused=paused,
            paused_remaining=paused_rem,
        )

    persist(end_time, duration_seconds, paused=False)

    try:
        while True:
            start_time = time.time()
            end_time = start_time + duration_seconds
            persist(end_time, duration_seconds, paused=False)

            while True:
                state = poll_timer_state(pid)
                if state is None:
                    remove_timer_info(pid)
                    return

                if state.get("paused"):
                    rem = float(state.get("paused_remaining", 0))
                    time_str = format_duration_short(rem)
                else:
                    end_time = float(state["end_time"])
                    now = time.time()
                    remaining = end_time - now
                    if remaining <= 0:
                        break
                    time_str = format_duration_short(remaining)

                if args.name:
                    output = f"\r\033[K{args.name}  {time_str}"
                else:
                    output = f"\r\033[K{time_str}"

                sys.stdout.write(output)
                sys.stdout.flush()
                time.sleep(0.12)

            if args.name:
                print(f"\r\033[K{args.name}  Done!")
            else:
                print(f"\r\033[KDone!")

            sys.stdout.write('\a')
            sys.stdout.flush()

            if args.synchronize:
                continue

            remove_timer_info(pid)

            if args.sleep:
                sleep_system()
            elif args.sleep_display:
                sleep_display()

            if args.execute:
                try:
                    subprocess.run(args.execute, shell=True)
                except Exception as e:
                    print(f"\nError executing command: {e}")

            break

    except KeyboardInterrupt:
        remove_timer_info(pid)
        if args.name:
            print(f"\n\033[K{args.name}  Cancelled")
        else:
            print(f"\n\033[KCancelled")
        sys.exit(0)

def main():
    parser = CustomArgumentParser(description="Smart Terminal Timer")
    parser.add_argument('time_input', nargs='*', help="Time to count down (e.g. '10m', '1h 30s', '5'). Default unit is minutes.")
    parser.add_argument('-n', '--name', type=str, default="", help="Timer name/label")
    parser.add_argument('-g', '--group', type=str, default=None, help=f"Timer group (default: '{DEFAULT_GROUP}')")
    parser.add_argument('-s', '--sleep', action='store_true', help="Sleep system after timer")
    parser.add_argument('-sd', '--sleep-display', action='store_true', help="Sleep display after timer")
    parser.add_argument('-e', '--execute', type=str, help="Command to execute after timer")
    parser.add_argument('-sync', '--synchronize', action='store_true', help="Run timer in a loop (beep and restart)")
    parser.add_argument('-ls', '--list', action='store_true', help="List running timers (optional: -g to filter)")
    parser.add_argument('-v', '--version', action='store_true', help="Show version info")

    parser.add_argument('--stop-all', action='store_true', help="Stop (kill) all timers and remove state")
    parser.add_argument('--stop-group', metavar='GROUP', help="Stop all timers in GROUP")
    parser.add_argument('--stop', action='store_true', help="Stop timer(s) with matching -n (and optional -g)")

    parser.add_argument('--pause-all', action='store_true', help="Pause all timers")
    parser.add_argument('--pause-group', metavar='GROUP', help="Pause all timers in GROUP")
    parser.add_argument('--pause', action='store_true', help="Pause timer(s) matching -n (optional -g)")

    parser.add_argument('--resume-all', action='store_true', help="Resume all paused timers")
    parser.add_argument('--resume-group', metavar='GROUP', help="Resume paused timers in GROUP")
    parser.add_argument('--resume', action='store_true', help="Resume timer(s) matching -n (optional -g)")

    parser.add_argument('--reset-all', action='store_true', help="Reset all timers to original duration (needs duration_seconds in state)")
    parser.add_argument('--reset-group', metavar='GROUP', help="Reset all timers in GROUP to original duration")
    parser.add_argument('--reset', action='store_true', help="Reset timer(s) matching -n (optional -g)")

    parser.add_argument('--clear-all', action='store_true', help="Alias for --stop-all")
    parser.add_argument('--clear-group', metavar='GROUP', help="Stop all timers in GROUP (same as --stop-group)")

    parser.add_argument('--adjust', metavar='DELTA', type=str, help="Add/subtract time from remaining, e.g. +10d, -5m (use with -n, optional -g)")

    args = parser.parse_args()

    if args.version:
        print(f"Minimal Timer v{__version__}")
        return

    mgmt = any([
        args.list, args.stop_all, args.stop_group, args.stop,
        args.pause_all, args.pause_group, args.pause,
        args.resume_all, args.resume_group, args.resume,
        args.reset_all, args.reset_group, args.reset,
        args.clear_all, args.clear_group, args.adjust is not None,
    ])

    if args.clear_all:
        args.stop_all = True
    if args.clear_group:
        args.stop_group = args.clear_group

    if args.list:
        list_timers(group_filter=args.group)
        sys.exit(0)

    group_f = args.group

    def pred_all(_d):
        return True

    if args.stop_all:
        n = stop_timers(pred_all)
        print(f"Stopped {n} timer(s).")
        sys.exit(0)

    if args.stop_group:
        g = args.stop_group
        n = stop_timers(lambda d: d.get("group", DEFAULT_GROUP) == g)
        print(f"Stopped {n} timer(s) in group '{g}'.")
        sys.exit(0)

    if args.stop:
        name = args.name or ""
        if not name:
            print("Error: --stop requires -n/--name")
            sys.exit(2)
        n = stop_timers(
            lambda d: (d.get("name") or "") == name
            and (group_f is None or d.get("group", DEFAULT_GROUP) == group_f)
        )
        print(f"Stopped {n} timer(s) named '{name}'.")
        sys.exit(0)

    if args.pause_all:
        n = set_pause_state(pred_all, True)
        print(f"Paused {n} timer(s).")
        sys.exit(0)

    if args.pause_group:
        g = args.pause_group
        n = set_pause_state(lambda d: d.get("group", DEFAULT_GROUP) == g, True)
        print(f"Paused {n} timer(s) in group '{g}'.")
        sys.exit(0)

    if args.pause:
        name = args.name or ""
        if not name:
            print("Error: --pause requires -n/--name (or use --pause-all / --pause-group)")
            sys.exit(2)
        n = set_pause_state(
            lambda d: (d.get("name") or "") == name
            and (group_f is None or d.get("group", DEFAULT_GROUP) == group_f),
            True,
        )
        print(f"Paused {n} timer(s) named '{name}'.")
        sys.exit(0)

    if args.resume_all:
        n = set_pause_state(pred_all, False)
        print(f"Resumed {n} timer(s).")
        sys.exit(0)

    if args.resume_group:
        g = args.resume_group
        n = set_pause_state(lambda d: d.get("group", DEFAULT_GROUP) == g, False)
        print(f"Resumed {n} timer(s) in group '{g}'.")
        sys.exit(0)

    if args.resume:
        name = args.name or ""
        if not name:
            print("Error: --resume requires -n/--name (or use --resume-all / --resume-group)")
            sys.exit(2)
        n = set_pause_state(
            lambda d: (d.get("name") or "") == name
            and (group_f is None or d.get("group", DEFAULT_GROUP) == group_f),
            False,
        )
        print(f"Resumed {n} timer(s) named '{name}'.")
        sys.exit(0)

    if args.reset_all:
        n = reset_timers(pred_all)
        print(f"Reset {n} timer(s) (skipped entries without duration_seconds).")
        sys.exit(0)

    if args.reset_group:
        g = args.reset_group
        n = reset_timers(lambda d: d.get("group", DEFAULT_GROUP) == g)
        print(f"Reset {n} timer(s) in group '{g}'.")
        sys.exit(0)

    if args.reset:
        name = args.name or ""
        if not name:
            print("Error: --reset requires -n/--name (or use --reset-all / --reset-group)")
            sys.exit(2)
        n = reset_timers(
            lambda d: (d.get("name") or "") == name
            and (group_f is None or d.get("group", DEFAULT_GROUP) == group_f)
        )
        print(f"Reset {n} timer(s) named '{name}'.")
        sys.exit(0)

    if args.adjust is not None:
        if not (args.name or "").strip():
            print("Error: --adjust requires -n/--name (optional -g to narrow)")
            sys.exit(2)
        try:
            delta = parse_adjust_delta(args.adjust)
        except Exception as e:
            print(f"Error: {e}")
            sys.exit(1)
        n = adjust_timers_by_name(args.name.strip(), delta, group_filter=group_f)
        print(f"Adjusted {n} timer(s) by {args.adjust}.")
        sys.exit(0)

    if mgmt:
        parser.error("Unexpected state.")

    if not args.time_input:
        parser.error("Please provide a time duration.")

    full_time_str = " ".join(args.time_input)

    try:
        duration_seconds = parse_time(full_time_str)
    except Exception as e:
        print(f"Error: {e}")
        print("Try 'timer --help' for more information.")
        sys.exit(1)

    if duration_seconds <= 0:
        print("Error: Timer must be greater than 0.")
        print("Try 'timer --help' for more information.")
        sys.exit(1)

    pid = os.getpid()
    group = args.group if args.group is not None else DEFAULT_GROUP
    args.group = group

    start_time = time.time()
    initial_end = start_time + duration_seconds
    run_countdown_loop(args, pid, duration_seconds, initial_end)

if __name__ == "__main__":
    main()
