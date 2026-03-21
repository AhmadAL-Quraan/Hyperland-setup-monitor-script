# Hyprland Monitor Helper Script


A small Bash script to adjust external monitors in **Hyprland** to make it less annoying.

## Why I made this

Typing full `hyprctl keyword monitor ...` commands every time is annoying.
This script makes it faster, safer, and a bit more user-friendly.
Instead of manually typing `hyprctl` commands and guessing resolutions / refresh rates, this script gives you an interactive way to:

* browse available modes
* filter them by refresh rate
* or just pick the best one automatically based on HZ (An improvement of choosing best option based on best resolution will be made later).

---

## What it does

When you run the script, it:

1. Asks if you want to see available monitor modes
2. Lets you choose:

   * all modes
   * modes near a specific Hz
   * or automatically pick the best mode (highest refresh rate)
3. Lets you set:

   * refresh rate
   * resolution
   * monitor position (right / left / up / down)
4. Applies everything using `hyprctl`

---

## Features

### 1)  Mode exploration

* List all available modes for your monitor
* Filter modes within a small Hz range (±2 Hz)
* Automatically pick the **highest refresh rate**

### 2) Input validation

* Prevents invalid Hz values
* Ensures required inputs are not empty
* Re-prompts on errors instead of failing

### 3) Clean output

* Sorted resolutions
* Numbered list for readability

### 4) Position handling

Quickly position your external monitor relative to your laptop screen:

* `right`
* `left`
* `up`
* `down`

### 5) Caching previous answers 
* So you don't have to type dimensions and hirtz again and again or if you mirror your laptop with the monitor, the available modes don't disappear.
---

##  Example usage

```bash
$ ./monitor.sh
Show available modes? (y/n): y
All options (y) or specific (n) or best (b): b

✅ Best mode selected: 1920x1080@144.00Hz

Postion of laptop screen, right/left/up/down: right
```

---

##  How "best mode" works

The script:

* reads all available modes
* extracts refresh rates using `jq`
* picks the mode with the **highest Hz**

Simple and effective.

---

## Functions made:  

* `available_modes` 
  -> Let you choose whether to see the available options for your monitor or not

* `all_options()`
  → shows all modes

* `specific_option()`
  → filters modes near a chosen Hz

* `best_mode()`
  → auto-selects highest refresh rate

* `choose_position()`
  → sets monitor placement

* `choose_hirtz_and_dimenstions()`
  -> To choose the hirtz and position (up, down, left, right)

* `choose_settings()`
  → final input + apply settings

---

## Notes!!

* Monitor name is currently hardcoded as:

  ```
  HDMI-A-3
  ```
* Position offsets assume your laptop display is **1920x1080**
* Scale is fixed at `1` (100%)

---

## 💡 Ideas for future improvements

* Choose monitor dynamically (not hardcoded).
* Select option directly by number instead of typing values.
* Allow user to choose whether to sort by:

  * Hz
  * width
  * height

* Smarter "best mode" (balance resolution + refresh rate).
* After select option based on number, the script should ask you if you are satisfied with the current settings.

---

## Requirements

* `hyprctl` (I mean it's for Hyprland )
* `jq` (json processor and formatter tool)
* standard Unix tools (`sort`, `nl`, `tr`)



