FROM python:3.9-slim

WORKDIR /app

COPY ./src/* ./

RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 8080

ENV DATABASE_NAME=satellites DATABASE_USER=postgres DATABASE_PASSWORD=12345678 DATABASE_HOST=database-1.cz62omc64lqo.eu-central-1.rds.amazonaws.com DATABASE_PORT=5432 APP_PORT=8080 S3_BUCKET_NAME=satellites-api-data S3_SATELLITE_FILE_NAME=telemetry_data.json

CMD ["python", "main.py"]
