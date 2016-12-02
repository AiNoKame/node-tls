'use strict';

const fs = require('fs');
const https = require('https');
const CERTS_DIR = __dirname + '/certs'
const PROVIDER_CERTS_DIR = `${CERTS_DIR}/provider`;
const CONSUMER_CERTS_DIR = `${CERTS_DIR}/consumer`;

const key1 = fs.readFileSync(`${PROVIDER_CERTS_DIR}/ripple-connect-server-key.pem`, 'utf8');
const cert1 = fs.readFileSync(`${PROVIDER_CERTS_DIR}/ripple-connect-server-crt.pem`, 'utf8');
const ca1 = fs.readFileSync(`${PROVIDER_CERTS_DIR}/provider-ca-crt.pem`, 'utf8');

const key2 = fs.readFileSync(`${CONSUMER_CERTS_DIR}/ripple-connect-server-key.pem`, 'utf8');
const cert2 = fs.readFileSync(`${CONSUMER_CERTS_DIR}/ripple-connect-server-crt.pem`, 'utf8');
const ca2 = fs.readFileSync(`${CONSUMER_CERTS_DIR}/consumer-ca-crt.pem`, 'utf8');

const host = 'localhost';
const port = 8002;

const options = {
  hostname: host,
  port,
  path: '/',
  method: 'GET',
  key: [key2],
  cert: [cert2],
  ca: [ca1, ca2] // can be in any order
};

const req = https.request(options, res => {
  res.on('data', data => {
    process.stdout.write(data);
  });
});

req.end();

req.on('error', error => {
  console.log('\n\n============================================================= ERROR');
  console.error(error);
});
