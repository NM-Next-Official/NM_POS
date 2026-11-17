-- ═══════════════════════════════════════════════════════════════
-- NM POS Complete Database Setup Script
-- Run in pgAdmin 4 query tool connected to postgres/nm_pos database
-- ═══════════════════════════════════════════════════════════════

-- Step A: Create app role/user (if not exists)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'nm_pos_app') THEN
        CREATE ROLE nm_pos_app WITH LOGIN PASSWORD 'nmpos_dev_2026';
    END IF;
END
$$;

-- Step B: Grant database privileges
GRANT ALL PRIVILEGES ON DATABASE nm_pos TO nm_pos_app;
GRANT ALL ON SCHEMA public TO nm_pos_app;
ALTER SCHEMA public OWNER TO nm_pos_app;

-- Step C: Enable cryptographic extension for UUID generation
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Step D: Create tables

-- 1. Users Table
CREATE TABLE IF NOT EXISTS users (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email             TEXT UNIQUE,
    phone             VARCHAR(20) UNIQUE,
    first_name        VARCHAR(80) NOT NULL,
    last_name         VARCHAR(80) NOT NULL,
    password_hash     VARCHAR(255) NOT NULL,
    password_salt     VARCHAR(64) NOT NULL,
    role              VARCHAR(20) NOT NULL
                      CHECK (role IN ('admin', 'owner', 'basic', 'salesman')),
    business_name     VARCHAR(120),
    business_address  TEXT,
    outlet_ids        TEXT NOT NULL DEFAULT '',
    profile_image_data BYTEA,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Ensure profile_image_data exists if table was created previously without it
ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_image_data BYTEA;

CREATE INDEX IF NOT EXISTS idx_users_email ON users(LOWER(email));
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);

-- 2. Sessions Table
CREATE TABLE IF NOT EXISTS sessions (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    access_token      VARCHAR(255) UNIQUE NOT NULL,
    refresh_token     VARCHAR(255) UNIQUE NOT NULL,
    expires_at        TIMESTAMPTZ NOT NULL,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sessions_access_token ON sessions(access_token);
CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);

-- 3. OTP Codes Table
CREATE TABLE IF NOT EXISTS otp_codes (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    destination       VARCHAR(255) NOT NULL,
    channel           VARCHAR(10) NOT NULL CHECK (channel IN ('email', 'phone')),
    purpose           VARCHAR(30) NOT NULL CHECK (purpose IN (
                       'signup', 'login', 'passwordReset', 'phoneVerify'
                      )),
    code              VARCHAR(10) NOT NULL,
    expires_at        TIMESTAMPTZ NOT NULL,
    verified          BOOLEAN NOT NULL DEFAULT FALSE,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_otp_dest_purpose
    ON otp_codes(destination, purpose, created_at DESC);

-- Step E: Grant all table, sequence, and function permissions to app user
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO nm_pos_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO nm_pos_app;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO nm_pos_app;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO nm_pos_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO nm_pos_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO nm_pos_app;
