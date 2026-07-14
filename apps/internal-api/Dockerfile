# Lightweight Python image — Cloud Run runs whatever listens on $PORT
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

# Cloud Run sends traffic to this port
ENV PORT=8080
EXPOSE 8080

# gunicorn: production WSGI server (Flask's built-in server is for local only)
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "1", "--threads", "4", "app:app"]
