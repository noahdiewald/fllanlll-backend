CREATE TABLE IF NOT EXISTS segments
(
    id uuid NOT NULL DEFAULT uuid_generate_v4(),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    segment_text text NOT NULL,
    note text NOT NULL DEFAULT ''::text,
    CONSTRAINT segments_pkey PRIMARY KEY (id)
)
