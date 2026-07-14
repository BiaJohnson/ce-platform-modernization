#!/usr/bin/env bash
# Day-0 GCP setup for platform modernization PoC
# Override with: export PROJECT_ID=... REGION=...

set -euo pipefail

PROJECT_ID="${PROJECT_ID:-your-gcp-project-id}"
REGION="${REGION:-us-central1}"

echo "==> Configuring gcloud for project: ${PROJECT_ID}"
gcloud config set project "${PROJECT_ID}"
gcloud config set compute/region "${REGION}"

echo "==> Linking billing (if not already linked)"
BILLING_ACCOUNT="$(gcloud billing accounts list --filter='open=true' --format='value(name)' | head -1 || true)"
if [[ -z "${BILLING_ACCOUNT}" ]]; then
  echo "No open billing account found. Link billing in the console first:"
  echo "https://console.cloud.google.com/billing/linkedaccount?project=${PROJECT_ID}"
  exit 1
fi

gcloud billing projects link "${PROJECT_ID}" --billing-account="${BILLING_ACCOUNT}" || true

echo "==> Enabling required APIs"
gcloud services enable \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  iam.googleapis.com \
  logging.googleapis.com \
  cloudresourcemanager.googleapis.com \
  --project="${PROJECT_ID}"

echo "==> Success check"
gcloud run services list --project="${PROJECT_ID}" --region="${REGION}"

echo ""
echo "Day-0 setup complete for ${PROJECT_ID}"
echo "Next: create budget alerts (see scripts/gcp-budget-alerts.sh or console steps in SETUP.md)"
