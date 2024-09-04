
# Iptables Rule Counter Comparison Script

![Calico Logo](/images/logo/Tigera-Logo-Transparent.png)

This script allows you to compare the counters of iptables rules by saving the output of `iptables-save -c` at different intervals and then identifying the differences between them. It is useful for troubleshooting by analyzing how rule counters have changed over time.

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Requirements

Ensure you have the following tools installed:

- [Bash Shell](https://www.gnu.org/software/bash/)
- [iptables](https://netfilter.org/projects/iptables/index.html)
- [SSH Access](https://www.ssh.com/ssh/)
- [Text Editor](https://www.nano-editor.org/), [vim](https://www.vim.org/), or similar for saving script files

## Installation

Clone this repository to your local machine:

```bash
git clone https://github.com/your-username/iptables-rule-counter-comparison.git
cd iptables-rule-counter-comparison
```

## Usage

Follow these steps to use the script:

1. SSH into the node where you want to analyze the iptables rules:

    ```bash
    ssh user@your-node-ip
    ```

2. Save the current iptables rule counters to a file:

    ```bash
    sudo iptables-save -c > file1
    ```

3. Wait for the required troubleshooting time (e.g., 60 seconds).

4. Save the iptables rule counters again to a second file:

    ```bash
    sudo iptables-save -c > file2
    ```

5. Save the script below as `iptables_save_script.sh`:

    ```bash
    nano iptables_save_script.sh
    ```

    Paste the script content into the file and save it.

6. Assign execute permissions to the script:

    ```bash
    sudo chmod +x iptables_save_script.sh
    ```

7. Run the script to compare the two files:

    ```bash
    bash iptables_save_script.sh file1 file2
    ```

    The comparison results will be saved in `packet_rate_diff.txt`.

## Customization

### Script Customization

You can modify the script to suit your specific needs:

- **File Names**: Change `file1` and `file2` to your preferred names when running the `iptables-save -c` command.
- **Output File**: By default, the script saves the comparison results to `packet_rate_diff.txt`. You can modify the script to change this output file name if needed.

## Troubleshooting

If you encounter any issues, please check the following:

- Ensure the `iptables-save -c` command is working correctly on your node.
- Verify that both `file1` and `file2` are saved correctly with no content truncation.
- Ensure the script has execute permissions.
- Check for any syntax errors in the script.

For further assistance, feel free to open an issue in this repository.

## Contributing

We welcome contributions from the community! To contribute, follow these steps:

- Fork this repository.
- Create a new branch with a descriptive name.
- Make your changes and commit them with clear messages.
- Push your changes to your fork.
- Submit a pull request with a detailed description of your changes.

## License

This project is licensed under the MIT License. See the LICENSE file for details.
