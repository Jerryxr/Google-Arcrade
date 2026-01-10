#!/bin/bash
set -e

# ==============================
# GKE Hello App Lab Script
# ==============================

# Default values (can be overridden by environment variables)
REGION=${REGION:-us-central1}
ZONE=${ZONE:-us-central1-a}
CLUSTER_NAME=${CLUSTER_NAME:-lab-cluster}
MACHINE_TYPE=${MACHINE_TYPE:-e2-medium}

echo "=== GCP Authentication Check ==="
gcloud auth list

PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [[ -z "$PROJECT_ID" ]]; then
  echo "❌ No active project found. Set your project using:"
  echo "   gcloud config set project YOUR_PROJECT_ID"
  exit 1
fi

echo "Using Project: $PROJECT_ID"
echo

# Set region and zone
echo "Setting compute region and zone..."
gcloud config set compute/region "$REGION"
gcloud config set compute/zone "$ZONE"
echo

# Confirm with user before creating resources
echo "⚠️ This lab creates billable GKE resources."
read -p "Do you want to continue? (y/n): " CONFIRM
[[ "$CONFIRM" != "y" ]] && exit 0
echo

# Create GKE cluster
echo "=== Creating GKE Cluster: $CLUSTER_NAME ==="
gcloud container clusters create "$CLUSTER_NAME" \
  --machine-type="$MACHINE_TYPE" \
  --zone="$ZONE"
echo

# Fetch cluster credentials
echo "=== Fetching Cluster Credentials ==="
gcloud container clusters get-credentials "$CLUSTER_NAME" \
  --zone="$ZONE"
echo

# Deploy sample application
echo "=== Deploying Kubernetes Application ==="
kubectl create deployment hello-server \
  --image=gcr.io/google-samples/hello-app:1.0
echo

# Expose deployment via LoadBalancer
echo "=== Exposing Deployment via LoadBalancer ==="
kubectl expose deployment hello-server \
  --type=LoadBalancer \
  --port=8080
echo

# Show service info
echo "=== Service Details ==="
kubectl get service hello-server
echo
echo "✅ Lab setup complete. Wait a few minutes for the EXTERNAL-IP to appear."
echo

# Optional cleanup
read -p "Do you want to delete the GKE cluster now? (y/n): " CLEANUP
if [[ "$CLEANUP" == "y" ]]; then
  echo "=== Deleting GKE Cluster ==="
  gcloud container clusters delete "$CLUSTER_NAME" \
    --zone="$ZONE" \
    --quiet
  echo "Cluster deleted."
else
  echo "⚠️ Remember to delete the cluster later to avoid charges."
fi

echo "=== Script Completed ==="

