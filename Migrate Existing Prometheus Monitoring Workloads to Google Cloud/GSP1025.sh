#!/usr/bin/env bash

# ============================================================
#  Welcome to Yash Hirve's Lab Solutions
#  Author: Yash Hirve
#  Purpose: GKE + Google Managed Prometheus Lab Setup
# ============================================================

set -euo pipefail

# -------- Colors for output --------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# -------- Welcome banner --------
echo
echo "============================================================"
echo "  Welcome to Yash Hirve's Lab Solutions"
echo "============================================================"
echo

# -------- Variables --------
CLUSTER_NAME="gmp-cluster"
NAMESPACE="gmp-test"
PROM_VERSION="v0.4.3-gke.0"

# -------- Helper functions --------
info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
  echo -e "${RED}[ERROR]${NC} $1"
  exit 1
}

check_command() {
  command -v "$1" >/dev/null 2>&1 || error "$1 is not installed"
}

# -------- Pre-flight checks --------
info "Running pre-flight checks..."
check_command gcloud
check_command kubectl
check_command git
check_command curl
success "All required tools are installed"

# -------- User input --------
read -rp "Enter GCP zone (e.g. us-central1-a): " ZONE
[[ -z "$ZONE" ]] && error "Zone cannot be empty"

info "Using zone: $ZONE"
echo

# -------- Create GKE cluster --------
info "Creating GKE cluster: $CLUSTER_NAME"
gcloud container clusters create "$CLUSTER_NAME" \
  --num-nodes=3 \
  --zone="$ZONE"
success "Cluster created"

# -------- Get cluster credentials --------
info "Fetching cluster credentials"
gcloud container clusters get-credentials "$CLUSTER_NAME" \
  --zone="$ZONE"
success "kubectl configured"

# -------- Create namespace --------
info "Creating namespace: $NAMESPACE"
kubectl create namespace "$NAMESPACE" \
  || warn "Namespace already exists"
success "Namespace ready"

# -------- Deploy example application --------
info "Deploying example application"
kubectl -n "$NAMESPACE" apply -f \
  "https://raw.githubusercontent.com/GoogleCloudPlatform/prometheus-engine/${PROM_VERSION}/examples/example-app.yaml"

# -------- Deploy Prometheus --------
info "Deploying Google Managed Prometheus"
kubectl -n "$NAMESPACE" apply -f \
  "https://raw.githubusercontent.com/GoogleCloudPlatform/prometheus-engine/${PROM_VERSION}/examples/prometheus.yaml"

# -------- List pods --------
info "Listing pods in namespace: $NAMESPACE"
kubectl -n "$NAMESPACE" get pods

# -------- Fetch project ID --------
info "Fetching GCP project ID"
PROJECT_ID=$(gcloud config get-value project)
export PROJECT_ID
success "Project ID: $PROJECT_ID"

# -------- Deploy frontend --------
info "Deploying frontend service"
curl -s \
  "https://raw.githubusercontent.com/GoogleCloudPlatform/prometheus-engine/${PROM_VERSION}/examples/frontend.yaml" \
  | sed "s/\$PROJECT_ID/$PROJECT_ID/" \
  | kubectl apply -n "$NAMESPACE" -f -
success "Frontend deployed"

# -------- Clone kube-prometheus --------
info "Cloning kube-prometheus repository"
if [[ ! -d kube-prometheus ]]; then
  git clone https://github.com/prometheus-operator/kube-prometheus.git
  success "Repository cloned"
else
  warn "kube-prometheus already exists, skipping clone"
fi

# -------- Deploy Grafana --------
info "Deploying Grafana"
kubectl -n "$NAMESPACE" apply -f \
  "https://raw.githubusercontent.com/GoogleCloudPlatform/prometheus-engine/${PROM_VERSION}/examples/grafana.yaml"
success "Grafana deployed"

# -------- Completion message --------
echo
success "Setup complete 🎉"
echo
info "Access services using port-forwarding:"
echo "  kubectl -n $NAMESPACE port-forward svc/frontend 9090"
echo "  kubectl -n $NAMESPACE port-forward svc/grafana 3001:3000"
echo

