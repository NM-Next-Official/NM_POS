-- Run manually in pgAdmin to enable database-backed account profile photos.
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS profile_image_data BYTEA;
