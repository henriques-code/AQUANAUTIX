-- Corre este script no Supabase Dashboard > SQL Editor
-- Se retornar uma linha → bucket existe, não criar.
-- Se retornar vazio → criar manualmente em Storage > New Bucket.

SELECT id, name, public
FROM storage.buckets
WHERE id = 'catch-photos';
