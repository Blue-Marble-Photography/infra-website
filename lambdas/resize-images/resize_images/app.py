import logging
import os
from io import BytesIO

import boto3
from PIL import Image

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    image = event['queryStringParameters']['path']
    file, extension = image.split('.')
    original_filename, image_size = file.rsplit('-', 1)
    original_filename += '.jpg'

    logger.info(f'Image: {image}')
    logger.info(f'Original Filename: {original_filename}')

    allowed_sizes = ['2880', '2800', '1600', '1440', '1100', '750', '400']
    allowed_extensions = ['webp', 'jpg']

    if image_size not in allowed_sizes or extension not in allowed_extensions:
        return {
            'statusCode': 400,
            'body': 'Invalid size or extension requested'
        }

    resize_image(image_size, original_filename, extension, image)
    url = create_url(image)

    logger.info(f'Redirect URL: {url}')

    return {
        'statusCode': 301,
        'headers': {
            'location': url
        },
        'body': ''
    }


def resize_image(image_size, original_filename, image_format, requested_filename):
    s3 = boto3.resource('s3')
    original_file = download_s3(original_filename, s3)

    img = Image.open(BytesIO(original_file))
    img = img.copy()
    img.thumbnail((int(image_size), int(image_size)), resample=Image.Resampling.LANCZOS)
    buffer = BytesIO()

    if image_format == 'jpg':
        img.save(buffer, format='JPEG', progressive=True, optimize=True, quality=75)
    elif image_format == 'webp':
        img.save(buffer, format='WEBP', quality=75, method=6)

    buffer.seek(0)

    upload_s3(buffer, image_format, requested_filename, original_filename, s3)


def download_s3(original_image, s3):
    s3_object = s3.Object(
        bucket_name=os.environ["IMAGES_BUCKET"],
        key='originals/' + original_image
    )

    logger.info(f'S3 Get: {s3_object}')

    obj_body = s3_object.get()['Body'].read()

    return obj_body


def upload_s3(buffer, image_format, resized_image, original_image, s3):
    s3_object = s3.Object(
        bucket_name=os.environ["IMAGES_BUCKET"],
        key=resized_image
    )

    if image_format == 'jpg':
        response = s3_object.put(Body=buffer, ContentType='image/jpeg', CacheControl='max-age=31536000',
                                 ContentDisposition='attachment;filename="' + original_image + '"')
    elif image_format == 'webp':
        response = s3_object.put(Body=buffer, ContentType='image/webp', CacheControl='max-age=31536000')

    logger.info(f'S3 Put: {response}')


def create_url(image):
    return f'https://images.bluemarble.photography/{image}'
