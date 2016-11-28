'use strict';

const fs = require('fs');
const https = require('https');
const CONFIG_DIR = './certs/provider';

const options = {
  key: fs.readFileSync(`${CONFIG_DIR}/validator-server-key.pem`),
  cert: fs.readFileSync(`${CONFIG_DIR}/validator-server-crt.pem`),
  ca: [fs.readFileSync(`${CONFIG_DIR}/provider-ca-crt.pem`)],
  requestCert: true,
  rejectUnauthorized: true
};

const host = 'localhost';
const port = 8002;

const server = https.createServer(options, (req, res) => {
  console.log(
    `${new Date()} ${req.connection.remoteAddress} ${req.method} ${req.url}`);

  res.writeHead(200);
  res.end('hello world\n');
});

server.listen(port, host);

console.log(`Serving test server at ${host}:${port}`);

