#!/bin/bash
set -e

# =======================
# GKE Challenge Lab Script
# =======================

# Default values (can be overridden by environment variables)
REGION=${REGION:-us-central1}
ZONE=${ZONE:-us-central1-a}
CLUSTER_NAME=${CLUSTER_NAME:-lab-gke-cluster}
MACHINE_TYPE=${MACHINE_TYPE:-e2-medium}

echo "=== GKE Hello App Challenge Lab ==="
echo

# Check active project
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [[ -z "$PROJECT_ID" ]]; then
  echo "❌ No active GCP project found."
  echo "Run: gcloud config set project YOUR_PROJECT_ID"
  exit 1
fi

echo "Using Project: $PROJECT_ID"
echo

# Set region and zone
echo "Setting compute region and zone..."
gcloud config set compute/region "$REGION" >/dev/null
gcloud config set compute/zone "$ZONE" >/dev/null

echo
echo "⚠️ WARNING: This lab creates billable GKE resources."
read -p "Do you want to continue? (y/n): " CONFIRM
[[ "$CONFIRM" != "y" ]] && exit 0
echo

# Create GKE cluster
echo "Creating GKE cluster..."
gcloud container clusters create "$CLUSTER_NAME" \
  --machine-type="$MACHINE_TYPE" \
  --zone="$ZONE"

echo
echo "Fetching cluster credentials..."
gcloud container clusters get-credentials "$CLUSTER_NAME" \
  --zone="$ZONE"

# Deploy application
echo
echo "Creating Kubernetes deployment..."
kubectl create deployment hello-server \
  --image=gcr.io/google-samples/hello-app:1.0

# Expose service
echo
echo "Exposing deployment via LoadBalancer..."
kubectl expose deployment hello-server \
  --type=LoadBalancer \
  --port=8080

echo
echo "Retrieving service details..."
kubectl get service hello-server

echo
echo "✅ Lab setup complete."
echo "⏳ Wait a few minutes for the EXTERNAL-IP to appear."
echo "🌐 Access the app at: http://EXTERNAL-IP:8080"
echo
echo "⚠️ Remember to delete the cluster after completing the lab:"
echo "gcloud container clusters delete $CLUSTER_NAME --zone $ZONE"

