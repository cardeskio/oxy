-- Make ticket-attachments bucket public so images can be viewed without auth
UPDATE storage.buckets
SET public = true
WHERE name = 'ticket-attachments';
