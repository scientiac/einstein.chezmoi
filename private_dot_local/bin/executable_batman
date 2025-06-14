#!/usr/bin/env bash

BATTERY_PATH="/sys/class/power_supply/BAT0"
THRESHOLD=$(cat "$BATTERY_PATH/charge_control_end_threshold")
CAPACITY=$(cat "$BATTERY_PATH/capacity")
STATUS=$(cat "$BATTERY_PATH/status")
MAX=100
DEFAULT=80

function set_custom() {
  # Prompt the user for a value using gum input
  threshold=$(gum input --placeholder "Enter value (60-100)")

  # Check if the input is a valid number between 60 and 100
  if [[ "$threshold" =~ ^[0-9]+$ ]] && [ "$threshold" -ge 60 ] && [ "$threshold" -le 100 ]; then

    gum confirm && gum spin --spinner dot --title "Okay..." -- sleep 1 || exit

    # Use pkexec to invoke root privileges to write to the file
    pkexec threshold "$threshold"

    if [ $? -eq 0 ]; then
      echo "Charge threshold set to $threshold successfully."
    else
      echo "Failed to set charge threshold."
    fi
  else
    echo "Invalid input. Please enter a number between 60 and 100."
  fi
}

function set_max() {
    pkexec threshold "$MAX"

    if [ $? -eq 0 ]; then
      echo "Charge control end threshold set to $MAX successfully."
    else
      echo "Failed to set charge control end threshold."
    fi
}

function set_default() {
    pkexec threshold "$DEFAULT"

    if [ $? -eq 0 ]; then
      echo "Charge control end threshold set to $DEFAULT successfully."
    else
      echo "Failed to set charge control end threshold."
    fi
}

# Function definitions
function show_status() {
  gum style \
    --border normal \
    --align center --width 40 --margin "1 2" --padding "1 2" \
    "Battery Status: $STATUS" "Capacity: $CAPACITY%" "Charging Threshold: $THRESHOLD%" 
}

# Present a list of tasks to the user using gum
CHOICE=$(gum choose "Show Status" "Full Charge" "Health Mode" "Set Threshold")

# Handle the selected choice
case "$CHOICE" in
  "Show Status")
    show_status
    ;;
  "Set Threshold")
    set_custom
    ;;
  "Full Charge")
    set_max
    ;;
  "Health Mode")
    set_default
    ;;
  *)
    echo "Invalid choice!"
    ;;
esac

