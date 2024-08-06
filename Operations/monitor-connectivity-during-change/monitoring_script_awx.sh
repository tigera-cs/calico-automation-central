#!/bin/bash

# Define control node and log file
CONTROL_NODE="control1"
LOG_FILE="tigerastatus.log"

# Function to kill the monitoring process and delete pods
kill_process() {
    # Kill the monitoring process
    ssh $CONTROL_NODE "pkill -f 'kubectl get tigerastatus'"
    
    # Delete the pods
    ssh $CONTROL_NODE "kubectl delete pod red1 red2 red3 red4"
    
    # Optionally, remove the log file if desired
    ssh $CONTROL_NODE "rm -f $LOG_FILE"
    
    echo "Monitoring process stopped and pods deleted on $CONTROL_NODE."
}

# Function to start the monitoring process
start_process() {
    COMMAND='while true; do echo && date && kubectl get tigerastatus && sleep 1; done > tigerastatus.log'
    ssh $CONTROL_NODE "nohup bash -c \"$COMMAND\" > /dev/null 2>&1 &"
    echo "Monitoring process started on $CONTROL_NODE."
}

# Check command-line arguments
if [ "$1" == "--kill" ]; then
    kill_process
    exit 0
fi

# Label the nodes
kubectl label nodes ip-10-0-1-30.ca-central-1.compute.internal nodegroup=group1
kubectl label nodes ip-10-0-1-31.ca-central-1.compute.internal nodegroup=group2

# Apply the pod configurations with the init containers
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: red2
  labels:
    app: red
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: nodegroup
            operator: In
            values:
            - group1
  containers:
  - name: red2
    image: busybox
    command: ["/bin/sh", "-c", "tail -f /dev/null"]
---
apiVersion: v1
kind: Pod
metadata:
  name: red4
  labels:
    app: red
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: nodegroup
            operator: In
            values:
            - group2
  containers:
  - name: red4
    image: busybox
    command: ["/bin/sh", "-c", "tail -f /dev/null"]
EOF

# Function to check if a pod is ready
is_pod_ready() {
  kubectl get pod $1 -o=jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null | grep -q 'True'
}

# Wait until red2 and red4 are running
for i in {1..10}; do
  if is_pod_ready red2 && is_pod_ready red4; then
    break
  fi
  echo "Waiting for pods to be ready..."
  sleep 10
done

# Fetch pod IPs
RED2=$(kubectl get pod red2 -o=jsonpath='{.status.podIP}' 2>/dev/null)
RED4=$(kubectl get pod red4 -o=jsonpath='{.status.podIP}' 2>/dev/null)

if [[ -z "$RED2" || -z "$RED4" ]]; then
  echo "Pods are not ready. Exiting."
  exit 1
fi

echo "RED2 IP: $RED2"
echo "RED4 IP: $RED4"

# Apply red1 pod configuration
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: red1
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: nodegroup
            operator: In
            values:
            - group1
  containers:
  - name: red1
    image: busybox
    command: ["/bin/sh"]
    args: ["-c", "while true; do echo \"\$(date): \$(timeout 1 ping -c 1 -W 1 $RED2 > /dev/null && echo 'Ping successful' || echo 'Ping failed')\" >> /ping-output/ping.log; sleep 1; done"]
    volumeMounts:
    - name: ping-output
      mountPath: /ping-output
  volumes:
  - name: ping-output
    emptyDir: {}
EOF

# Apply red3 pod configuration
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: red3
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: nodegroup
            operator: In
            values:
            - group1
  containers:
  - name: red3
    image: busybox
    command: ["/bin/sh"]
    args: ["-c", "while true; do echo \"\$(date): \$(timeout 1 ping -c 1 -W 1 $RED4 > /dev/null && echo 'Ping successful' || echo 'Ping failed')\" >> /ping-output/ping.log; sleep 1; done"]
    volumeMounts:
    - name: ping-output
      mountPath: /ping-output
  volumes:
  - name: ping-output
    emptyDir: {}
EOF

# Start the monitoring process
start_process
