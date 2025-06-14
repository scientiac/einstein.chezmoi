#!/usr/bin/env bash

# Create temporary files
input_file=$(mktemp)
markdown_file=$(mktemp)
processed_file=$(mktemp)

# Download the markdown file and replace 'Empty' with '`Empty`'
curl -s https://raw.githubusercontent.com/the-nix-way/dev-templates/main/README.md | sed 's/Empty/`empty`/g' > "$input_file"

# Extract the section between '### ' and the next '## '
awk '/### /, /^## / {if (!/^## /) print}' "$input_file" > "$markdown_file"

# Add formatting around '### ' lines
sed -i '/^### /{s/^/~~~\n\n/;s/$/\n/}' "$markdown_file"

# Remove the first occurrence of '~~~'
sed -i '0,/~~~/{s/~~~//}' "$markdown_file"

# Add '~~~' at the end of the file
sed -i '$s/$/\n~~~/' "$markdown_file"

# Initialize an empty variable to hold the list of languages
languages=""

# Process the file to collect languages and format the output
formatted_output=$(awk '
/### \[/ {
    match($0, /\[`([^`]*)`\]/, arr)
    print arr[1]
    next
}
{ print }
' "$markdown_file")

# Extract languages from the formatted output and save to a variable
languages=$(echo "$formatted_output" | awk '/^[a-zA-Z0-9_-]+$/')

# Save the processed output to a temporary file
echo "$formatted_output" > "$processed_file"

# Use fzf to select a language with preview
SELECTED_LANG=$(echo "$languages" | fzf --preview "awk '/^{}$/,/^~~~$/ {if (NR>1 && !/^~~~$/) print}' \"$processed_file\"" --preview-window=right:50%:wrap --height=60% --layout=reverse --info=inline --border --margin=1 --padding=1)

# If a language is selected, initialize the nix flake
if [ -n "$SELECTED_LANG" ]; then
    echo "Selected language: $SELECTED_LANG"
    nix flake init --template "github:the-nix-way/dev-templates#$SELECTED_LANG"
else
    echo "No language selected."
fi

# Clean up temporary files
rm "$input_file" "$markdown_file" "$processed_file"

