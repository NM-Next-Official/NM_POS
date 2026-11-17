import 'dotenv/config';
import http from 'node:http';
import { randomBytes } from 'node:crypto';
import { google } from 'googleapis';

const { GOOGLE_OAUTH_CLIENT_ID: clientId, GOOGLE_OAUTH_CLIENT_SECRET: clientSecret } = process.env;
if (!clientId || !clientSecret) {
  throw new Error('Set GOOGLE_OAUTH_CLIENT_ID and GOOGLE_OAUTH_CLIENT_SECRET in backend/.env first.');
}

const server = http.createServer();
server.listen(0, '127.0.0.1');
await new Promise((resolve, reject) => {
  server.once('listening', resolve);
  server.once('error', reject);
});

const { port } = server.address();
const redirectUri = `http://127.0.0.1:${port}/oauth2callback`;
const oauth = new google.auth.OAuth2(clientId, clientSecret, redirectUri);
const state = randomBytes(24).toString('hex');
const authUrl = oauth.generateAuthUrl({
  access_type: 'offline',
  prompt: 'consent',
  scope: ['https://www.googleapis.com/auth/gmail.send'],
  state,
});

console.log('Open this URL and authorize nmnext.official@gmail.com to send NM POS OTP email:');
console.log(authUrl);
console.log('Waiting for the one-time authorization response on this computer...');

const timeout = setTimeout(() => {
  console.error('Authorization timed out. Run this script again.');
  server.close();
  process.exitCode = 1;
}, 5 * 60 * 1000);
timeout.unref();

server.on('request', async (req, res) => {
  const requestUrl = new URL(req.url, redirectUri);
  if (requestUrl.pathname !== '/oauth2callback') {
    res.writeHead(404).end('Not found');
    return;
  }
  if (requestUrl.searchParams.get('state') !== state) {
    res.writeHead(400).end('Authorization state did not match. Close this page and retry.');
    return;
  }
  const code = requestUrl.searchParams.get('code');
  if (!code) {
    res.writeHead(400).end('Google did not return an authorization code.');
    return;
  }

  try {
    const { tokens } = await oauth.getToken(code);
    res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end('NM POS mail authorization complete. Return to the terminal.');
    if (!tokens.refresh_token) {
      throw new Error('No refresh token was returned. Revoke this app in Google Account security and run the setup again.');
    }
    console.log('\nCopy this refresh token into backend/.env as GOOGLE_OAUTH_REFRESH_TOKEN. Keep it private:');
    console.log(tokens.refresh_token);
    clearTimeout(timeout);
    server.close();
  } catch (error) {
    res.writeHead(500).end('Could not finish authorization. Check the terminal and try again.');
    console.error('Gmail authorization failed:', error.message);
    clearTimeout(timeout);
    server.close();
    process.exitCode = 1;
  }
});
