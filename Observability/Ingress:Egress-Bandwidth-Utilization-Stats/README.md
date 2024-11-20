# Ingress/Egress Bandwidth Utilization Stats for Observability with Kibana

![Calico Logo](/images/logo/Tigera-Logo-Transparent.png)

Automate the collection and visualization of **Ingress/Egress Bandwidth Utilization** statistics using Calico and Kibana. This repository provides all necessary resources and configurations to set up bandwidth monitoring and visualization, allowing users to gain insights into network traffic usage within their Kubernetes clusters.

## Table of Contents

- [Overview](#overview)
- [Requirements](#requirements)
- [How to Use](#how-to-use)
- [Customization](#customization)
- [Contribution](#contribution)
- [License](#license)
- [Support](#support)

## Overview

This repository contains scripts and configurations to help users collect and visualize **Ingress and Egress Bandwidth Utilization Stats** for their Kubernetes clusters using Calico. The data collected is visualized in **Kibana** to help monitor network performance and resource utilization.

For a detailed guide on how to import custom dashboards in Kibana and use the provided scripts, please refer to the documentation located at: `calico-automation-central/Observability/Ingress:Egress-Bandwidth-Utilization-Stats/Documentation-How to Import Custom Dashboard in Kibana-310724-205613.pdf`.

## Requirements

Ensure you have the following tools and configurations:

- **Calico Enterprise** or **Calico Cloud** installed in your Kubernetes cluster.
- **Kibana** set up to visualize the collected network data.
- **Elasticsearch** configured as a data source for Kibana.
- Access to the **Calico Flow Logs** to collect ingress and egress bandwidth statistics.
- **Git** installed to clone this repository.

## How to Use

1. Clone the repository to your local machine:
   ```bash
   git clone https://github.com/tigera-cs/calico-automation-central.git
   ```
2. Navigate to the script directory:
   ```bash
   cd calico-automation-central/Observability/Ingress:Egress-Bandwidth-Utilization-Stats
   ```
3. Follow the steps in the documentation to import the custom Kibana dashboard:
   - Open the provided PDF documentation: `Documentation-How to Import Custom Dashboard in Kibana-310724-205613.pdf`.
   - Follow the instructions to import the pre-configured dashboard into Kibana.

4. Run the script to collect ingress and egress bandwidth statistics from your Kubernetes cluster. The data will be automatically sent to **Elasticsearch**, allowing you to visualize it in **Kibana**.

## Customization

- **Kibana Dashboard**: The provided dashboard can be customized to match your monitoring requirements. You can add or modify visualizations to focus on specific network metrics.
- **Data Collection Configuration**: Update the configuration scripts to adjust the parameters for data collection, such as time intervals, namespaces, or specific nodes of interest.

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
