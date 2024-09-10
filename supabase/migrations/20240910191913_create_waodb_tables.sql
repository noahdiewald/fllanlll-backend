CREATE TABLE IF NOT EXISTS document_log
(
    id uuid NOT NULL DEFAULT uuid_generate_v4(),
    dockey uuid NOT NULL DEFAULT uuid_generate_v4(),
    parent uuid NOT NULL DEFAULT uuid_nil(),
    create_time timestamp with time zone NOT NULL DEFAULT now(),
    doctype character varying NOT NULL,
    document jsonb NOT NULL,
    deleted boolean DEFAULT false,
    doctype_version integer NOT NULL,
    CONSTRAINT document_log_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS relation_log
(
    id uuid NOT NULL DEFAULT uuid_generate_v4(),
    relkey uuid NOT NULL DEFAULT uuid_generate_v4(),
    parent uuid NOT NULL DEFAULT uuid_nil(),
    create_time timestamp with time zone NOT NULL DEFAULT now(),
    reltype character varying NOT NULL,
    relation jsonb NOT NULL,
    arg1 uuid NOT NULL,
    arg2 uuid NOT NULL,
    deleted boolean DEFAULT false,
    reltype_version integer NOT NULL,
    CONSTRAINT relation_log_pkey PRIMARY KEY (id)
);

CREATE VIEW translations AS
       select * from document_log d where
              d.id not in (select parent from document_log) and
              not d.deleted and
              d.doctype = 'translation';

CREATE VIEW flat_translations
 AS
 SELECT t.dockey,
    t.document #>> '{source_text}'::text[] AS source_text,
    trad.value #>> '{traduccion}'::text[] AS traduccion
   FROM translations t
     LEFT JOIN LATERAL jsonb_array_elements(t.document #> '{traducciones}'::text[]) trad(value) ON t.dockey = t.dockey
  WHERE t.deleted = false;

CREATE VIEW document_head AS
       select * from document_log d where
              d.id not in (select parent from document_log) and
              not d.deleted;
              
CREATE OR REPLACE VIEW translations AS
       select * from document_head d where
              d.doctype = 'translation';

CREATE VIEW relation_head AS
       select * from relation_log d where
              d.id not in (select parent from relation_log) and
              not d.deleted;
              
CREATE OR REPLACE VIEW translations AS
        SELECT DISTINCT ON (dockey) id,
        dockey,
        parent,
        create_time,
        doctype,
        document,
        deleted,
        doctype_version,
        "substring"(dockey::text, 1, 8) AS sdockey
        FROM document_log
        WHERE doctype = 'translation'
        ORDER BY dockey, create_time DESC;
        
CREATE OR REPLACE FUNCTION set_updated_at_to_now()
    RETURNS trigger
    LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$BODY$;

CREATE TRIGGER update_segments_updated_at
    BEFORE UPDATE 
    ON segments
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at_to_now();

CREATE TABLE IF NOT EXISTS segment_translations
(
    id uuid NOT NULL DEFAULT uuid_generate_v4(),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    translation_text text NOT NULL,
    segment_id uuid NOT NULL,
    CONSTRAINT segment_translations_pkey PRIMARY KEY (id),
    CONSTRAINT segment_translations_ref_segment_id FOREIGN KEY (segment_id)
        REFERENCES segments (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);

CREATE INDEX IF NOT EXISTS segment_translations_segment_id_index
    ON segment_translations USING btree
    (segment_id ASC NULLS LAST);

CREATE TRIGGER update_segment_translations_updated_at
    BEFORE UPDATE 
    ON segment_translations
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at_to_now();
    
CREATE VIEW flat_segments
  AS
  SELECT s.id,
    s.segment_text,
    t.translation_text
    FROM segments s
    LEFT JOIN segment_translations t
    ON s.id = t.segment_id;

CREATE VIEW json_segments AS
SELECT sub.id, to_jsonb(sub.*) AS segment
FROM (
	SELECT seg.*, jsonb_agg(trans.*) AS translations
	FROM segments seg
	LEFT JOIN segment_translations trans ON trans.segment_id = seg.id
	GROUP BY seg.id
) sub;

CREATE TABLE IF NOT EXISTS notes
(
        id uuid NOT NULL DEFAULT uuid_generate_v4(),
        created_at timestamp with time zone NOT NULL DEFAULT now(),
        updated_at timestamp with time zone NOT NULL DEFAULT now(),
        note_text text NOT NULL,
        CONSTRAINT notes_pkey PRIMARY KEY (id)
);

CREATE TRIGGER update_notes_updated_at
    BEFORE UPDATE 
    ON notes
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at_to_now();

CREATE TABLE IF NOT EXISTS segments_notes (
    segment_id uuid REFERENCES segments (id) ON UPDATE CASCADE ON DELETE CASCADE,
    note_id uuid REFERENCES notes (id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT segments_notes_pkey PRIMARY KEY (segment_id, note_id)
);

CREATE OR REPLACE VIEW json_segments AS
SELECT
    id,
    to_jsonb (sub.*) AS segment
FROM (
    SELECT
        seg.id,
        seg.created_at,
        seg.updated_at,
        seg.segment_text,
        jsonb_agg(n.*) AS notes,
        jsonb_agg(trans.*) AS translations
    FROM
        segments_notes sn
        INNER JOIN segments seg ON seg.id = sn.segment_id
        INNER JOIN notes n ON n.id = sn.note_id
        LEFT JOIN segment_translations trans ON trans.segment_id = seg.id
    GROUP BY
        seg.id) sub;

CREATE OR REPLACE VIEW json_segments AS
SELECT
    id,
    to_jsonb (sub.*) AS segment
FROM (
    SELECT
        seg.*,
        jsonb_agg(trans.*) AS translations
    FROM
        segments seg
    LEFT JOIN segment_translations trans ON trans.segment_id = seg.id
    GROUP BY
        seg.id) sub;

DROP TABLE IF EXISTS segments_notes;

DROP TABLE IF EXISTS notes;

CREATE TABLE IF NOT EXISTS contributors (
    id uuid NOT NULL DEFAULT uuid_generate_v4 (),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    name text NOT NULL,
    note text NOT NULL DEFAULT ''::text,
    CONSTRAINT contributors_pkey PRIMARY KEY (id));

CREATE TRIGGER update_contributors_updated_at
    BEFORE UPDATE 
    ON contributors
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at_to_now();

CREATE TABLE IF NOT EXISTS audios (
    id uuid NOT NULL DEFAULT uuid_generate_v4 (),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    title text NOT NULL,
    note text NOT NULL DEFAULT ''::text,
    media_type text NOT NULL DEFAULT ''::text,
    collected_by text NOT NULL DEFAULT ''::text,
    original_filename text NOT NULL DEFAULT ''::text,
    translated_esp boolean NOT NULL DEFAULT FALSE,
    speakers text[] NOT NULL DEFAULT '{}' ::text[],
    translated_eng boolean NOT NULL DEFAULT FALSE,
    transcribed boolean NOT NULL DEFAULT FALSE,
    recorded_at timestamp with time zone NOT NULL DEFAULT now(),
    description text NOT NULL DEFAULT ''::text,
    location text NOT NULL DEFAULT ''::text,
    record_dated boolean NOT NULL DEFAULT FALSE,
    CONSTRAINT audios_pkey PRIMARY KEY (id));

CREATE TRIGGER update_audios_updated_at
    BEFORE UPDATE 
    ON audios
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at_to_now();

CREATE TABLE IF NOT EXISTS transcriptions (
    id uuid NOT NULL DEFAULT uuid_generate_v4 (),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    audio_id uuid NOT NULL,
    transcriber text NOT NULL DEFAULT ''::text,
    editors text[] COLLATE pg_catalog."default" NOT NULL DEFAULT '{}' ::text[],
    transcription_text text NOT NULL DEFAULT ''::text,
    complete boolean NOT NULL DEFAULT FALSE,
    final_draft boolean NOT NULL DEFAULT FALSE,
    note text NOT NULL DEFAULT ''::text,
    CONSTRAINT transcriptions_pkey PRIMARY KEY (id),
    CONSTRAINT transcriptions_ref_audio_id FOREIGN KEY (audio_id) REFERENCES audios (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE INDEX IF NOT EXISTS transcriptions_audio_id_index ON transcriptions USING btree (audio_id ASC NULLS LAST);

CREATE TRIGGER update_transcriptions_updated_at
    BEFORE UPDATE ON transcriptions
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at_to_now ();

CREATE VIEW flat_transcriptions AS
SELECT
    t.id,
    a.title,
    t.complete,
    t.final_draft
FROM
    transcriptions t
    INNER JOIN audios a ON a.id = t.audio_id;

CREATE TABLE IF NOT EXISTS audio_translations (
    id uuid NOT NULL DEFAULT uuid_generate_v4 (),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    translator text NOT NULL DEFAULT ''::text,
    language text
    NOT NULL DEFAULT ''::text,
    translation_text text NOT NULL,
    editors text[] NOT NULL DEFAULT '{}' ::text[],
    complete boolean NOT NULL DEFAULT FALSE,
    final_draft boolean NOT NULL DEFAULT FALSE,
    audio_id uuid NOT NULL,
    note text NOT NULL DEFAULT ''::text,
    CONSTRAINT audio_translations_pkey PRIMARY KEY (id),
    CONSTRAINT audio_translations_ref_audio_id FOREIGN KEY (audio_id) REFERENCES audios (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE INDEX IF NOT EXISTS audio_translations_audio_id_index ON audio_translations USING btree (audio_id ASC NULLS LAST);

CREATE TRIGGER update_audio_translations_updated_at
    BEFORE UPDATE ON audio_translations
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at_to_now ();

CREATE VIEW flat_audio_translations AS
SELECT
    t.id,
    a.title,
    t.language,
    t.complete,
    t.final_draft
FROM
    audio_translations t
    INNER JOIN audios a ON a.id = t.audio_id;

CREATE TABLE IF NOT EXISTS subtitles (
    id uuid NOT NULL DEFAULT uuid_generate_v4 (),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    audio_id uuid NOT NULL,
    language text
    NOT NULL DEFAULT ''::text,
    note text NOT NULL DEFAULT ''::text,
    complete boolean NOT NULL DEFAULT FALSE,
    final_draft boolean NOT NULL DEFAULT FALSE,
    format text NOT NULL DEFAULT ''::text,
    subtitle_text text NOT NULL DEFAULT ''::text,
    subtitler text NOT NULL DEFAULT ''::text,
    editors text[] NOT NULL DEFAULT '{}' ::text[],
    CONSTRAINT subtitles_pkey PRIMARY KEY (id),
    CONSTRAINT subtitles_ref_audio_id FOREIGN KEY (audio_id) REFERENCES audios (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE INDEX IF NOT EXISTS subtitles_audio_id_index ON subtitles USING btree (audio_id ASC NULLS LAST);

CREATE TRIGGER update_subtitles_updated_at
    BEFORE UPDATE ON subtitles
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at_to_now ();

CREATE VIEW flat_subtitles AS
SELECT
    t.id,
    a.title,
    t.language,
    t.complete,
    t.final_draft
FROM
    subtitles t
    INNER JOIN audios a ON a.id = t.audio_id;

CREATE OR REPLACE VIEW json_audios AS
SELECT
    id,
    to_jsonb (sub.*) AS audio
FROM (
    SELECT
        a.*,
        COALESCE(jsonb_agg(tc.*) FILTER (WHERE tc.id IS NOT NULL), '[]') AS transcriptions,
        COALESCE(jsonb_agg(tl.*) FILTER (WHERE tl.id IS NOT NULL), '[]') AS translations,
        COALESCE(jsonb_agg(s.*) FILTER (WHERE s.id IS NOT NULL), '[]') AS subtitles
    FROM
        audios a
    LEFT JOIN transcriptions tc ON tc.audio_id = a.id
    LEFT JOIN audio_translations tl ON tl.audio_id = a.id
    LEFT JOIN subtitles s ON s.audio_id = a.id
GROUP BY
    a.id) sub;

CREATE TABLE IF NOT EXISTS protocols (
    id uuid NOT NULL DEFAULT uuid_generate_v4 (),
    name text NOT NULL,
    description text NOT NULL,
    directions text NOT NULL,
    note text NOT NULL DEFAULT ''::text,
    CONSTRAINT protocols_pkey PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS questions (
    id uuid NOT NULL DEFAULT uuid_generate_v4 (),
    protocol_id uuid NOT NULL,
    group_name text NOT NULL,
    q_field text NOT NULL,
    q_kind text NOT NULL,
    q_options text[] NOT NULL DEFAULT '{}' ::text[],
    q_display text NOT NULL,
    CONSTRAINT questions_pkey PRIMARY KEY (id),
    CONSTRAINT questions_ref_protocol_id FOREIGN KEY (protocol_id) REFERENCES protocols (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE INDEX IF NOT EXISTS questions_protocol_id_index ON questions USING btree (protocol_id ASC NULLS LAST);

CREATE TABLE IF NOT EXISTS answers (
    id uuid NOT NULL DEFAULT uuid_generate_v4 (),
    question_id uuid NOT NULL,
    answer text NOT NULL,
    respondent text NOT NULL,
    CONSTRAINT answers_pkey PRIMARY KEY (id),
    CONSTRAINT answers_ref_question_id FOREIGN KEY (question_id) REFERENCES questions (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE INDEX IF NOT EXISTS answers_question_id_index ON answers USING btree (question_id ASC NULLS LAST);

CREATE OR REPLACE VIEW json_segments AS
SELECT
    id,
    to_jsonb (sub.*) AS segment
FROM (
    SELECT
        seg.*,
        COALESCE(jsonb_agg(trans.*) FILTER (WHERE trans.id IS NOT NULL), '[]') AS translations
    FROM
        segments seg
    LEFT JOIN segment_translations trans ON trans.segment_id = seg.id
GROUP BY
    seg.id) sub;


ALTER TABLE segment_translations
    DROP CONSTRAINT segment_translations_ref_segment_id,
    ADD CONSTRAINT segment_translations_ref_segment_id FOREIGN KEY (segment_id) REFERENCES segments (id) ON DELETE CASCADE;

CREATE TABLE IF NOT EXISTS judgments (
    id uuid NOT NULL DEFAULT uuid_generate_v4 (),
    document jsonb NOT NULL,
    note text NOT NULL DEFAULT '',
    CONSTRAINT judgements_pkey PRIMARY KEY (id)
);
