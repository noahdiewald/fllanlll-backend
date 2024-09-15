alter table "public"."answers" enable row level security;

alter table "public"."audio_translations" enable row level security;

alter table "public"."audios" enable row level security;

alter table "public"."contributors" enable row level security;

alter table "public"."document_log" enable row level security;

alter table "public"."judgments" enable row level security;

alter table "public"."protocols" enable row level security;

alter table "public"."questions" enable row level security;

alter table "public"."relation_log" enable row level security;

alter table "public"."segment_translations" enable row level security;

alter table "public"."segments" enable row level security;

alter table "public"."subtitles" enable row level security;

alter table "public"."transcriptions" enable row level security;

create policy "answers_all"
on "public"."answers"
as permissive
for all
to public
using (true)
with check (true);


create policy "audio_translations_all"
on "public"."audio_translations"
as permissive
for all
to public
using (true)
with check (true);


create policy "audios_all"
on "public"."audios"
as permissive
for all
to public
using (true)
with check (true);


create policy "contributors_all"
on "public"."contributors"
as permissive
for all
to authenticated
using (true)
with check (true);


create policy "document_log_delete"
on "public"."document_log"
as permissive
for delete
to service_role
using (true);


create policy "document_log_insert"
on "public"."document_log"
as permissive
for insert
to service_role
with check (true);


create policy "document_log_select"
on "public"."document_log"
as permissive
for select
to authenticated
using (true);


create policy "document_log_update"
on "public"."document_log"
as permissive
for update
to service_role
using (true)
with check (true);


create policy "judgements_all"
on "public"."judgments"
as permissive
for all
to public
using (true)
with check (true);


create policy "protocols_all"
on "public"."protocols"
as permissive
for all
to public
using (true)
with check (true);


create policy "questions_all"
on "public"."questions"
as permissive
for all
to public
using (true)
with check (true);


create policy "relation_log_delete"
on "public"."relation_log"
as permissive
for delete
to service_role
using (true);


create policy "relation_log_insert"
on "public"."relation_log"
as permissive
for insert
to service_role
with check (true);


create policy "relation_log_select"
on "public"."relation_log"
as permissive
for select
to authenticated
using (true);


create policy "relation_log_update"
on "public"."relation_log"
as permissive
for update
to service_role
using (true)
with check (true);


create policy "segment_translations_all"
on "public"."segment_translations"
as permissive
for all
to authenticated
using (true)
with check (true);


create policy "segments_all"
on "public"."segments"
as permissive
for all
to authenticated
using (true)
with check (true);


create policy "subtitles_all"
on "public"."subtitles"
as permissive
for all
to public
using (true)
with check (true);


create policy "transcriptions_all"
on "public"."transcriptions"
as permissive
for all
to public
using (true)
with check (true);



