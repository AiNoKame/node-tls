'use strict';

const fs = require('fs');
const https = require('https');

const options = {
  key: fs.readFileSync('config/server-key.pem'),
  cert: fs.readFileSync('config/server-crt.pem'),
  ca: [fs.readFileSync('config/ca-crt.pem')],
};

const host = 'localhost';
const port = 8000;

const server = https.createServer(options, (req, res) => {
  console.log(
    `${new Date()} ${req.connection.remoteAddress} ${req.method} ${req.url}`);

  res.writeHead(200);
  res.end("hello world\n");
});

server.listen(port, host);

console.log(`Serving test server at ${host}:${port}`);

