import path from 'node:path';
import { fileURLToPath } from 'node:url';
import dotenv from 'dotenv';
import nodemailer from 'nodemailer';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.resolve(__dirname, '../.env') });
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const recipient = process.argv[2] || 'tpwm420@gmail.com';
const gmailUser = (process.env.GMAIL_USER_EMAIL || process.env.SMTP_USER || '').trim().toLowerCase();
const gmailPass = (process.env.GMAIL_APP_PASSWORD || process.env.SMTP_PASS || '').trim().replace(/\s+/g, '');
const resendApiKey = (process.env.RESEND_API_KEY || '').trim();
const resendFrom = (process.env.RESEND_FROM || 'NM POS <onboarding@resend.dev>').trim();

console.log('Testing NM POS email delivery...');
console.log(`Target Recipient: ${recipient}`);

if (gmailUser && gmailPass) {
  console.log(`Using Gmail SMTP with sender: ${gmailUser}`);
  const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: { user: gmailUser, pass: gmailPass },
  });

  try {
    const info = await transporter.sendMail({
      from: `"NM POS" <${gmailUser}>`,
      to: recipient,
      subject: 'NM POS Test Email',
      text: 'Hello from NM POS! Your email delivery configuration is working perfectly.',
      html: '<h3>Hello from NM POS!</h3><p>Your email delivery configuration is working perfectly.</p>',
    });
    console.log(`SUCCESS! Email sent to ${recipient} (Message ID: ${info.messageId})`);
  } catch (err) {
    console.error(`FAILED: ${err.message}`);
  }
} else if (resendApiKey) {
  console.log(`Using Resend API...`);
  if (!resendApiKey.startsWith('re_')) {
    console.error(`ERROR: RESEND_API_KEY does not start with "re_". Got: "${resendApiKey.slice(0, 8)}..."`);
    console.error('Please generate a valid API key at https://resend.com/api-keys');
    process.exit(1);
  }

  try {
    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${resendApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: resendFrom,
        to: [recipient],
        subject: 'NM POS Test Email',
        text: 'Hello from NM POS! Resend delivery is working.',
        html: '<h3>Hello from NM POS!</h3><p>Resend delivery is working.</p>',
      }),
    });
    const data = await response.json();
    if (response.ok) {
      console.log(`SUCCESS! Resend delivered to ${recipient} (ID: ${data.id})`);
    } else {
      console.error('FAILED: Resend returned error:', data);
      if (data?.statusCode === 403 && data?.message?.includes('testing emails')) {
        console.log('\n💡 [WHY DID THIS HAPPEN?]');
        console.log('   Resend in free/test mode only allows delivering to your own account email: nmnext.official@gmail.com');
        console.log(`   To send real emails to ${recipient} (or any user):`);
        console.log('   Option A: Add GMAIL_APP_PASSWORD to backend/.env (sends via Gmail SMTP with no domain needed)');
        console.log('   Option B: Verify your domain at https://resend.com/domains\n');
      }
    }
  } catch (err) {
    console.error(`FAILED: ${err.message}`);
  }
} else {
  console.error('No configuration found. Add GMAIL_APP_PASSWORD or RESEND_API_KEY to backend/.env');
}
