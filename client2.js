'use strict';

require('ssl-root-cas')
.addFile(__dirname + `/certs/consumer/consumer-ca-crt.pem`)
.addFile(__dirname + `/certs/provider/provider-ca-crt.pem`);
const fs = require('fs');
const https = require('https');
const CERTS_DIR = './certs'
const PROVIDER_CERTS_DIR = `${CERTS_DIR}/provider`;
const CONSUMER_CERTS_DIR = `${CERTS_DIR}/consumer`;

const key1 = fs.readFileSync(`${PROVIDER_CERTS_DIR}/ripple-connect-server-key.pem`, 'utf8');
const cert1 = fs.readFileSync(`${PROVIDER_CERTS_DIR}/ripple-connect-server-crt.pem`, 'utf8');
const ca1 = fs.readFileSync(`${PROVIDER_CERTS_DIR}/provider-ca-crt.pem`, 'utf8');

const key2 = fs.readFileSync(`${CONSUMER_CERTS_DIR}/ripple-connect-server-key.pem`, 'utf8');
const cert2 = fs.readFileSync(`${CONSUMER_CERTS_DIR}/ripple-connect-server-crt.pem`, 'utf8');
const ca2 = fs.readFileSync(`${CONSUMER_CERTS_DIR}/consumer-ca-crt.pem`, 'utf8');

const cafull = fs.readFileSync(`${CERTS_DIR}/fullchain.pem`, 'utf8');

const host = 'localhost';
const port = 8002;

const options = {
  hostname: host,
  port,
  path: '/',
  method: 'GET',
  // key: [key1, key2],
  // cert: [cert1, cert2],
  // ca: [cafull]
  key: [key2],
  cert: [cert2],
  ca: [ca2] // include either this ca option or use ssl-root-cas
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
