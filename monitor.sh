#!/bin/bash

#monitor=NAME,RESOLUTION@REFRESH,POSITION,SCALE

#POSITION means move the monitor to the right of the eDP-1 with same vertical, because eDP-1 is 1920
#+-------------------+-------------------+
#|    eDP-1          |   HDMI-A-3        |
#| 1920x1080         | 1920x1080         |
#+-------------------+-------------------+
#0x0              1920x0

# SCALE means 1 -> 100%(Normal), 1.25 -> 125% ,...
#
#
# More ideas to add :
#   * Choose monitor dynamically (not hardcoded).
#   * Select option directly by number instead of typing values.
#   * Allow user to choose whether to sort by:

#       * Hz
#       * width
#       * height

#   * Smarter "best mode" (balance resolution + refresh rate).

RED="\e[31m"
BLUE="\e[34m"
RESET="\e[0m"

# All availabe mode options for the monitor connected via HDMI
value=0 #postion value (right, left, up, down)
Hirtz=0
Dimensions=0 #width x height

# CHeck if there is previous answer for modes or settings applied

mirroring() {
  while true; do
    read -p "Mirror / seperate ? (m/s) " mirror
    case "$mirror" in
    m | mirror)
      hyprctl keyword monitor HDMI-A-3,"$Dimensions"@"$Hirtz","$value",1,mirror,eDP-1
      exit
      ;;
    s | seperate)
      break
      ;;
    *)
      echo "Enter valid answer (m/s) !!"
      ;;
    esac

  done

}

# Start of the script
previous_settings="/tmp/hdmi_script/previous_settings"
mode_file="/tmp/hdmi_script/HDMI_modes"

if [[ -f "$previous_settings" ]]; then
  echo -e "Do you want to apply the last settings ? \n"
  echo -e "$(cat $previous_settings)\n"

  while true; do

    read -p "(y/n): " apply
    case "$apply" in
    y | yes)
      Dimensions=$(cat /tmp/hdmi_script/previous_settings | awk '{print $2}')
      Hirtz=$(cat /tmp/hdmi_script/previous_settings | awk '{print $4}')
      value=$(cat /tmp/hdmi_script/previous_settings | awk '{print $6}')
      mirroring

      hyprctl keyword monitor HDMI-A-3,"$Dimensions"@"$Hirtz","$value",1
      exit
      ;;
    n | no)
      break
      ;;
    *)
      echo "Enter valid answer (y/n) !!"
      ;;

    esac
  done
fi

if [[ ! -f "$mode_file" ]]; then
  all_option=$(hyprctl monitors -j | jq '.[] | select(.name=="HDMI-A-3") | .availableModes[] ' | sed 's/"//g' | sort -t'x' -k1,1 -n | nl -w1 -s ') ')
  mkdir "/tmp/hdmi_script/" 2>/dev/null
  echo "$all_option" >"$mode_file"

fi

function choose_position() {
  #Loop to apply valid postion
  while true; do
    read -p "Postion of laptop screen, right/left/up/down: " postion
    case "$postion" in
    right)
      value=1920x0
      break
      ;;
    left)
      value=-1920x0
      break
      ;;
    up)
      value=0x-1080
      break
      ;;
    down)
      value=0x1080
      break
      ;;
    *) echo "Enter valid input right/left/up/down" ;; esac
  done
}

best_mode() {
  best=$(hyprctl monitors -j | jq -r '
    [
      .[] 
      | select(.name=="HDMI-A-3") 
      | .availableModes[]
      | { 
          mode: ., 
          hz: (capture("@(?<hz>[0-9.]+)Hz").hz | tonumber) 
        }
    ]
    | sort_by(.hz)
    | last
    | .mode
  ')

  if [[ -z "$best" ]]; then
    echo "❌ No modes found!"
    return 1
  fi

  echo "✅ Best mode selected: $best"

  Dimensions=$(echo "$best" | cut -d'@' -f1)
  hirtz=$(echo "$best" | cut -d'@' -f2 | sed 's/Hz//')

  choose_position

  hyprctl keyword monitor HDMI-A-3,"$Dimensions"@"$hirtz","$value",1
  exit
}

all_options() {
  cat "$mode_file"
}

specific_option() {
  while true; do
    # 🔹 Validate input
    while true; do
      read -p "Enter specific hz: " HZ
      if [[ ! "$HZ" =~ ^[0-9]+$ || "$HZ" -lt 30 || "$HZ" -gt 540 ]]; then
        echo "Enter valid number !!"
      else
        break
      fi
    done

    left=$((HZ - 2))
    right=$((HZ + 2))

    # 🔹 Capture result
    result=$(hyprctl monitors -j | jq -r --argjson left "$left" --argjson right "$right" '
      .[] 
      | select(.name=="HDMI-A-3") 
      | .availableModes[] 
      | (capture("@(?<hz>[0-9.]+)Hz").hz | tonumber) as $hz
      | select($hz >= $left and $hz <= $right)
    ')

    # 🔹 Check if empty
    if [[ -z "$result" ]]; then
      echo "❌ No modes found in range [$left - $right] Hz. Try again."
      continue
    fi

    # 🔹 Print nicely
    echo "$result" |
      sort -t'x' -k1,1n |
      nl -w1 -s ') '

    break
  done

  while true; do
    read -p "Continue configuration with the $HZ hirtz (you only need to choose dimension) ? (yes/no) " continue
    case "$continue" in
    y | yes)
      Hirtz="$HZ"
      break
      ;;
    n | no)
      break
      ;;
    *)
      echo "Enter valid answer (yes/no) !!"
      ;;
    esac

  done

}

available_modes() {
  while true; do
    read -p "Show available dimension @ hirtz ? (y/n): " option
    option=$(echo "$option" | tr '[:upper:]' '[:lower:]')

    case "$option" in
    y | yes)
      while true; do
        read -p "All modes (y) or specific hirtz option lookup (n) or best mode (based on hirtz) (b) ? " option2
        option2=$(echo "$option2" | tr '[:upper:]' '[:lower:]')

        case "$option2" in
        y | yes)
          echo -e "${BLUE}Note! : available modes sorted based on width from loweset to heighst (width x height @ hirtz)${RESET}"
          all_options
          break
          ;;
        n | no)
          specific_option
          break
          ;;
        b | best)
          best_mode
          break
          ;;
        *) echo "Invalid input" ;;
        esac
      done
      break
      ;;

    n | no)
      break
      ;;

    *)
      echo "Invalid input"
      ;;
    esac
  done
}

choose_hirtz_and_dimensions() {
  echo -e "\n"
  if [[ "$Hirtz" == 0 ]]; then

    while true; do
      read -p "Enter the hz for the screen, Ex. 60 for 60hz: " hirtz
      if [[ -n "$hirtz" ]]; then
        Hirtz="$hirtz"
        break
      fi
      echo "Hirtz can't be empty!!"
    done
  fi
  while true; do
    read -p "Enter the Dimensions for the screen, Ex. 1920x1080: " dimensions
    if [[ -n "$dimensions" ]]; then
      Dimensions="$dimensions"
      break
    fi
    echo "Dimensions can't be empty!!"

  done
}

choose_settings() {
  choose_hirtz_and_dimensions
  choose_position
  mirroring

  hyprctl keyword monitor HDMI-A-3,"$Dimensions"@"$Hirtz","$value",1
  echo "Dimension: $Dimensions       Hirtz: $Hirtz       Postion: $value" >"$previous_settings"
}

available_modes
choose_settings
