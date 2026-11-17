import path from 'node:path';
import { fileURLToPath } from 'node:url';
import dotenv from 'dotenv';
import express from 'express';
import helmet from 'helmet';
import { rateLimit } from 'express-rate-limit';
import nodemailer from 'nodemailer';
import { google } from 'googleapis';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Load environment variables from backend/.env and project root .env
dotenv.config({ path: path.resolve(__dirname, '../.env') });
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const app = express();
app.disable('x-powered-by');
app.use(helmet());
app.use(express.json({ limit: '10kb' }));

// ─── Configuration ───
const gmailUser = (process.env.GMAIL_USER_EMAIL || process.env.SMTP_USER || '').trim().toLowerCase();
const gmailPass = (process.env.GMAIL_APP_PASSWORD || process.env.SMTP_PASS || '').trim().replace(/\s+/g, '');

const resendApiKey = (process.env.RESEND_API_KEY || '').trim();
const resendFrom = (process.env.RESEND_FROM || 'NM POS <onboarding@resend.dev>').trim();
const resendReplyTo = (process.env.RESEND_REPLY_TO || gmailUser || 'nmnext.official@gmail.com').trim();

const googleClientId = (process.env.GOOGLE_OAUTH_CLIENT_ID || '').trim();
const googleClientSecret = (process.env.GOOGLE_OAUTH_CLIENT_SECRET || '').trim();
const googleRefreshToken = (process.env.GOOGLE_OAUTH_REFRESH_TOKEN || '').trim();

// ─── Initialize Transports ───

// 1. Gmail SMTP Transporter
let smtpTransporter = null;
if (gmailUser && gmailPass) {
  smtpTransporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: gmailUser,
      pass: gmailPass,
    },
  });
}

// 2. Google OAuth2 Client
let gmailOAuthClient = null;
if (gmailUser && googleClientId && googleClientSecret && googleRefreshToken) {
  try {
    const oauth = new google.auth.OAuth2(googleClientId, googleClientSecret);
    oauth.setCredentials({ refresh_token: googleRefreshToken });
    gmailOAuthClient = google.gmail({ version: 'v1', auth: oauth });
  } catch (err) {
    console.warn('⚠️ Google OAuth initialization failed:', err.message);
  }
}

// Check Resend Key format
const isResendKeyValid = resendApiKey.startsWith('re_');
if (resendApiKey && !isResendKeyValid) {
  console.warn('\n⚠️ [CONFIG WARNING] RESEND_API_KEY in .env does not look like a valid key!');
  console.warn('   Resend API keys always begin with "re_".');
  console.warn('   To get your API key: Open https://resend.com/api-keys and click "Create API Key".\n');
}

function getActiveProvider() {
  if (smtpTransporter) return 'gmail_smtp';
  if (resendApiKey && isResendKeyValid) return 'resend';
  if (gmailOAuthClient) return 'gmail_oauth';
  return 'none_configured';
}

const activeProvider = getActiveProvider();
console.log(`✉️ NM POS Mail Service active provider: [${activeProvider}]`);
if (activeProvider === 'gmail_smtp') {
  console.log(`   → Sending via Gmail SMTP as: ${gmailUser}`);
} else if (activeProvider === 'resend') {
  console.log(`   → Sending via Resend API (from: ${resendFrom})`);
} else {
  console.log('\n⚠️ No active email provider configured yet!');
  console.log('   To send real emails to ANY inbox (e.g. tpwm420@gmail.com):');
  console.log('   Option A (Recommended): Add GMAIL_APP_PASSWORD to backend/.env');
  console.log('     1. Go to https://myaccount.google.com/apppasswords');
  console.log('     2. Generate a 16-character App Password for "NM POS"');
  console.log('     3. Set GMAIL_USER_EMAIL=your_email@gmail.com and GMAIL_APP_PASSWORD=xxxx xxxx xxxx xxxx in backend/.env');
  console.log('   Option B: Add a valid RESEND_API_KEY (starts with re_) to backend/.env\n');
}

app.get('/health', (_req, res) => {
  res.json({
    status: 'ok',
    provider: getActiveProvider(),
    gmailSmtpConfigured: Boolean(smtpTransporter),
    resendConfigured: Boolean(resendApiKey && isResendKeyValid),
    gmailOAuthConfigured: Boolean(gmailOAuthClient),
    gmailUser: gmailUser || null,
  });
});

