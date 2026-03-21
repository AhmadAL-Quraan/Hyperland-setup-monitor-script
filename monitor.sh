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
#   1) Ask the user to make the Sort based on HZ or width or height
#   2) Execute based on specific number of the options instead of writing them manually

value=0 #postion value (right, left, up, down)
Hirtz=0
Dimensions=0

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
    *)
      echo "Enter valid input right/left/up/down"
      ;;
    esac
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

  dimensions=$(echo "$best" | cut -d'@' -f1)
  hirtz=$(echo "$best" | cut -d'@' -f2 | sed 's/Hz//')

  choose_position

  hyprctl keyword monitor HDMI-A-3,"$dimensions"@"$hirtz","$value",1
  exit
}

all_options() {
  hyprctl monitors -j | jq '.[] | select(.name=="HDMI-A-3") | .availableModes[] ' | sed 's/"//g' | sort -t'x' -k1,1 -n | nl -w1 -s ') '
}

specific_option() {
  while true; do
    # 🔹 Validate input
    while true; do
      read -p "Enter specific hz: " HZ
      if [[ ! "$HZ" =~ ^[0-9]+$ || "$HZ" -lt 20 || "$HZ" -gt 540 ]]; then
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
}

available_modes() {
  while true; do
    read -p "Show available modes? (y/n): " option
    option=$(echo "$option" | tr '[:upper:]' '[:lower:]')

    case "$option" in
    y | yes)
      while true; do
        read -p "All options (y) or specific (n) or best (b) -> based on highest HZ? " option2
        option2=$(echo "$option2" | tr '[:upper:]' '[:lower:]')

        case "$option2" in
        y | yes)
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
  while true; do
    read -p "Enter the hz for the screen, Ex. 60 for 60hz: " hirtz
    if [[ -n "$hirtz" ]]; then
      Hirtz="$hirtz"
      break
    fi
    echo "Hirtz can't be empty!!"
  done

  echo "You can treat all the hz appeared as a one value (the value you choosen) and you don't need to specify."
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

  hyprctl keyword monitor HDMI-A-3,"$Dimensions"@"$Hirtz","$value",1
}

available_modes
choose_settings
