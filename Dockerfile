FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY load2kafka.py .

CMD ["python", "load2kafka.py"]
