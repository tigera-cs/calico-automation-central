#!/usr/bin/env python3
from kubernetes import client, config

def list_unmatched_network_policies():
    # Load the kubeconfig file
    config.load_kube_config()

    # Create API clients
    v1 = client.CoreV1Api()
    networking_v1 = client.NetworkingV1Api()

    print("Kubernetes Policies with 0 endpoints attached are as below:\n")

    # Open a file to write the unmatched policies
    with open('kubernetes-unused-policies.txt', 'w') as file:

        # List all network policies
        network_policies = networking_v1.list_network_policy_for_all_namespaces()

        for np in network_policies.items:
            # Check if pod_selector.match_labels is None or empty
            if np.spec.pod_selector.match_labels:
                # Build a selector string from the policy's podSelector
                selector = ','.join([f'{k}={v}' for k, v in np.spec.pod_selector.match_labels.items()])
            else:
                # If match_labels is None or empty, it means all pods are selected
                selector = None

            # List all pods in the same namespace that match the policy's podSelector, if selector is not None
            if selector:
                pods = v1.list_namespaced_pod(np.metadata.namespace, label_selector=selector)
            else:
                # If selector is None, list all pods in the namespace
                pods = v1.list_namespaced_pod(np.metadata.namespace)

            pod_names = [pod.metadata.name for pod in pods.items]

            # If no pods matched, print and write the policy name
            if not pod_names:
                policy_info = f"Policy '{np.metadata.namespace}/{np.metadata.name}' has no endpoints attached.\n"
                print(policy_info)
                file.write(policy_info.strip() + "\n")  # Write policy info to file without extra newlines

    print("\nThe output has also been written to kubernetes-unused-policies.txt. Analyze it for further information.")

if __name__ == "__main__":
    list_unmatched_network_policies()
