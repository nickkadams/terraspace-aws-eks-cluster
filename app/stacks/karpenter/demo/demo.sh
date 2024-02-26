#!/bin/bash

### Initial deployment
kubectl apply -f demo-deployment.yaml
echo ""
# kubectl get nodes --sort-by=.metadata.creationTimestamp
kubectl get nodes -o json | jq -Cjr '.items[] | .metadata.name," ",.metadata.labels."beta.kubernetes.io/instance-type"," ",.metadata.labels."eks.amazonaws.com/nodegroup"," ",.metadata.creationTimestamp, "\n"' | sort -k4
echo ""
kubectl get pods --sort-by=.metadata.creationTimestamp
echo ""

### Scale out
echo "Scale out to 30 pods"
echo ""
kubectl scale --replicas=30 deployment/demo-deployment
sleep 50
echo ""
kubectl get pods --sort-by=.metadata.creationTimestamp
echo ""
kubectl get nodes -o json | jq -Cjr '.items[] | .metadata.name," ",.metadata.labels."beta.kubernetes.io/instance-type"," ",.metadata.labels."eks.amazonaws.com/nodegroup"," ",.metadata.creationTimestamp, "\n"' | sort -k4
echo ""

### Scale more
echo "Scale out to 45 pods"
echo ""
kubectl scale --replicas=45 deployment/demo-deployment
sleep 50
echo ""
kubectl get pods --sort-by=.metadata.creationTimestamp
echo ""
kubectl get nodes -o json | jq -Cjr '.items[] | .metadata.name," ",.metadata.labels."beta.kubernetes.io/instance-type"," ",.metadata.labels."eks.amazonaws.com/nodegroup"," ",.metadata.creationTimestamp, "\n"' | sort -k4
echo ""

### Scale more more
echo "Scale out to 100 pods"
echo ""
kubectl scale --replicas=100 deployment/demo-deployment
sleep 50
echo ""
kubectl get pods --sort-by=.metadata.creationTimestamp
echo ""
kubectl get nodes -o json | jq -Cjr '.items[] | .metadata.name," ",.metadata.labels."beta.kubernetes.io/instance-type"," ",.metadata.labels."eks.amazonaws.com/nodegroup"," ",.metadata.creationTimestamp, "\n"' | sort -k4
echo ""

### Scale in
echo "Scale in to 1 pod"
echo ""
kubectl scale --replicas=1 deployment/demo-deployment
sleep 75
echo ""
kubectl get nodes -o json | jq -Cjr '.items[] | .metadata.name," ",.metadata.labels."beta.kubernetes.io/instance-type"," ",.metadata.labels."eks.amazonaws.com/nodegroup"," ",.metadata.creationTimestamp, "\n"' | sort -k4
echo ""
kubectl get pods --sort-by=.metadata.creationTimestamp
