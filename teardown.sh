#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -o errexit

echo "=========================================================="
echo "⚠️ COMMENCING SAFE INFRASTRUCTURE TEARDOWN ROUTINE"
echo "=========================================================="

# 1. Clean up Kubernetes services to remove any dynamic AWS Load Balancers
if aws eks update-kubeconfig --region us-east-1 --name dev-eks-cluster 2>/dev/null; then
    echo "🧼 Removing Kubernetes resources to clear external dependencies..."
    kubectl delete deployment springboot-app --ignore-not-found=true
    kubectl delete svc -A --all || true
    sleep 30 # Gives AWS time to safely de-provision active load balancers
else
    echo "ℹ️ EKS cluster not reachable or not provisioned yet. Skipping cluster cleanup."
fi

# 2. Clear out ECR registry images to allow the repository to delete cleanly
echo "🧼 Purging all container images from Amazon ECR..."
if aws ecr describe-repositories --repository-names springboot-app --region us-east-1 2>/dev/null; then
    IMAGES=$(aws ecr list-images --repository-name springboot-app --region us-east-1 --query 'imageIds[*]' --output json)
    if [ "$IMAGES" != "[]" ] && [ ! -z "$IMAGES" ]; then
        aws ecr batch-delete-image --repository-name springboot-app --region us-east-1 --image-ids "$IMAGES" || true
    fi
fi

# 3. Run Terraform Destroy to tear down the infrastructure safely
echo "🔥 Running Terraform Destroy..."
terraform destroy -auto-approve

echo "=========================================================="
echo "✅ TEARDOWN SUCCESSFUL: All resources safely removed."
echo "=========================================================="
