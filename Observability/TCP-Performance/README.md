# TCP Performance Dashboard for Observability with Kibana

![Calico Logo](/images/logo/Tigera-Logo-Transparent.png)

Automate the collection and visualization of **TCP Performance Metrics** using Calico and Kibana. This repository provides all necessary resources and configurations to set up a **TCP Performance Dashboard**, allowing users to gain insights into the performance of TCP connections within their Kubernetes clusters.

## Table of Contents

- [Overview](#overview)
- [Requirements](#requirements)
- [How to Use](#how-to-use)
- [Customization](#customization)
- [Contribution](#contribution)
- [License](#license)
- [Support](#support)

## Overview

This repository contains scripts and configurations to help users collect and visualize **TCP Performance Metrics** for their Kubernetes clusters using Calico. The collected metrics are visualized in **Kibana**, providing detailed insights into the performance of TCP connections, aiding in monitoring and troubleshooting network performance issues.

The TCP Performance Dashboard can help users:
- Monitor TCP connection performance within the cluster.
- Identify bottlenecks or slow connections.
- Gain insights into network performance for optimization.

For a detailed guide on how to use the provided TCP performance dashboard script, please refer to the video tutorial available here: [TCP Performance Dashboard Video Guide](https://fast.wistia.com/embed/channel/lhjf79y3oy?wchannelid=lhjf79y3oy&wmediaid=sk1g5jn0cv).

## Requirements

Ensure you have the following tools and configurations:

- **Calico Enterprise** or **Calico Cloud** installed in your Kubernetes cluster.
- **Kibana** set up to visualize the collected TCP performance data.
- **Elasticsearch** configured as a data source for Kibana.
- Access to the **Calico Flow Logs** for collecting TCP performance metrics.
- **Git** installed to clone this repository.

## How to Use

1. Clone the repository to your local machine:
   ```bash
   git clone https://github.com/tigera-cs/calico-automation-central.git
   ```
2. Navigate to the script directory:
   ```bash
   cd calico-automation-central/Observability/TCP-Performance
   ```
3. Import the TCP performance dashboard into Kibana:
   - Use the provided script `tcp-performance-live.ndjson` to import the pre-configured dashboard.
   - Follow the instructions in the video tutorial: [TCP Performance Dashboard Video Guide](https://fast.wistia.com/embed/channel/lhjf79y3oy?wchannelid=lhjf79y3oy&wmediaid=sk1g5jn0cv).

4. Once imported, you can visualize the TCP performance metrics in **Kibana** to gain insights into your cluster's TCP activity.

## Customization

- **Kibana Dashboard**: The provided dashboard can be customized to match your monitoring requirements. You can add or modify visualizations to focus on specific TCP metrics.
- **TCP Metrics Collection**: Update the collection parameters to adjust the time range, namespaces, or specific nodes to match your observability needs.

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