app.post(
  '/v1/email/otp',
  rateLimit({ windowMs: 15 * 60 * 1000, limit: 30, standardHeaders: 'draft-8', legacyHeaders: false }),
  async (req, res) => {
    const email = typeof req.body?.email === 'string' ? req.body.email.trim().toLowerCase() : '';
    const code = typeof req.body?.code === 'string' ? req.body.code.trim() : '';
    const purpose = typeof req.body?.purpose === 'string' ? req.body.purpose.trim() : 'verification';

    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || !/^\d{6}$/.test(code)) {
      return res.status(400).json({ error: 'A valid email address and six-digit code are required.' });
    }

    let actionLabel = 'Email Verification';
    let messageIntro = 'Thank you for signing up for NM POS. Use the verification code below to complete your registration:';

    if (purpose === 'passwordReset') {
      actionLabel = 'Password Reset';
      messageIntro = 'We received a request to reset your NM POS account password. Use the verification code below to proceed:';
    } else if (purpose === 'signup') {
      actionLabel = 'Account Sign Up';
      messageIntro = 'Welcome to NM POS! Use the verification code below to verify your email address and activate your account:';
    }

    const subject = `NM POS ${actionLabel} Code: ${code}`;
    const plain = `Your NM POS ${actionLabel} code is ${code}. It expires in 10 minutes. If you did not request this, please ignore this email.`;

    const html = `
      <div style="background-color:#F5F7FA;padding:36px 16px;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;color:#182535;">
        <div style="max-width:520px;margin:0 auto;background:#FFFFFF;border-radius:12px;padding:32px;box-shadow:0 4px 12px rgba(0,0,0,0.06);border:1px solid #E2E8F0;">
          <div style="text-align:center;margin-bottom:24px;">
            <h1 style="color:#182535;font-size:24px;font-weight:700;margin:0;letter-spacing:1px;">NM POS</h1>
            <p style="color:#64748B;font-size:14px;margin-top:4px;">Smart Point of Sale System</p>
          </div>
          <div style="border-top:1px solid #E2E8F0;padding-top:20px;">
            <h2 style="font-size:18px;font-weight:600;color:#1E293B;margin-top:0;">${actionLabel}</h2>
            <p style="font-size:14px;line-height:1.6;color:#475569;">${messageIntro}</p>
            <div style="background-color:#F1F5F9;border-radius:8px;padding:18px;text-align:center;margin:24px 0;">
              <span style="font-size:36px;font-weight:800;letter-spacing:8px;color:#0F172A;font-family:monospace;">${code}</span>
            </div>
            <p style="font-size:13px;color:#64748B;line-height:1.5;">This verification code is valid for <strong>10 minutes</strong>. Never share this code with anyone.</p>
            <p style="font-size:12px;color:#94A3B8;margin-top:24px;line-height:1.4;">If you did not make this request, you can safely ignore this email.</p>
          </div>
        </div>
      </div>
    `;

    // ─── Provider 1: Gmail SMTP (Nodemailer) ───
    if (smtpTransporter) {
      try {
        const info = await smtpTransporter.sendMail({
          from: `"NM POS" <${gmailUser}>`,
          to: email,
          subject,
          text: plain,
          html,
        });
        console.log(`✅ [Gmail SMTP] OTP email sent to ${email} (messageId: ${info.messageId})`);
        return res.status(202).json({ sent: true, provider: 'gmail_smtp', messageId: info.messageId });
      } catch (err) {
        console.error('❌ [Gmail SMTP Error]:', err.message);
        return res.status(502).json({
          error: `Gmail SMTP failed: ${err.message}. Check GMAIL_USER_EMAIL and GMAIL_APP_PASSWORD in backend/.env`,
        });
      }
    }

    // ─── Provider 2: Resend API ───
    if (resendApiKey) {
      if (!isResendKeyValid) {
        console.error('❌ [Resend Error]: RESEND_API_KEY is invalid (it must start with "re_").');
        console.log('\n============================================================');
        console.log('📧 [FALLBACK DEV OTP CODE]');
        console.log(`To:      ${email}`);
        console.log(`Purpose: ${purpose}`);
        console.log(`Code:    ${code}`);
        console.log('============================================================\n');
        return res.status(502).json({
          error: 'Resend API key in .env is invalid. It must start with "re_". Get your key from https://resend.com/api-keys or configure GMAIL_APP_PASSWORD.',
        });
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
            to: [email],
            reply_to: resendReplyTo,
            subject,
            html,
            text: plain,
          }),
        });

        const data = await response.json();
        if (response.ok) {
          console.log(`✅ [Resend] OTP email delivered to ${email} (id: ${data.id})`);
          return res.status(202).json({ sent: true, provider: 'resend', id: data.id });
        }

        console.error('❌ [Resend Error Response]:', data);
        let errorMsg = data?.message || 'Resend rejected the request.';
        if (data?.statusCode === 403 && data?.message?.includes('testing emails')) {
          console.log('\n============================================================');
          console.log('📧 [NM POS OTP CODE - TEST MODE]');
          console.log(`To:      ${email}`);
          console.log(`Purpose: ${purpose} (${actionLabel})`);
          console.log(`Code:    ${code}`);
          console.log(`Expires: 10 minutes`);
          console.log(`Notice:  Resend test tier delivers to ${resendReplyTo}.`);
          console.log(`         For other addresses (${email}), code is logged here for testing.`);
          console.log('============================================================\n');
          return res.status(202).json({
            sent: true,
            provider: 'dev_console',
            code,
            note: 'Delivered to terminal console due to Resend test domain limitation.',
          });
        }
        return res.status(502).json({ error: errorMsg });
      } catch (err) {
        console.error('❌ [Resend Network Error]:', err.message);
        return res.status(502).json({ error: `Resend network error: ${err.message}` });
      }
    }

    // ─── Provider 3: Google Gmail API (OAuth2) ───
    if (gmailOAuthClient && gmailUser) {
      try {
        const boundary = `nmpos_${Date.now().toString(36)}`;
        const mime = [
          `From: NM POS <${gmailUser}>`,
          `To: ${email}`,
          `Subject: ${subject}`,
          'MIME-Version: 1.0',
          `Content-Type: multipart/alternative; boundary="${boundary}"`,
          '',
          `--${boundary}`,
          'Content-Type: text/plain; charset="UTF-8"',
          'Content-Transfer-Encoding: base64',
          '',
          Buffer.from(plain, 'utf8').toString('base64'),
          `--${boundary}`,
          'Content-Type: text/html; charset="UTF-8"',
          'Content-Transfer-Encoding: base64',
          '',
          Buffer.from(html, 'utf8').toString('base64'),
          `--${boundary}--`,
        ].join('\r\n');

        await gmailOAuthClient.users.messages.send({
          userId: 'me',
          requestBody: { raw: Buffer.from(mime, 'utf8').toString('base64url') },
        });

        console.log(`✅ [Gmail OAuth] OTP email sent to ${email}`);
        return res.status(202).json({ sent: true, provider: 'gmail_oauth' });
      } catch (err) {
        console.error('❌ [Gmail OAuth Error]:', err.message);
        return res.status(502).json({ error: `Gmail OAuth failed: ${err.message}` });
      }
    }

    // ─── No Provider Configured ───
    console.log('\n============================================================');
    console.log('📧 [NM POS DEV OTP EMAIL (NO EMAIL PROVIDER CONFIGURED)]');
    console.log(`To:      ${email}`);
    console.log(`Purpose: ${purpose} (${actionLabel})`);
    console.log(`Code:    ${code}`);
    console.log('Valid:   10 minutes');
    console.log('Note:    Set GMAIL_APP_PASSWORD in backend/.env to send real emails to inboxes.');
    console.log('============================================================\n');

    return res.status(202).json({
      sent: true,
      provider: 'dev_console',
      code,
      note: 'OTP was logged to backend console for local development',
    });
  },
);

const port = Number(process.env.PORT || 8080);
app.listen(port, '0.0.0.0', () => {
  console.log(`🚀 NM POS Mail API listening on port ${port} (0.0.0.0)`);
  console.log(`   Health check: http://localhost:${port}/health`);
});
