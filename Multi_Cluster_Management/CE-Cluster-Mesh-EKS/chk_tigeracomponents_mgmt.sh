#!/bin/bash

# Wait until all component come up shows a status of Available=True
echo ""
echo "Wait until the Calico components shows a status of Available=True ..."
while true; do
    LOGSTACCESS=$(kubectl get tigerastatuses/log-storage-access --no-headers | awk '{print $2}')
    LOGSTRG=$(kubectl get tigerastatuses/log-storage --no-headers | awk '{print $2}')
    CALNODE=$(kubectl get tigerastatuses/calico --no-headers | awk '{print $2}')
    LOGSTELASTIC=$(kubectl get tigerastatuses/log-storage-elastic --no-headers | awk '{print $2}')
    ELASTIC_ECK=$(kubectl get -n tigera-elasticsearch elastic --no-headers | awk '{print $2}')

    if [ "$LOGSTACCESS" == "True" ] && [ "$LOGSTRG" == "True" ] && [ "$CALNODE" == "True" ] && [ "$LOGSTELASTIC" == "True" ] && [ "$ELASTIC_ECK" == "green" ]; then
        echo "All statuses are True:"
        echo "LOG STORGAE ACCESS: $LOGSTACCESS"
        echo "LOGS STORGAE : $LOGSTRG"
        echo "CALICO NODE: $CALNODE"
        echo "LOG STORGAE ELASTIC: $LOGSTELASTIC"
        echo "ELASTIC_ECK_HEALTH: $ELASTIC_ECK"
        echo "----------------------------"
        break
    else
        echo "Current statuses:"
        echo "LOG STORGAE ACCESS: $LOGSTACCESS"
        echo "LOGS STORGAE : $LOGSTRG"
        echo "CALICO NODE: $CALNODE"
        echo "LOG STORGAE ELASTIC: $LOGSTELASTIC"
        echo "ELASTIC_ECK_HEALTH: $ELASTIC_ECK"
        echo "Still waiting for the Calico component become available=True"
        echo "----------------------------"
        echo "Retrying in 60 seconds..."
        echo "----------------------------"
        sleep 60
    fi
done
