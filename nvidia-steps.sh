#!/bin/bash

# install kwok
kubectl apply -f https://github.com/kubernetes-sigs/kwok/releases/download/v0.7.0/kwok.yaml

# verify kwok exists
kubectl get pods -n kube-system -l app=kwok-controller
# Expected: kwok-controller-...   1/1   Running


# add fake gpu operator jfrog repository
helm repo add fake-gpu-operator \
  https://runai.jfrog.io/artifactory/api/helm/fake-gpu-operator-charts-prod \
  --force-update

# install fake gpu-operator
# will install 0.0.82
helm upgrade -i gpu-operator fake-gpu-operator/fake-gpu-operator \
  -n gpu-operator --create-namespace \
  --set 'topology.nodePools.default.gpuCount=8' \
  --set 'topology.nodePools.default.gpuProduct=NVIDIA-H100-80GB-HBM3'


# label a node so that fake-gpu-operator starts working
kubectl label node node-01 run.ai/simulated-gpu-node-pool=default


# verify node status & maybe do it before and after label application
k get nodes node-01 -o yaml | yq ".status.allocatable"

# deploy a test workload
# this only works because we have fake-gpu-operator running
# if we unlabel the node then this same deployment will not work
cat << EOF > test-workload.yaml
apiVersion: v1
kind: Pod
metadata:
  name: gpu-pod
spec:
  containers:
  - name: gpu-container
    image: nginx    
    resources:
      limits:
        nvidia.com/gpu: 1
EOF

# unlabel the pod
kubectl label node node-01 run.ai/simulated-gpu-node-pool-

# try and show to do the above deployment again.
# it will show that the pod is in pending state
#
#
#
# message: '0/3 nodes are available: 3 Insufficient nvidia.com/gpu. no new claims
# to deallocate, preemption: 0/3 nodes are available: 3 Preemption is not helpful
# for scheduling.
#
#
#
# with the above message


# set the node label again
# label a node so that fake-gpu-operator starts working
kubectl label node node-01 run.ai/simulated-gpu-node-pool=default


# let the people know that the pod gets allocated with a gpu currently deployed to it
# you can even add labels to a pod such that it simulates and gives out fake metrics
# about gpu usage

# deploy a test workload
cat << EOF > test-simulate-usage-workload.yaml
apiVersion: v1
kind: Pod
metadata:
  name: gpu-simulate-usage-pod
  annotations:
    run.ai/simulated-gpu-utilization: "10-30"  # Simulate 10-30% GPU usage
spec:
  containers:
  - name: gpu-container
    image: nginx    
    resources:
      limits:
        nvidia.com/gpu: 1
EOF

# it exposes metrics which can be viewed via metrics server apis but our 
# current clusters do not export metrics by default i.e. k8s-omni

# install metrics server
wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# edit the deployment to use
# --kubelet-insecure-tls

# apply
kubectl apply -f components.yaml

# I tried setting up a metrics server and was able to do so quickly by disabling
# metrics server but the default metrics server made by kubernetes does not yet
# export metrics for gpu resources and the kubectl top pods or kubectl top nodes
# will not showcase any metrics for gpu usage


############# THANK YOU ####################


