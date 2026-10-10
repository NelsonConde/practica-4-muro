FROM python:3.14-slim
WORKDIR /app
ENV PORT=8080
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 app:app