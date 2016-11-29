'use strict';

const fs = require('fs');
const https = require('https');
const CERTS_DIR = './certs'
const PROVIDER_CERTS_DIR = `${CERTS_DIR}/provider`;
const CONSUMER_CERTS_DIR = `${CERTS_DIR}/consumer`;

const ledger0Key1 = fs.readFileSync(`${PROVIDER_CERTS_DIR}/ledger0-server-key.pem`);
const ledger0Cert1 = fs.readFileSync(`${PROVIDER_CERTS_DIR}/ledger0-server-crt.pem`);
const key1 = fs.readFileSync(`${PROVIDER_CERTS_DIR}/ripple-connect-server-key.pem`);
const cert1 = fs.readFileSync(`${PROVIDER_CERTS_DIR}/ripple-connect-server-crt.pem`);
const ca1 = fs.readFileSync(`${PROVIDER_CERTS_DIR}/provider-ca-crt.pem`);

const ledger0Key2 = fs.readFileSync(`${CONSUMER_CERTS_DIR}/ledger0-server-key.pem`);
const ledger0Cert2 = fs.readFileSync(`${CONSUMER_CERTS_DIR}/ledger0-server-crt.pem`);
const key2 = fs.readFileSync(`${CONSUMER_CERTS_DIR}/ripple-connect-server-key.pem`);
const cert2 = fs.readFileSync(`${CONSUMER_CERTS_DIR}/ripple-connect-server-crt.pem`);
const ca2 = fs.readFileSync(`${CONSUMER_CERTS_DIR}/consumer-ca-crt.pem`);

const options = {
  key: ledger0Key1,
  cert: ledger0Cert1,
  ca: [ca1],
  requestCert: true,
  rejectUnauthorized: true
};

const host = "0.0.0.0";
const port = 8002;

const server = https.createServer(options, (req, res) => {
  console.log(
    `${new Date()} ${req.connection.remoteAddress} ${req.method} ${req.url}`);

  // res.writeHead(200);
  // res.end('hello world\n');
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

