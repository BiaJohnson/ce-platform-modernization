"""
Internal orders API — private tier.

In production this would sit behind IAM + internal ingress (no public internet).
Cloud Run injects PORT (usually 8080); we must listen on 0.0.0.0:$PORT.
"""

import os

from flask import Flask, jsonify

app = Flask(__name__)

# Fake "database" — enough for a workshop demo
ORDERS = [
    {"id": "ord-1001", "customer": "customer-a", "sku": "WIDGET-A", "qty": 3, "status": "shipped"},
    {"id": "ord-1002", "customer": "customer-b", "sku": "WIDGET-B", "qty": 1, "status": "processing"},
    {"id": "ord-1003", "customer": "customer-c", "sku": "WIDGET-A", "qty": 10, "status": "pending"},
]


@app.get("/health")
def health():
    return "ok", 200


@app.get("/internal/orders")
def list_orders():
    return jsonify({"source": "internal-api", "orders": ORDERS})


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8080"))
    app.run(host="0.0.0.0", port=port)
