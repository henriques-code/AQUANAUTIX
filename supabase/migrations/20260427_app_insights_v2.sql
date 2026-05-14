-- AQUANAUTIX insights v2: scope by country/region/species.
-- Idempotent migration: safe to re-run.

create table if not exists public.app_insights_v2 (
  id bigserial primary key,
  insight_type text not null
    check (insight_type in ('legal_check', 'privacy', 'compliance', 'confidence')),
  country text not null,
  region text not null default 'ALL',
  species text not null default 'ALL',
  title text not null,
  detail text not null,
  source text,
  updated_label text,
  score int,
  ok boolean,
  active boolean not null default true,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create unique index if not exists app_insights_v2_scope_uniq
  on public.app_insights_v2 (insight_type, country, region, species);

alter table public.app_insights_v2 enable row level security;

drop policy if exists "app_insights_v2_public_read" on public.app_insights_v2;
create policy "app_insights_v2_public_read"
on public.app_insights_v2
for select
to anon, authenticated
using (active = true);

drop policy if exists "app_insights_v2_no_client_write" on public.app_insights_v2;
create policy "app_insights_v2_no_client_write"
on public.app_insights_v2
for all
to anon, authenticated
using (false)
with check (false);

insert into public.app_insights_v2
  (insight_type, country, region, species, title, detail, source, updated_label, score, ok, active, updated_at)
values
  ('legal_check', 'PT', 'ALL', 'ALL',
    'CHECK LEGAL PRE-MISSAO',
    'Sem alertas criticos para esta janela. Tamanho minimo e limites verificados.',
    'DGRM', 'Atualizado ha 2h', null, true, true, now()),
  ('privacy', 'PT', 'ALL', 'ALL',
    'PRIVACIDADE DIFERENCIAL ATIVA',
    'Partilha publica com zona fuzzificada + atraso temporal. Spot exato mantem-se privado.',
    'AQUANAUTIX Privacy Engine', 'Atualizado ha 2h', null, true, true, now()),
  ('compliance', 'PT', 'ALL', 'ALL',
    'COMPLIANCE & REPORTE UE',
    '3 capturas desta semana com dados completos para reporte eletronico.',
    'Reg. UE 2023/2842 + DGRM', 'Atualizado ha 2h', null, true, true, now()),
  ('confidence', 'PT', 'ALL', 'ALL',
    'ORACULO · CONFIANCA',
    'Baseado em mare, vento, historico local e feedback da tua atividade.',
    'AQUANAUTIX Oraculo', 'Atualizado ha 2h', 86, true, true, now()),

  ('legal_check', 'ES', 'ALL', 'ALL',
    'CHEQUEO LEGAL PRE-MISION',
    'Sin alertas criticos para esta ventana. Tallas minimas y limites verificados.',
    'MAPA', 'Actualizado hace 2h', null, true, true, now()),
  ('privacy', 'ES', 'ALL', 'ALL',
    'PRIVACIDAD DIFERENCIAL ACTIVA',
    'Comparticion publica con zona difusa + retraso temporal. El spot exacto permanece privado.',
    'AQUANAUTIX Privacy Engine', 'Actualizado hace 2h', null, true, true, now()),
  ('compliance', 'ES', 'ALL', 'ALL',
    'CUMPLIMIENTO & REPORTE UE',
    '3 capturas de esta semana listas para reporte electronico.',
    'Reg. UE 2023/2842 + MAPA', 'Actualizado hace 2h', null, true, true, now()),
  ('confidence', 'ES', 'ALL', 'ALL',
    'ORACULO · CONFIANZA',
    'Basado en marea, viento, historial local y feedback de actividad.',
    'AQUANAUTIX Oraculo', 'Actualizado hace 2h', 84, true, true, now()),

  ('legal_check', 'PT', 'SETUBAL', 'ROBALO',
    'CHECK LEGAL PRE-MISSAO',
    'Robalo com registo obrigatorio. Declaracao diaria ativa para esta especie.',
    'DGRM RecFishing', 'Atualizado ha 2h', null, true, true, now()),
  ('compliance', 'PT', 'SETUBAL', 'ROBALO',
    'COMPLIANCE & REPORTE UE',
    'Atencao: para robalo, valida declaracao no fim da jornada.',
    'DGRM + UE', 'Atualizado ha 2h', null, false, true, now()),

  ('legal_check', 'ES', 'GALICIA', 'LUBINA',
    'CHEQUEO LEGAL PRE-MISION',
    'Lubina con medidas de control reforzadas. Revisa cupos y talla minima local.',
    'MAPA + CCAA', 'Actualizado hace 2h', null, true, true, now()),
  ('compliance', 'ES', 'GALICIA', 'LUBINA',
    'CUMPLIMIENTO & REPORTE UE',
    'Recuerda registrar jornada y capturas/devoluciones en el mismo dia.',
    'MAPA RecFishing', 'Actualizado hace 2h', null, false, true, now())
on conflict (insight_type, country, region, species)
do update set
  title = excluded.title,
  detail = excluded.detail,
  source = excluded.source,
  updated_label = excluded.updated_label,
  score = excluded.score,
  ok = excluded.ok,
  active = excluded.active,
  updated_at = excluded.updated_at;

