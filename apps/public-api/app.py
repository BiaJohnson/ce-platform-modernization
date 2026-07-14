"""
Public API — edge tier.

GET /api/orders:
  1. Fetch a Google identity token for the internal service URL (audience)
  2. Call internal service with Authorization: Bearer <token>
  3. Return the combined response

On Cloud Run, identity tokens come from the metadata server (like AWS instance
profiles / IRSA, but for Google service accounts). Locally, Application Default
Credentials can mint tokens if you are logged in with gcloud.
"""

import os

import google.auth.transport.requests
import google.oauth2.id_token
import requests
from flask import Flask, jsonify

app = Flask(__name__)

INTERNAL_SERVICE_URL = os.environ.get("INTERNAL_SERVICE_URL", "").rstrip("/")
GCP_PROJECT = os.environ.get("GCP_PROJECT", "")


def fetch_identity_token(audience: str) -> str:
    """Mint an ID token whose audience is the internal Cloud Run URL."""
    auth_req = google.auth.transport.requests.Request()
    return google.oauth2.id_token.fetch_id_token(auth_req, audience)


@app.get("/health")
def health():
    return "ok", 200


@app.get("/api/orders")
def get_orders():
    if not INTERNAL_SERVICE_URL:
        return jsonify({"error": "INTERNAL_SERVICE_URL is not set"}), 500

    try:
        token = fetch_identity_token(INTERNAL_SERVICE_URL)
        resp = requests.get(
            f"{INTERNAL_SERVICE_URL}/internal/orders",
            headers={"Authorization": f"Bearer {token}"},
            timeout=10,
        )
    except Exception as exc:  # noqa: BLE001 — surface errors clearly in a PoC
        return jsonify(
            {
                "error": "failed to call internal service",
                "detail": str(exc),
                "hint": "Check run.invoker IAM and INTERNAL_SERVICE_URL audience",
            }
        ), 502

    if resp.status_code == 403:
        return jsonify(
            {
                "error": "internal service returned 403",
                "hint": "Public SA is missing roles/run.invoker on the internal service",
                "body": resp.text,
            }
        ), 403

    if not resp.ok:
        return jsonify(
            {
                "error": "internal service error",
                "status": resp.status_code,
                "body": resp.text,
            }
        ), 502

    data = resp.json()
    return jsonify(
        {
            "source": "public-api",
            "project": GCP_PROJECT,
            "internal": data,
        }
    )


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8080"))
    app.run(host="0.0.0.0", port=port)
