from config import *
from flask import Flask, request, jsonify
import psycopg2, boto3, json


web_app = Flask(__name__)


class DB_Communicator:
    def __init__(self):
        self.config = db_config
        self.connect()


    def connect(self):
        self.connection = psycopg2.connect(
            host = self.config['db_host'],
            port = self.config['db_port'],
            database = self.config['db_name'],
            user = self.config['db_user'],
            password = self.config['db_passwd']
        )

        runner = self.connection.cursor()
        runner.execute(
            '''
                CREATE TABLE IF NOT EXISTS {} (
                    id SERIAL PRIMARY KEY,
                    satellite_id VARCHAR(50),
                    timestamp TIMESTAMP,
                    longitude DECIMAL(9, 6),
                    latitude DECIMAL(8, 6),
                    altitude DECIMAL(10, 2),
                    temperature DECIMAL(5, 2),
                    pressure DECIMAL(7, 2),
                    humidity DECIMAL(5, 2),
                    solar_irradiance DECIMAL(8, 2)
                );
            '''.format(self.config['db_satellites_table'])
        )

        self.connection.commit()
        runner.close()

        return True


    def get_satellites_data(self):
        runner = self.connection.cursor()
        runner.execute(
            'SELECT * FROM {};'.format(self.config['db_satellites_table'])
        )

        satellites = runner.fetchall()
        runner.close()
        
        return satellites
    

    def insert_satellites_data(self, data):
        runner = self.connection.cursor()
        runner.execute(
            '''
                INSERT INTO {} (satellite_id, timestamp, longitude, latitude, altitude, temperature, pressure, humidity, solar_irradiance)
                VALUES ('{}', '{}', '{}', '{}', '{}', '{}', '{}', '{}', '{}')
            '''.format(self.config['db_satellites_table'], *data)
        )

        self.connection.commit()
        runner.close()

        return True



class S3_Communicator:
    def __init__(self):
        self.bucket_name = s3_bucket_name
        self.file_name = s3_satellites_file

        self.connect()
    

    def connect(self):
        self.connection = boto3.client('s3')


    def insert_satellites_data(self, data):
        existing_s3_data = self.connection.get_object(
            Bucket = self.bucket_name, Key = self.file_name
        )['Body'].read().decode('utf-8')

        existing_s3_data = json.loads(existing_s3_data)
        existing_s3_data += [data]
        updated_s3_data = json.dumps(existing_s3_data, indent=4)

        self.connection.put_object(
            Bucket = self.bucket_name, Key = self.file_name, Body = updated_s3_data
        )

        return True



class API_Communicator:
    def __init__(self):
        pass

    
    @staticmethod
    @web_app.route('/get_satellites')
    def get_satellites():
        satellites_data = []
        existing_db_data = db_communicator.get_satellites_data()

        for satellite in existing_db_data:
            satellites_data += [{
                'name': satellite[1],
                'timestamp': str(satellite[2]),
                'location': {
                    'longitude': str(satellite[3]),
                    'latitude': str(satellite[4]),
                    'altitude': str(satellite[5])
                },
                'temperature': str(satellite[6]),
                'pressure': str(satellite[7]),
                'humidity': str(satellite[8]),
                'solar_irradiance': str(satellite[9])
            }]

        return jsonify({
            'success': True,
            'data': satellites_data
        })


    @staticmethod
    @web_app.route('/add_satellite', methods=['POST'])
    def add_satellite():
        try:
            raw_data = request.json
            satellite_data = [
                raw_data['name'],
                raw_data['timestamp'],
                raw_data['location']['longitude'],
                raw_data['location']['latitude'],
                raw_data['location']['altitude'],
                raw_data['temperature'],
                raw_data['pressure'],
                raw_data['humidity'],
                raw_data['solar_irradiance']
            ]

            db_communicator.insert_satellites_data(satellite_data)
            s3_communicator.insert_satellites_data(raw_data)

        except:
            return jsonify({
                'success': False,
                'error': 'Invalid input data; Must match the example JSON format and each value should be a string.',
                'example': {
                    'name': 'SATELLITE-8589',
                    'timestamp': '2024-02-06 12:00:00',
                    'location': {
                        'longitude': '-75.123400',
                        'latitude': '42.567800',
                        'altitude': '500.41'
                    },
                    'temperature': '20.50',
                    'pressure': '1013.25',
                    'humidity': '45.60',
                    'solar_irradiance': '750.20'
                }
            })

        return jsonify({
            'success': True,
            'description': 'Successfully updated s3://{}/{} and the {} table in the database'.format(
                s3_bucket_name, s3_satellites_file, db_config['db_satellites_table']
            )
        })



if __name__ == '__main__':
    db_communicator = DB_Communicator()
    s3_communicator = S3_Communicator()
    api = API_Communicator()

    web_app.run(debug = True, host = '0.0.0.0', port = app_port)
