import json

def lambda_handler(event, context):
    response = event['Records'][0]['cf']['response']
    request = event['Records'][0]['cf']['request']

    newUrl = 'https://api.bluemarble.photography/v1/resize?path=' + request['uri'][1:]

    if int(response['status']) == 404:
        response['status'] = 302
        response['statusDescription'] = 'Found'
        response['headers']['location'] = [{'key': 'Location', 'value': newUrl}]

    return response
