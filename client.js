'use strict';

const fs = require('fs');
const https = require('https');
const CONFIG_DIR = './config';

const host = 'localhost';
const port = 8000;

const options = {
  hostname: host,
  port,
  path: '/',
  method: 'GET',
  ca: [fs.readFileSync(`${CONFIG_DIR}/ca-crt.pem`)]
};

const req = https.request(options, res => {
  res.on('data', data => {
    process.stdout.write(data);
  });
});

req.end();
