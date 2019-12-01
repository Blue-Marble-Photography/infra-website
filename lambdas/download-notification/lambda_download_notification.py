import boto3
import datetime
import json
from botocore.exceptions import ClientError


def lambda_handler(event, context):
  status = sendEmail(event['queryStringParameters']['filename'])

  return {
      'statusCode': 200,
      'body': json.dumps(status),
      'headers': {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': 'https://bluemarble.photography'
      }
  }


def sendEmail(filename):
  timestamp = datetime.datetime.now().isoformat()

  bodyText = (filename + ' was downloaded at ' + timestamp)

  bodyHtml = '<html><head></head><body><p>' + filename + ' was downloaded at ' + timestamp + \
      '</p><p><img src="https://bluemarble.photography/assets/images/photos/' + \
      filename.replace('.jpg', '-750.jpg') + '"></p></body></html>'

  client = boto3.client('ses', region_name='us-east-1')

  try:
    client.send_email(
        Destination={'ToAddresses': ['joseph@bluemarble.photography', ]},
        Message={'Body': {'Html': {'Charset': 'UTF-8', 'Data': bodyHtml},
                          'Text': {'Charset': 'UTF-8', 'Data': bodyText}},
                 'Subject': {'Charset': 'UTF-8', 'Data': 'Blue Marble Photography - Download Notification', }},
        Source='noreply@bluemarble.photography',
    )

    return {'status': 'sent'}
  except ClientError as e:
    return {'status': e.response['Error']['Message']}
  else:
    return {'status': 'unknown'}
