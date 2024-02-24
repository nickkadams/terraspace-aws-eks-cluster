#!/bin/bash

### Initial deployment
kubectl apply -f demo-deployment.yaml
echo ""
kubectl get nodes --sort-by=.metadata.creationTimestamp
echo ""
kubectl get pods --sort-by=.metadata.creationTimestamp
echo ""

### Scale out
echo "Scale out to 30 pods"
kubectl scale --replicas=30 deployment/demo-deployment
sleep 45
echo ""
kubectl get pods --sort-by=.metadata.creationTimestamp
echo ""
kubectl get nodes --sort-by=.metadata.creationTimestamp
echo ""

### Scale more
echo "Scale out to 45 pods"
kubectl scale --replicas=45 deployment/demo-deployment
sleep 45
echo ""
kubectl get pods --sort-by=.metadata.creationTimestamp
echo ""
kubectl get nodes --sort-by=.metadata.creationTimestamp
echo ""

### Scale more more
echo "Scale out to 100 pods"
kubectl scale --replicas=100 deployment/demo-deployment
sleep 45
echo ""
kubectl get pods --sort-by=.metadata.creationTimestamp
echo ""
kubectl get nodes --sort-by=.metadata.creationTimestamp
echo ""

### Scale in
echo "Scale in to 1 pod"
kubectl scale --replicas=1 deployment/demo-deployment
sleep 45
echo ""
kubectl get nodes --sort-by=.metadata.creationTimestamp
echo ""
kubectl get pods --sort-by=.metadata.creationTimestamp
