# NM POS Mail & OTP API

This service delivers OTP verification emails for user signups and password resets in the NM POS application.

---

## Why didn't the email arrive in the inbox?

The error in the terminal:
```
⚠️ Resend API responded with error: {
  message: 'API key is invalid',
  name: 'validation_error',
  statusCode: 401
}
```
**Reason**: The value `c6fe0962-4d0e-4ebc-8651-2a0d1ac0e845` in `.env` is a UUID, not a Resend API key. A valid Resend API key **always begins with `re_`** (e.g. `re_123456789_abcdef`).

---

## How to Fix It (Choose Option 1 or Option 2)

### Option 1 (Recommended): Gmail SMTP with an App Password
This is the easiest and most reliable method to deliver emails directly to **any user's Gmail inbox** (`tpwm420@gmail.com`, customers, etc.) without requiring a custom domain:

1. Go to your Google Account Security:
   👉 **https://myaccount.google.com/apppasswords**
   *(Ensure 2-Step Verification is enabled on your Google account if not already).*
2. Enter an app name: **NM POS** and click **Create**.
3. Google will show a **16-character password** (e.g., `abcd efgh ijkl mnop`).
4. In `backend/.env`, set:
   ```env
   GMAIL_USER_EMAIL=nmnext.official@gmail.com
   GMAIL_APP_PASSWORD=abcd efgh ijkl mnop
   ```
5. Test delivery immediately in your terminal:
   ```bash
   npm run test:email tpwm420@gmail.com
   ```
6. Start the server:
   ```bash
   npm start
   ```

---

### Option 2: Resend API Key
If you prefer using Resend:
1. Open your Resend dashboard (you already have this tab open):
   👉 **https://resend.com/api-keys**
2. Click **Create API Key**.
3. Copy the key that begins with **`re_`**.
4. In `backend/.env`, set:
   ```env
   RESEND_API_KEY=re_your_copied_api_key_here
   ```
5. *Note regarding Resend Free Tier*:
   If you do not have a verified domain, Resend with `onboarding@resend.dev` only permits sending emails to the email address registered with that Resend account. To send to arbitrary users like `tpwm420@gmail.com`, verify your domain in Resend or use **Option 1 (Gmail App Password)**.

---

## Health Check & Verification

Once configured, verify server status in your browser:
```
http://localhost:8080/health
```
