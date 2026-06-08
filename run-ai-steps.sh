#!/bin/bash

# pull the chart and see the contents
helm pull oci://ghcr.io/run-ai/fake-gpu-operator/fake-gpu-operator

# it contains gpu-operator & nvidia-dra-driver-gpu as deps and a chart template of its own

# install operator
helm upgrade -i gpu-operator oci://ghcr.io/run-ai/fake-gpu-operator/fake-gpu-operator \
	--namespace gpu-operator \
	--create-namespace \
	--version 0.0.82

# deploying the test workload does not work

cat << EOF > test-workload.yaml
apiVersion: v1
kind: Pod
metadata:
  name: gpu-pod
spec:
  containers:
  - name: gpu-container
    image: nvidia/cuda-vector-add:v0.1
    resources:
      limits:
        nvidia.com/gpu: 1
EOF

# because cannot download the image

