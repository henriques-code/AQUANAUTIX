# Supabase Setup — AQUANAUTIX

## 1. Correr a migration catch_photos

No Supabase Dashboard → SQL Editor, cola e executa:
`supabase/migrations/20260512000000_catch_photos.sql`

## 2. Verificar bucket catch-photos

No Supabase Dashboard → SQL Editor, corre:
`supabase/scripts/check_bucket.sql`

**Retornou uma linha:** bucket já existe, não fazer nada.
**Retornou vazio:** ir a Storage → New Bucket:
- Name: `catch-photos`
- Public bucket: activar
- Clicar Save

## 3. Políticas do bucket (só se criaste o bucket agora)

Storage → catch-photos → Policies:

Política SELECT:
- Name: `catch_photos_public_read`
- Operation: SELECT | Roles: public
- USING: `bucket_id = 'catch-photos'`

Política INSERT:
- Name: `catch_photos_upload`
- Operation: INSERT | Roles: authenticated
- WITH CHECK: `bucket_id = 'catch-photos'`

## 4. Confirmar setup

SQL Editor:
SELECT COUNT(*) FROM catch_photos;
Retorna 0 sem erro = sucesso.
