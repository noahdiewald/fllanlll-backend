create or replace view
  public.translations
  with (security_invoker=on)
  as
select distinct
  on (document_log.dockey) document_log.id,
  document_log.dockey,
  document_log.parent,
  document_log.create_time,
  document_log.doctype,
  document_log.document,
  document_log.deleted,
  document_log.doctype_version,
  "substring" (document_log.dockey::text, 1, 8) as sdockey
from
  document_log
where
  document_log.doctype::text = 'translation'::text
order by
  document_log.dockey,
  document_log.create_time desc;
  
create or replace view
  public.relation_head
  with (security_invoker=on)
  as
select
  d.id,
  d.relkey,
  d.parent,
  d.create_time,
  d.reltype,
  d.relation,
  d.arg1,
  d.arg2,
  d.deleted,
  d.reltype_version
from
  relation_log d
where
  not (
    d.id in (
      select
        relation_log.parent
      from
        relation_log
    )
  )
  and not d.deleted;

create or replace view
  public.json_segments
  with (security_invoker=on)
  as
select
  sub.id,
  to_jsonb(sub.*) as segment
from
  (
    select
      seg.id,
      seg.created_at,
      seg.updated_at,
      seg.segment_text,
      seg.note,
      coalesce(
        jsonb_agg(trans.*) filter (
          where
            trans.id is not null
        ),
        '[]'::jsonb
      ) as translations
    from
      segments seg
      left join segment_translations trans on trans.segment_id = seg.id
    group by
      seg.id
  ) sub;

create or replace view
  public.json_audios
  with (security_invoker=on)
  as
select
  sub.id,
  to_jsonb(sub.*) as audio
from
  (
    select
      a.id,
      a.created_at,
      a.updated_at,
      a.title,
      a.note,
      a.media_type,
      a.collected_by,
      a.original_filename,
      a.translated_esp,
      a.speakers,
      a.translated_eng,
      a.transcribed,
      a.recorded_at,
      a.description,
      a.location,
      a.record_dated,
      coalesce(
        jsonb_agg(tc.*) filter (
          where
            tc.id is not null
        ),
        '[]'::jsonb
      ) as transcriptions,
      coalesce(
        jsonb_agg(tl.*) filter (
          where
            tl.id is not null
        ),
        '[]'::jsonb
      ) as translations,
      coalesce(
        jsonb_agg(s.*) filter (
          where
            s.id is not null
        ),
        '[]'::jsonb
      ) as subtitles
    from
      audios a
      left join transcriptions tc on tc.audio_id = a.id
      left join audio_translations tl on tl.audio_id = a.id
      left join subtitles s on s.audio_id = a.id
    group by
      a.id
  ) sub;

create or replace view
  public.flat_translations
  with (security_invoker=on)
  as
select
  t.dockey,
  t.document #>> '{source_text}'::text[] as source_text,
  trad.value #>> '{traduccion}'::text[] as traduccion
from
  translations t
  left join lateral jsonb_array_elements(t.document #> '{traducciones}'::text[]) trad (value) on t.dockey = t.dockey
where
  t.deleted = false;

create or replace view
  public.flat_transcriptions
  with (security_invoker=on)
  as
select
  t.id,
  a.title,
  t.complete,
  t.final_draft
from
  transcriptions t
  join audios a on a.id = t.audio_id;

create or replace view
  public.flat_subtitles
  with (security_invoker=on)
  as
select
  t.id,
  a.title,
  t.language,
  t.complete,
  t.final_draft
from
  subtitles t
  join audios a on a.id = t.audio_id;

create or replace view
  public.flat_segments
  with (security_invoker=on)
  as
select
  s.id,
  s.segment_text,
  t.translation_text
from
  segments s
  left join segment_translations t on s.id = t.segment_id;
  
create or replace view
  public.flat_audio_translations
  with (security_invoker=on)
  as
select
  t.id,
  a.title,
  t.language,
  t.complete,
  t.final_draft
from
  audio_translations t
  join audios a on a.id = t.audio_id;

create or replace view
  public.document_head
  with (security_invoker=on)
  as
select
  d.id,
  d.dockey,
  d.parent,
  d.create_time,
  d.doctype,
  d.document,
  d.deleted,
  d.doctype_version
from
  document_log d
where
  not (
    d.id in (
      select
        document_log.parent
      from
        document_log
    )
  )
  and not d.deleted;
  
