# WAF Dashboard for Observability with Kibana

![Calico Logo](/images/logo/Tigera-Logo-Transparent.png)

Automate the collection and visualization of **Web Application Firewall (WAF) Metrics** using Calico and Kibana. This repository provides all necessary resources and configurations to set up a **WAF Dashboard**, allowing users to gain insights into the activity and performance of WAF within their Kubernetes clusters.

## Table of Contents

- [Overview](#overview)
- [Requirements](#requirements)
- [How to Use](#how-to-use)
- [Customization](#customization)
- [Contribution](#contribution)
- [License](#license)
- [Support](#support)

## Overview

This repository contains scripts and configurations to help users collect and visualize **WAF Metrics** for their Kubernetes clusters using Calico. The collected metrics are visualized in **Kibana**, providing detailed insights into WAF activity, helping with monitoring, and troubleshooting web application security.

The WAF Dashboard can help users:
- Monitor WAF activity within the cluster.
- Identify potential threats or security incidents.
- Gain insights into the effectiveness of WAF rules for optimizing security.

For a detailed guide on how to use the provided WAF dashboard script, please refer to the video tutorial available here: [WAF Dashboard Video Guide](https://fast.wistia.com/embed/channel/lhjf79y3oy?wchannelid=lhjf79y3oy&wmediaid=5mus7q8whp).

## Requirements

Ensure you have the following tools and configurations:

- **Calico Enterprise** or **Calico Cloud** installed in your Kubernetes cluster.
- **Kibana** set up to visualize the collected WAF data.
- **Elasticsearch** configured as a data source for Kibana.
- Access to the **Calico WAF Logs** for collecting WAF metrics.
- **Git** installed to clone this repository.

## How to Use

1. Clone the repository to your local machine:
   ```bash
   git clone https://github.com/tigera-cs/calico-automation-central.git
   ```
2. Navigate to the script directory:
   ```bash
   cd calico-automation-central/Observability/WAF-Dashboard
   ```
3. Import the WAF dashboard into Kibana:
   - Use the provided script `waf-dashboard.ndjson` to import the pre-configured dashboard.
   - Follow the instructions in the video tutorial: [WAF Dashboard Video Guide](https://fast.wistia.com/embed/channel/lhjf79y3oy?wchannelid=lhjf79y3oy&wmediaid=5mus7q8whp).

4. Once imported, you can visualize the WAF metrics in **Kibana** to gain insights into your cluster's WAF activity.

## Customization

- **Kibana Dashboard**: The provided dashboard can be customized to match your monitoring requirements. You can add or modify visualizations to focus on specific WAF metrics.
- **WAF Metrics Collection**: Update the collection parameters to adjust the time range, namespaces, or specific nodes to match your observability needs.

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
