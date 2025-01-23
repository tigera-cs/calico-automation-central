# Calico Automation Central
![Calico Enterprise](https://docs.tigera.io/img/calico-enterprise-logo.webp)\
**Disclaimer**

This repository is a collection of automation scripts and operational process documents designed to assist users of Calico Enterprise, Calico Cloud, and Calico Open Source.
These resources are provided by Tigera support and delivery team members as a voluntary effort to benefit our customers and the broader community.
While we strive to ensure the scripts are helpful and functional, they are not part of Tigera’s official product offerings. As such:\
_They are not officially supported by Tigera._\
_Use them at your own discretion and ensure thorough testing in your environment before deploying them.\
No guarantees are provided regarding their suitability, performance, or maintenance.\
We encourage you to explore these resources and adapt them as needed to meet your specific use cases._

# Repository Structure

**Installation**

If you’re looking to automate the deployment of your solution, we strongly recommend visiting our installation repository as a starting point.
Operations
This directory includes scripts designed for various operational tasks related to Kubernetes clusters and Calico Enterprise. Tasks range from filtering unused Calico policies to comparing iptables or managing migration from kubectl based installation to Helm based Installation on AKS.

**Observability**

Scripts in this directory focus on observability tasks such as logging, tracing, and metrics collection to help monitor and maintain your infrastructure effectively.

**Vulnerability Management**

This directory contains scripts for managing vulnerabilities and performing security scans in Calico Enterprise. It also includes instructions for integrating these processes with tools like Kenkis in Azure DevOps pipelines.
