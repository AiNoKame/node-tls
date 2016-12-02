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

const host = "0.0.0.0";
const port = 8002;

const ledger0Key1 = fs.readFileSync(`${PROVIDER_CERTS_DIR}/ledger0-server-key.pem`, 'utf8');
const ledger0Cert1 = fs.readFileSync(`${PROVIDER_CERTS_DIR}/ledger0-server-crt.pem`, 'utf8');
const ledger0Key2 = fs.readFileSync(`${CONSUMER_CERTS_DIR}/ledger0-server-key.pem`, 'utf8');
const ledger0Cert2 = fs.readFileSync(`${CONSUMER_CERTS_DIR}/ledger0-server-crt.pem`, 'utf8');

const options = {
  // key: ledger0Key2,
  // cert: ledger0Cert2,
  // ca: [ca2, ca1],
  key: ledger0Key1,
  cert: ledger0Cert1,
  ca: [ca2, ca1], // can be in any order
  requestCert: true,
  rejectUnauthorized: true
};

const server = https.createServer(options, (req, res) => {
  const clientCert = req.client.getPeerCertificate();
  console.log(
    `${new Date()} ${req.connection.remoteAddress} ${req.method} ${req.url}`);
  console.log(
    `Certificate info! ${JSON.stringify(clientCert.subject, true, 2)}`);

  if (req.client.authorized) {
      res.writeHead(200, {"Content-Type": "application/json"});
      res.end('{"status":"approved"}');
  } else {
      res.writeHead(401, {"Content-Type": "application/json"});
      res.end('{"status":"denied"}');
  }
});

server.listen(port, host);

console.log(`Serving test server at ${host}:${port}`);

