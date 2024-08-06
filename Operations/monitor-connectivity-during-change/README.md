# Monitoring Calico Networking During a Change (e.g.Upgrade) 

![Calico Logo](/images/logo/Tigera-Logo-Transparent.png)

## What the Script Does:

The scope of the script is to monitor connectivity and tigerastatus, for example, while upgrading k8s or CE/CC

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Customization](#customization)
- [Contributing](#contributing)
- [License](#license)
- [Troubleshooting](#troubleshooting)
- [Acknowledgements](#acknowledgements)

## Requirements

Ensure you have the following tools installed:

- Cluster must be installed using AWX
- You must be on the bastion instance on the AWX cluster
- [Bash](https://en.wikipedia.org/wiki/Bash_(Unix_shell))
- [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) v1.18 or later
- [SSH](https://www.cyberciti.biz/faq/how-to-install-ssh-on-ubuntu-linux-using-apt-get/)

## Installation

Clone this repository to the bastion instance:

```bash
git clone git@github.com:tigera-cs/automation-scripts-customer-success.git 
cd automation-scripts-customer-success/Operations/monitor-connectivity-during-change/ 

```

## Usage

- Set the bash script to be executable:
```bash
  chmod +x monitoring_script_awx.sh 
```
- Run the bash script:
```bash
   ./monitoring_script_awx.sh
```

The script then:
- Creates 4 pods (3 in worker1 and 1 in worker2)
- red1 pings red2 and saves the output in ping-output/ping.log in the red1 pod (pods on same node)
- red3 pings red4 and saves the output in ping-output/ping.log in the red3 pod (pod on different nodes)
- kubectl get tigerastatus is launched on control1 and the output is saved in the the control1 node /home/ubuntu/tigerastatus.log
- If you add the --kill option when launching the script, it deletes everything

### Other info:
#### Setup Variables:
- CONTROL_NODE set to control1
- LOG_FILE set to tigerastatus.log
#### Functions:
- kill_process:
  - Stop monitoring process
  - Delete pods (red1, red2, red3, red4)
  - Remove log file
- start_process:
  - Start monitoring process on CONTROL_NODE
#### Command-Line Argument:
- --kill: Runs kill_process and exits
#### Kubernetes Operations:
- Label nodes with nodegroup=group1 and nodegroup=group2
- Create and configure pods (red2, red4)
- Wait for red2 and red4 to be ready
- Fetch IPs of red2 and red4
- Create pods (red1, red3) to ping each other and log results
#### Start Monitoring:
- Begin monitoring process on CONTROL_NODE

## Customization

N/A

## Troubleshooting

If you encounter any issues, please check the following:

TBD


## Contributing

We welcome contributions from the community! To contribute, follow these steps:

- Fork this repository.
- Create a new branch with a descriptive name.
- Make your changes and commit them with clear messages.
- Push your changes to your fork.
- Submit a pull request with a detailed description of your changes.

## License

This project is licensed under the MIT License. See the LICENSE file for details.

