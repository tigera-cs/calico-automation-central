# Flow Log Dashboard for Observability with Kibana

![Calico Logo](/images/logo/Tigera-Logo-Transparent.png)

Automate the collection and visualization of **Flow Logs** using Calico and Kibana. 

## Table of Contents

- [Overview](#overview)
- [Requirements](#requirements)
- [How to Use](#how-to-use)
- [Customization](#customization)
- [Contribution](#contribution)
- [License](#license)
- [Support](#support)

## Overview

This repository contains scripts and configurations to help users collect and visualize **Flow Logs** for their Kubernetes clusters using Calico. The collected flow logs are visualized in **Kibana**, providing detailed insights into network flows for monitoring and troubleshooting. This repository provides all necessary resources and configurations to set up a **Flow Log Dashboard**, allowing users to gain insights into network traffic within their Kubernetes clusters.

The Flow Log Dashboard can help users:
- Monitor network activity within the cluster.
- Identify unexpected or anomalous traffic patterns.
- Gain insights into traffic flows for resource optimization.

For a detailed guide on how to use the provided flow log dashboard script, please refer to the video tutorial available here: [Flow Log Dashboard Video Guide](https://fast.wistia.com/embed/channel/lhjf79y3oy?wchannelid=lhjf79y3oy&wmediaid=24q8l9o7dt).

## Requirements

Ensure you have the following tools and configurations:

- **Calico Enterprise** or **Calico Cloud** installed in your Kubernetes cluster.
- **Kibana** set up to visualize the collected flow log data.
- **Elasticsearch** configured as a data source for Kibana.
- Access to the **Calico Flow Logs** for collecting flow log data.
- **Git** installed to clone this repository.

## How to Use

1. Clone the repository to your local machine:
   ```bash
   git clone https://github.com/tigera-cs/calico-automation-central.git
   ```
2. Navigate to the script directory:
   ```bash
   cd calico-automation-central/Observability/Flow-Log-Dashboard
   ```
3. Import the flow log dashboard into Kibana:
   - Use the provided script `flow-log-dashboard-live.ndjson` to import the pre-configured dashboard.
   - Follow the instructions in the video tutorial: [Flow Log Dashboard Video Guide](https://fast.wistia.com/embed/channel/lhjf79y3oy?wchannelid=lhjf79y3oy&wmediaid=24q8l9o7dt).

4. Once imported, you can visualize the flow logs in **Kibana** to gain insights into your cluster's network activity.

## Customization

- **Kibana Dashboard**: The provided dashboard can be customized to match your monitoring requirements. You can add or modify visualizations to focus on specific flow log metrics.
- **Flow Log Data Collection**: Update the collection parameters to adjust the time range, namespaces, or specific nodes to match your observability needs.

## Contribution

We welcome contributions from the community! To contribute, follow these steps:

- Fork this repository.
- Create a new branch with a descriptive name.
- Make your changes and commit them with clear messages.
- Push your changes to your fork.
- Submit a pull request with a detailed description of your changes.

## License

This project is licensed under the [MIT License](LICENSE).

## Support

If you need support or have questions, check out our community forum or contact the maintainers via [email/issue tracker].
