#!/bin/bash

# Wait until all component come up shows a status of Available=True
echo ""
echo "Wait until the Calico components shows a status of Available=True ..."
while true; do
    CALNODE=$(kubectl get tigerastatuses/calico --no-headers | awk '{print $2}')
    POLREC=$(kubectl get tigerastatuses/policy-recommendation --no-headers | awk '{print $2}')
    MONTR=$(kubectl get tigerastatuses/monitor --no-headers | awk '{print $2}')
    LOGCOL=$(kubectl get tigerastatuses/log-collector --no-headers | awk '{print $2}')
    IPP=$(kubectl get tigerastatuses/ippools --no-headers | awk '{print $2}')
    MGMTCON=$(kubectl get tigerastatuses/management-cluster-connection --no-headers | awk '{print $2}')
    if [ "$CALNODE" == "True" ] && [ "$POLREC" == "True" ] && [ "$MONTR" == "True" ] && [ "$LOGCOL" == "True" ] && [ "$IPP" == "True" ] && [ "$MGMTCON" == "True" ]; then
        echo "All statuses are True:"
        echo "CALICO NODE: $CALNODE"
        echo "policy-recommendation: $POLREC"
        echo "monitor: $MONTR"
        echo "log-collector: $LOGCOL"
        echo "ippools: $IPP"
        echo "management-cluster-connection: $MGMTCON"
        echo "----------------------------"
        break
    else
        echo "Current statuses:"
        echo "CALICO NODE: $CALNODE"
        echo "policy-recommendation: $POLREC"
        echo "monitor: $MONTR"
        echo "Log-collector: $LOGCOL"
        echo "ippools: $IPP"
        echo "management-cluster-connection: $MGMTCON"
        echo "Still waiting for the Calico component become available=True"
        echo "----------------------------"
        echo "Retrying in 60 seconds..."
        echo "----------------------------"
        sleep 60
    fi
done
