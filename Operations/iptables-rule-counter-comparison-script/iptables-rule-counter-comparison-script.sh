#!/bin/bash

# Check if both files are provided
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <file1> <file2>"
  exit 1
fi

file1="$1"
file2="$2"

# Temporary file to store the output
output_file="packet_rate_diff.txt"
> "$output_file"

declare -A file1_rules
declare -A file2_rules
declare -A unmatched_lines_file1
declare -A unmatched_lines_file2

# Function to calculate the difference
calculate_diff() {
    old_value=$1
    new_value=$2
    diff=$((new_value - old_value))
    echo "$diff"
}

# Function to parse the file into the associative array
parse_file() {
    local file="$1"
    local -n rules_array=$2
    local -n unmatched_lines=$3

    while IFS= read -r line; do
        # Remove any leading/trailing whitespace
        line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        if [[ "$line" =~ \[([0-9]+):([0-9]+)\] ]]; then
            # Extract the rule (line without counters)
            rule=$(echo "$line" | sed 's/\[[0-9]\+:[0-9]\+\]//')
            rule=$(echo "$rule" | sed 's/[[:space:]]\+/ /g')
            # Store the counters in the array with the rule as the key
            rules_array["$rule"]="${BASH_REMATCH[1]}:${BASH_REMATCH[2]}"
        else
            # Normalize the rule (remove extra spaces)
            rule=$(echo "$line" | sed 's/[[:space:]]\+/ /g')
            unmatched_lines["$rule"]=1
        fi
    done < "$file"
}

# Parse both files
parse_file "$file1" file1_rules unmatched_lines_file1
parse_file "$file2" file2_rules unmatched_lines_file2

# Compare the rules with counters
for rule in "${!file1_rules[@]}"; do
    if [[ -n "${file1_rules[$rule]}" ]]; then
        if [[ -n "${file2_rules[$rule]}" ]]; then
            # Extract counters
            IFS=: read -r pkt1 byte1 <<< "${file1_rules[$rule]}"
            IFS=: read -r pkt2 byte2 <<< "${file2_rules[$rule]}"
            pkt_diff=$(calculate_diff "$pkt1" "$pkt2")
            byte_diff=$(calculate_diff "$byte1" "$byte2")
            echo "[$pkt_diff:$byte_diff]$rule" >> "$output_file"
        else
            # Rule exists in file1 but not in file2
            echo "$rule - MISSING IN FILE2" >> "$output_file"
        fi
    fi
done

# Compare the lines without counters
for rule in "${!unmatched_lines_file1[@]}"; do
    if [[ -z "${unmatched_lines_file2[$rule]}" ]]; then
        echo "$rule - MISSING IN FILE2" >> "$output_file"
    else
        # Remove from unmatched list to prevent double-checking
        unset unmatched_lines_file2["$rule"]
    fi
done

# Check for any extra rules in file2 not in file1
for rule in "${!file2_rules[@]}"; do
    if [[ -z "${file1_rules[$rule]}" ]]; then
        echo "$rule - EXTRA IN FILE2" >> "$output_file"
    fi
done

# Check for any unmatched lines in file2 that were not in file1
for rule in "${!unmatched_lines_file2[@]}"; do
    echo "$rule - EXTRA IN FILE2" >> "$output_file"
done

echo "Packet rate differences calculated and saved in $output_file"
