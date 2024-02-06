from os import environ as env

app_port = env.get('APP_PORT', 8080)

db_config = {
    'db_name': env.get('DATABASE_NAME', 'satellites'),
    'db_user': env.get('DATABASE_USER', 'postgres'),
    'db_passwd': env.get('DATABASE_PASSWORD'),
    'db_host': env.get('DATABASE_HOST'),
    'db_port': env.get('DATABASE_PORT', 5432),
    'db_satellites_table': env.get('DATABASE_TABLE', 'telemetry_data')
}

s3_bucket_name = env.get('S3_BUCKET_NAME', 'satellites-api-data')
s3_satellites_file = env.get('S3_SATELLITES_FILE_NAME', 'telemetry_data.json')
