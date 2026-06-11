-- AQUANAUTIX: dynamic insights for legal/privacy/compliance/confidence blocks.
-- Safe to run multiple times.

create table if not exists public.app_insights (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.app_insights enable row level security;

-- Public read-only access (content is non-sensitive product copy/metrics).
drop policy if exists "app_insights_public_read" on public.app_insights;
create policy "app_insights_public_read"
on public.app_insights
for select
to anon, authenticated
using (true);

-- Prevent client-side writes with anon/authenticated keys.
drop policy if exists "app_insights_no_client_write" on public.app_insights;
create policy "app_insights_no_client_write"
on public.app_insights
for all
to anon, authenticated
using (false)
with check (false);

insert into public.app_insights as ai (key, value, updated_at)
values
  (
    'legal_check',
    jsonb_build_object(
      'title', 'CHECK LEGAL PRE-MISSAO',
      'detail', 'Sem alertas criticos para esta janela. Tamanho minimo e limites verificados.',
      'source', 'DGRM + MAPA',
      'updated', 'Atualizado ha 2h'
    ),
    now()
  ),
  (
    'privacy',
    jsonb_build_object(
      'title', 'PRIVACIDADE DIFERENCIAL ATIVA',
      'detail', 'Partilha publica com zona fuzzificada + atraso temporal. Spot exato mantem-se privado.'
    ),
    now()
  ),
  (
    'compliance',
    jsonb_build_object(
      'title', 'COMPLIANCE & REPORTE UE',
      'detail', '3 capturas desta semana com dados completos para reporte eletronico.',
      'ok', true
    ),
    now()
  ),
  (
    'confidence',
    jsonb_build_object(
      'score', 86,
      'detail', 'Baseado em mare, vento, historico local e feedback da tua atividade.'
    ),
    now()
  )
on conflict (key) do update
set value = excluded.value,
    updated_at = excluded.updated_at;

