#!/usr/bin/env bash
# Create $10 and $50 budget alerts for the PoC billing account.
# Requires: gcloud auth login, billing.budgets.create permission
# Override with: export PROJECT_ID=...

set -euo pipefail

PROJECT_ID="${PROJECT_ID:-your-gcp-project-id}"

BILLING_ACCOUNT="$(gcloud billing accounts list --filter='open=true' --format='value(name)' | head -1)"
if [[ -z "${BILLING_ACCOUNT}" ]]; then
  echo "No billing account found."
  exit 1
fi

BILLING_ACCOUNT_ID="${BILLING_ACCOUNT#billingAccounts/}"
USER_EMAIL="$(gcloud config get-value account 2>/dev/null)"

create_budget() {
  local amount="$1"
  local budget_id="poc-budget-${amount}-usd"

  echo "==> Creating budget alert: \$${amount} for project ${PROJECT_ID}"
  gcloud billing budgets create \
    --billing-account="${BILLING_ACCOUNT_ID}" \
    --display-name="PoC alert \$${amount}" \
    --budget-amount="${amount}USD" \
    --threshold-rule=percent=50 \
    --threshold-rule=percent=90 \
    --threshold-rule=percent=100 \
    --filter-projects="projects/${PROJECT_ID}" \
    --notifications-rule-pubsub-topic="" \
    --notifications-rule-monitoring-notification-channels="" \
    2>/dev/null || \
  gcloud billing budgets create \
    --billing-account="${BILLING_ACCOUNT_ID}" \
    --display-name="PoC alert \$${amount}" \
    --budget-amount="${amount}USD" \
    --threshold-rule=percent=50 \
    --threshold-rule=percent=90 \
    --threshold-rule=percent=100 \
    --filter-projects="projects/${PROJECT_ID}"
}

create_budget 10
create_budget 50

echo ""
echo "Budget alerts created for project ${PROJECT_ID}"
echo "Add email notifications in console if not set automatically:"
echo "https://console.cloud.google.com/billing/${BILLING_ACCOUNT_ID}/budgets"
