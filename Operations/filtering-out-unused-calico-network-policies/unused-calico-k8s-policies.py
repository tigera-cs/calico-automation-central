#!/usr/bin/env python3
import subprocess
from kubernetes import client, config

def calico_unused_policies():
    # Output file for Calico unused policies
    output_file = "calico-unused-policy.txt"

    # Clear the output file to avoid appending to old results
    open(output_file, 'w').close()

    # Fetch Calico NetworkPolicies with namespace and name
    cmd = "kubectl get networkpolicies.crd.projectcalico.org -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name --no-headers"
    result = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, check=True)
    policies_output = result.stdout.decode()

    # Process each policy to check for endpoints using calicoq
    for line in policies_output.splitlines():
        namespace, name = line.split()
        check_policy_endpoints(namespace, name, output_file)

    # Print the policies with 0 endpoints from the file to the terminal
    print("Policies with 0 endpoints attached are as below:\n")
    with open(output_file, 'r') as f:
        print(f.read())
    print(f"\nThe output has also been written to {output_file}. Analyze it for further information.")

def check_policy_endpoints(namespace, name, output_file):
    if not namespace or not name or name.startswith('allow-tigera'):
        return

    full_name = f"{namespace}/{name}"
    cmd = f"calicoq policy {full_name} -rs"
    result = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, check=True)
    output = result.stdout.decode()

    # Append to the file if the specific condition is met
    if "applies to these endpoints:" in output and "/eth0" not in output:
        with open(output_file, 'a') as f:
            f.write(f"Policy '{full_name}' has no endpoints attached.\n")

def list_unmatched_network_policies():
    # Load the kubeconfig file
    config.load_kube_config()

    # Create API clients
    v1 = client.CoreV1Api()
    networking_v1 = client.NetworkingV1Api()

    output_file = 'kubernetes-unused-policies.txt'
    # Clear the output file to avoid appending to old results
    open(output_file, 'w').close()

    print("\nKubernetes Policies with 0 endpoints attached are as below:\n")

    # Open a file to write the unmatched policies
    with open(output_file, 'a') as file:

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
                print(policy_info, end='')
                file.write(policy_info)  # Write policy info to file

    print(f"\nThe output has also been written to {output_file}. Analyze it for further information.")

if __name__ == "__main__":
    # Ensure the kubeconfig is loaded before executing functions
    config.load_kube_config()

    # Check and list unused Calico policies
    calico_unused_policies()

    # Then, list unmatched Kubernetes network policies
    list_unmatched_network_policies()