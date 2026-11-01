// Forwards mail received by SES for bluemarble.photography.
// Port of arithmetric/aws-lambda-ses-forwarder 4.2.0 to AWS SDK v3 (bundled in the Lambda Node.js runtime).

import { CopyObjectCommand, GetObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { SESClient, SendRawEmailCommand } from '@aws-sdk/client-ses';

// - fromEmail: verified address forwarded mail is sent from.
// - subjectPrefix: prepended to the Subject header.
// - emailBucket / emailKeyPrefix: where the SES receipt rule stores raw mail (prefix includes the trailing slash).
// - forwardMapping: lowercase address, `@domain`, or bare mailbox name → destination addresses.
export const defaultConfig = {
  fromEmail: 'noreply@bluemarble.photography',
  subjectPrefix: '',
  emailBucket: 'bluemarble.photography-email',
  emailKeyPrefix: 'incoming/',
  forwardMapping: {
    '@bluemarble.photography': ['joseph.gruber@gmail.com'],
  },
};

const s3Client = new S3Client({});
const sesClient = new SESClient({});

export function parseEvent(data) {
  const records = data.event?.Records;
  if (records?.length !== 1 || records[0].eventSource !== 'aws:ses' || records[0].eventVersion !== '1.0') {
    data.log({ level: 'error', message: 'parseEvent() received invalid SES message:', event: JSON.stringify(data.event) });
    throw new Error('Error: Received invalid SES message.');
  }

  data.email = records[0].ses.mail;
  data.recipients = records[0].ses.receipt.recipients;
  return data;
}

// Returns false when no recipient matches the forward mapping.
export function transformRecipients(data) {
  const mapping = data.config.forwardMapping;
  const has = (key) => Object.hasOwn(mapping, key);
  let newRecipients = [];
  data.originalRecipients = data.recipients;

  for (const origEmail of data.recipients) {
    const key = origEmail.toLowerCase();
    const pos = key.lastIndexOf('@');
    const domain = pos === -1 ? undefined : key.slice(pos);
    const user = pos === -1 ? key : key.slice(0, pos);
    const match = [key, domain, user].find((candidate) => candidate && has(candidate));
    if (match) {
      newRecipients = newRecipients.concat(mapping[match]);
      data.originalRecipient = origEmail;
    }
  }

  if (!newRecipients.length) {
    data.log({
      level: 'info',
      message: `Finishing process. No new recipients found for original destinations: ${data.originalRecipients.join(', ')}`,
    });
    return false;
  }

  data.recipients = newRecipients;
  return true;
}

export async function fetchMessage(data) {
  const { emailBucket: bucket, emailKeyPrefix: prefix } = data.config;
  const key = prefix + data.email.messageId;
  data.log({ level: 'info', message: `Fetching email at s3://${bucket}/${key}` });

  // Copy the object onto itself so this role owns a readable copy.
  try {
    await data.s3.send(
      new CopyObjectCommand({
        Bucket: bucket,
        CopySource: `${bucket}/${key}`,
        Key: key,
        ACL: 'private',
        ContentType: 'text/plain',
        StorageClass: 'STANDARD',
      }),
    );
  } catch (err) {
    data.log({ level: 'error', message: 'copyObject() returned error:', error: err, stack: err.stack });
    throw new Error('Error: Could not make readable copy of email.');
  }

  try {
    const result = await data.s3.send(new GetObjectCommand({ Bucket: bucket, Key: key }));
    data.emailData = await result.Body.transformToString();
  } catch (err) {
    data.log({ level: 'error', message: 'getObject() returned error:', error: err, stack: err.stack });
    throw new Error('Error: Failed to load message body from S3.');
  }
  return data;
}

export function processMessage(data) {
  let match = data.emailData.match(/^((?:.+\r?\n)*)(\r?\n(?:.*\s+)*)/m);
  let header = match?.[1] ? match[1] : data.emailData;
  const body = match?.[2] ? match[2] : '';

  // Add Reply-To with the original From address unless one exists.
  if (!/^Reply-To: /im.test(header)) {
    match = header.match(/^From: (.*(?:\r?\n\s+.*)*\r?\n)/m);
    const from = match?.[1] ? match[1] : '';
    if (from) {
      header = header + 'Reply-To: ' + from;
      data.log({ level: 'info', message: 'Added Reply-To address of: ' + from });
    } else {
      data.log({ level: 'info', message: 'Reply-To address not added because From address was not properly extracted.' });
    }
  }

  // SES only sends from verified addresses, so rewrite From to the configured sender.
  header = header.replace(/^From: (.*(?:\r?\n\s+.*)*)/gm, (_, from) => {
    if (data.config.fromEmail) {
      return `From: ${from.replace(/<(.*)>/, '').trim()} <${data.config.fromEmail}>`;
    }
    return `From: ${from.replace('<', 'at ').replace('>', '')} <${data.originalRecipient}>`;
  });

  if (data.config.subjectPrefix) {
    header = header.replace(/^Subject: (.*)/gm, (_, subject) => 'Subject: ' + data.config.subjectPrefix + subject);
  }

  if (data.config.toEmail) {
    header = header.replace(/^To: (.*)/gm, () => 'To: ' + data.config.toEmail);
  }

  header = header.replace(/^Return-Path: (.*)\r?\n/gm, '');
  header = header.replace(/^Sender: (.*)\r?\n/gm, '');
  header = header.replace(/^Message-ID: (.*)\r?\n/gim, '');
  // SES rejects duplicate DKIM-Signature headers, and the From rewrite invalidates them anyway.
  header = header.replace(/^DKIM-Signature: .*\r?\n(\s+.*\r?\n)*/gm, '');

  data.emailData = header + body;
  return data;
}

export async function sendMessage(data) {
  data.log({
    level: 'info',
    message:
      'sendMessage: Sending email via SES. ' +
      `Original recipients: ${data.originalRecipients.join(', ')}. ` +
      `Transformed recipients: ${data.recipients.join(', ')}.`,
  });

  try {
    const result = await data.ses.send(
      new SendRawEmailCommand({
        Destinations: data.recipients,
        Source: data.originalRecipient,
        RawMessage: { Data: Buffer.from(data.emailData) },
      }),
    );
    data.log({ level: 'info', message: 'sendRawEmail() successful.', result });
  } catch (err) {
    data.log({ level: 'error', message: 'sendRawEmail() returned error.', error: err, stack: err.stack });
    throw new Error('Error: Email sending failed.');
  }
  return data;
}

export const handler = async (event) => forward(event);

// `overrides` (config, log, s3, ses) replaces the defaults in local tests.
export async function forward(event, overrides = {}) {
  const data = {
    event,
    config: overrides.config ?? defaultConfig,
    log: overrides.log ?? console.log,
    s3: overrides.s3 ?? s3Client,
    ses: overrides.ses ?? sesClient,
  };

  try {
    parseEvent(data);
    if (!transformRecipients(data)) return;
    await fetchMessage(data);
    processMessage(data);
    await sendMessage(data);
  } catch (err) {
    data.log({ level: 'error', message: 'Step returned error: ' + err.message, error: err, stack: err.stack });
    throw new Error('Error: Step returned error.');
  }
  data.log({ level: 'info', message: 'Process finished successfully.' });
}
