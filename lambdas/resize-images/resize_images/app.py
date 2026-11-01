import logging
import os
from html import escape
from io import BytesIO

import boto3
from PIL import Image

logger = logging.getLogger()
logger.setLevel(logging.INFO)

EXIF_ARTIST = 0x013B
EXIF_COPYRIGHT = 0x8298
DEFAULT_ARTIST = 'Joseph Gruber'
DEFAULT_COPYRIGHT = '\u00a9 Joseph Gruber. All rights reserved.'
LICENSE_URL = 'https://bluemarble.photography/license/'

# Creator, rights, and the PLUS "Data Mining" field set to prohibit AI/ML training.
XMP_TEMPLATE = """<?xpacket begin="\ufeff" id="W5M0MpCehiHzreSzNTczkc9d"?>
<x:xmpmeta xmlns:x="adobe:ns:meta/">
 <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
  <rdf:Description rdf:about=""
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:xmpRights="http://ns.adobe.com/xap/1.0/rights/"
    xmlns:plus="http://ns.useplus.org/ldf/xmp/1.0/"
    xmpRights:Marked="True"
    xmpRights:WebStatement="{license}"
    plus:DataMining="http://ns.useplus.org/ldf/vocab/DMI-PROHIBITED-AIMLTRAINING">
   <dc:creator><rdf:Seq><rdf:li>{artist}</rdf:li></rdf:Seq></dc:creator>
   <dc:rights><rdf:Alt><rdf:li xml:lang="x-default">{copyright}</rdf:li></rdf:Alt></dc:rights>
  </rdf:Description>
 </rdf:RDF>
</x:xmpmeta>
<?xpacket end="w"?>"""


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
        return {'statusCode': 400, 'body': 'Invalid size or extension requested'}

    resize_image(image_size, original_filename, extension, image)
    url = create_url(image)

    logger.info(f'Redirect URL: {url}')

    return {'statusCode': 301, 'headers': {'location': url}, 'body': ''}


def resize_image(image_size, original_filename, image_format, requested_filename):
    s3 = boto3.resource('s3')
    original_file = download_s3(original_filename, s3)

    img = Image.open(BytesIO(original_file))
    exif, xmp = build_metadata(img)
    img = img.copy()
    img.thumbnail((int(image_size), int(image_size)), resample=Image.Resampling.LANCZOS)
    buffer = BytesIO()

    if image_format == 'jpg':
        img.save(buffer, format='JPEG', progressive=True, optimize=True, quality=75, exif=exif, xmp=xmp)
    elif image_format == 'webp':
        img.save(buffer, format='WEBP', quality=75, method=6, exif=exif, xmp=xmp)

    buffer.seek(0)

    upload_s3(buffer, image_format, requested_filename, original_filename, s3)


def exif_text(value: str | bytes | None) -> str | None:
    """Decode an EXIF text tag that may hold UTF-8 in an ASCII field.

    Args:
        value: The raw tag value from Pillow.

    Returns:
        The decoded text, or None when the tag is missing or empty.
    """
    if not value:
        return None
    if isinstance(value, bytes):
        return value.decode('utf-8', errors='replace').strip('\x00 ') or None
    try:
        # Pillow decodes ASCII tags as Latin-1; recover UTF-8 such as "\u00c2\u00a9" -> "\u00a9".
        return value.encode('latin-1').decode('utf-8').strip('\x00 ') or None
    except (UnicodeEncodeError, UnicodeDecodeError):
        return value.strip('\x00 ') or None


def build_metadata(original: Image.Image) -> tuple[bytes, bytes]:
    """Build copyright metadata for a resized copy.

    Only the original's Artist and Copyright tags are carried over. The rest of its EXIF
    (including GPS location) is deliberately left out.

    Args:
        original: The opened original image.

    Returns:
        EXIF bytes and an XMP packet for the resized image.
    """
    source = original.getexif()
    artist = exif_text(source.get(EXIF_ARTIST)) or DEFAULT_ARTIST
    copyright_notice = exif_text(source.get(EXIF_COPYRIGHT)) or DEFAULT_COPYRIGHT

    # Stored as UTF-8 bytes, like the originals; a str would be written as ASCII and lose the ©.
    exif = Image.Exif()
    exif[EXIF_ARTIST] = artist.encode('utf-8')
    exif[EXIF_COPYRIGHT] = copyright_notice.encode('utf-8')

    xmp = XMP_TEMPLATE.format(artist=escape(artist), copyright=escape(copyright_notice), license=LICENSE_URL)

    return exif.tobytes(), xmp.encode('utf-8')


def download_s3(original_image, s3):
    s3_object = s3.Object(bucket_name=os.environ['IMAGES_BUCKET'], key='originals/' + original_image)

    logger.info(f'S3 Get: {s3_object}')

    obj_body = s3_object.get()['Body'].read()

    return obj_body


def upload_s3(buffer, image_format, resized_image, original_image, s3):
    # Served from the root URL by the images distribution's origin_path (/generated).
    s3_object = s3.Object(bucket_name=os.environ['IMAGES_BUCKET'], key='generated/' + resized_image)

    if image_format == 'jpg':
        response = s3_object.put(
            Body=buffer,
            ContentType='image/jpeg',
            CacheControl='max-age=31536000',
            ContentDisposition='attachment;filename="' + original_image + '"',
        )
    elif image_format == 'webp':
        response = s3_object.put(Body=buffer, ContentType='image/webp', CacheControl='max-age=31536000')

    logger.info(f'S3 Put: {response}')


def create_url(image):
    return f'https://images.bluemarble.photography/{image}'
