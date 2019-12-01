import datetime
import json

import boto3


def lambda_handler(event, context):
  filename = event['queryStringParameters']['filename']

  result = send_ses_email(filename)

  return {
      'statusCode': 200,
      'body': json.dumps(result),
      'headers': {'Content-Type': 'application/json'}
  }


def send_ses_email(filename):
  ses = boto3.client('ses')

  timestamp = datetime.datetime.now().isoformat()

  body_text = filename + ' was downloaded at ' + timestamp

  mini_filename = filename.replace('.jpg', '-750.jpg')

  body_html = '<html><head></head><body><p>' + filename + ' was downloaded at ' + timestamp + '</p>' + \
              '<p><img src="https://images.bluemarble.photography/' + mini_filename + '"></p>' + \
              '</body></html>'

  try:
    ses.send_email(
        Destination={'ToAddresses': ['joseph@bluemarble.photography', ]},
        Message={'Body': {'Html': {'Charset': 'UTF-8', 'Data': body_html},
                          'Text': {'Charset': 'UTF-8', 'Data': body_text}},
                 'Subject': {'Charset': 'UTF-8', 'Data': 'Blue Marble Photography - Download Notification', }},
        Source='noreply@bluemarble.photography',
    )

    return {'status': 'sent'}
  except ses.exceptions.ClientError as e:
    return {'status': e.response['Error']['Message']}
  else:
    return {'status': 'unknown'}
