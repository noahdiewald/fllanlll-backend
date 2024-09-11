set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.write_segment(sj json)
 RETURNS json
 LANGUAGE plpgsql
AS $function$DECLARE
    segid uuid := (sj ->> 'id');
    seg_text text := (sj ->> 'segment_text');
    seg_note text := (sj ->> 'note');
    seg_trans json := (sj -> 'translations');
    tr json;
    traid uuid;
    tra_text text;
    newseg json;
BEGIN
    IF segid = uuid_nil () THEN
        INSERT INTO segments (segment_text, note)
            VALUES (seg_text, seg_note)
        RETURNING
            id INTO segid;
    ELSIF segid IS NOT NULL THEN
        UPDATE
            segments
        SET
            segment_text = seg_text,
            note = seg_note
        WHERE
            id = segid;
    ELSE
        RAISE EXCEPTION 'Invalid segments id %', segid;
    END IF;
    DELETE FROM segment_translations
    WHERE segment_id = segid
        AND id::text NOT IN (
            SELECT
                (ja ->> 'id')
            FROM
                json_array_elements(seg_trans) ja);
    FOR tr IN
    SELECT
        json_array_elements(seg_trans)
        LOOP
            traid := (tr ->> 'id');
            tra_text := (tr ->> 'translation_text');
            IF traid = uuid_nil () THEN
                INSERT INTO segment_translations (segment_id, translation_text)
                    VALUES (segid, tra_text);
            ELSIF traid IS NOT NULL THEN
                UPDATE
                    segment_translations
                SET
                    translation_text = tra_text
                WHERE
                    id = traid;
            ELSE
                RAISE EXCEPTION 'Invalid segment_translations id %', traid;
            END IF;
        END LOOP;
    SELECT
        segment INTO newseg
    FROM
        json_segments s
    WHERE
        id = segid;
    RETURN json_object('{segment}', newseg);
END;$function$
;


