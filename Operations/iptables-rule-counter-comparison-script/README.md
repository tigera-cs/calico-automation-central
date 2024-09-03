Overview

If you need to run iptables-save -c on the same node after a certain time (eg: 60 seconds) and you need to see the difference in counters of the rules, you can use the script below to do so.

You can save the output of the command in 2 separate files and this bash script:
Compares them and returns the difference of counters for the same iptables rules
If an iptables rule is missing in the second file, it will tell you so
If an iptables rule is extra in the second file, it will tell you so
Will save the comparison in the packet_rate_diff.txt file
Steps to use the script

SSH into a node
Run iptables-save -c > file1
Wait the required troubleshooting time (example: 60 seconds)
Run iptables-save -c > file2
Save the script below. Example: iptables_save_script.sh
Assign Execute permissions to it: sudo chmod +x iptables_save_script.sh
Run the script: bash iptables_save_script.sh file1 file2
