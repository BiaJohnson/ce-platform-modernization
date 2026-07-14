#!/usr/bin/env bash
# Build container images with Cloud Build and push to Artifact Registry.
# No local Docker required (AWS analogy: CodeBuild → ECR).

set -euo pipefail

PROJECT_ID="${PROJECT_ID:-your-gcp-project-id}"
REGION="${REGION:-us-central1}"
REPO="${REPO:-platform}"
TAG="${TAG:-v1}"

REGISTRY="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Project: ${PROJECT_ID}"
echo "==> Registry: ${REGISTRY}"

gcloud config set project "${PROJECT_ID}" >/dev/null

echo "==> Ensuring Artifact Registry repo '${REPO}' exists"
if ! gcloud artifacts repositories describe "${REPO}" \
  --location="${REGION}" \
  --project="${PROJECT_ID}" >/dev/null 2>&1; then
  gcloud artifacts repositories create "${REPO}" \
    --repository-format=docker \
    --location="${REGION}" \
    --description="Platform modernization PoC images" \
    --project="${PROJECT_ID}"
fi

echo "==> Enabling Cloud Build API (builds images in GCP)"
gcloud services enable cloudbuild.googleapis.com artifactregistry.googleapis.com \
  --project="${PROJECT_ID}"

# Cloud Build's default SA needs permission to push to Artifact Registry
PROJECT_NUMBER="$(gcloud projects describe "${PROJECT_ID}" --format='value(projectNumber)')"
CB_SA="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"
echo "==> Granting Artifact Registry Writer to ${CB_SA}"
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${CB_SA}" \
  --role="roles/artifactregistry.writer" \
  --condition=None \
  >/dev/null

build_and_push() {
  local name="$1"
  local context="${ROOT}/apps/${name}"
  local image="${REGISTRY}/${name}:${TAG}"
  echo "==> Building ${image}"
  gcloud builds submit "${context}" \
    --tag "${image}" \
    --project="${PROJECT_ID}"
  echo "==> Pushed ${image}"
}

build_and_push internal-api
build_and_push public-api

echo ""
echo "Done. Images:"
echo "  ${REGISTRY}/internal-api:${TAG}"
echo "  ${REGISTRY}/public-api:${TAG}"
echo ""
echo "List them with:"
echo "  gcloud artifacts docker images list ${REGISTRY}"
