from os import environ as env
import json, urllib.request

def lambda_handler(event, context):
    satellites_backend_url = env.get('APP_URL')
    satellites_data = urllib.request.urlopen(
        '{}/get_satellites'.format(satellites_backend_url)
    ).read().decode('utf-8')

    satellites_data = json.loads(satellites_data)
    satellites_output = ''

    for satellite in satellites_data['data']:
        satellites_output += '# {}:\n'.format(satellite['name'])
        satellites_output += '  Check-in on {}\n'.format(satellite['timestamp'])
        satellites_output += '  Location: {}° longitude, {}° latitude, {} km altitude\n'.format(
            satellite['location']['longitude'],
            satellite['location']['latitude'],
            satellite['location']['altitude']
        )
        satellites_output += 'Solar irradiance: {} W/m²\n'.format(satellite['solar_irradiance'])
        satellites_output += 'Temperature: {}°C\n'.format(satellite['temperature'])
        satellites_output += 'Pressure: {} hPa\n'.format(satellite['pressure'])
        satellites_output += 'Humidity: {}%\n\n'.format(satellite['humidity'])

    return {
        'statusCode': 200,
        'body': json.dumps(satellites_output, indent=4)
    }
