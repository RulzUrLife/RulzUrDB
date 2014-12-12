-- Function: clone_schema(text, text) cloned and adapted from:
-- https://gist.github.com/hielkehoeve/8818562

CREATE OR REPLACE FUNCTION clone_schema(source_schema text, dest_schema text)
  RETURNS void AS
$BODY$

DECLARE
  seq RECORD;
  table_ text;
  buffer text;
  name_ text;
  tablefrom_ text;
  columnfrom_ text;
  tableto_ text;
  columnto_ text;

  column_ text;
  default_ text;
  seq_id_start text;
BEGIN
  EXECUTE 'CREATE SCHEMA ' || dest_schema;

  -- TODO: Find a way to make this sequence's owner is the correct table.
  FOR seq IN
    SELECT * FROM information_schema.SEQUENCES WHERE sequence_schema = source_schema
  LOOP
    EXECUTE 'CREATE SEQUENCE ' || dest_schema || '.' || seq.sequence_name;
    EXECUTE 'ALTER SEQUENCE ' || dest_schema || '.' || seq.sequence_name || ' INCREMENT BY ' || seq.increment;
  END LOOP;

  FOR table_ IN
    SELECT table_name::text FROM information_schema.TABLES WHERE table_schema = source_schema
  LOOP
    buffer := dest_schema || '.' || table_;
    EXECUTE 'CREATE TABLE ' || buffer || ' (LIKE ' || source_schema || '.' || table_ || ' INCLUDING ALL)';
  END LOOP;

  FOR table_ IN
    SELECT table_name::text FROM information_schema.TABLES WHERE table_schema = source_schema
  LOOP
    buffer := dest_schema || '.' || table_;
    FOR name_, tablefrom_, columnfrom_, tableto_, columnto_ IN
      SELECT DISTINCT tc.constraint_name as name_, tc.table_name as tablefrom_, kcu.column_name as columnto_, ccu.table_name AS tableto_, ccu.column_name AS columnto_
      FROM information_schema.table_constraints AS tc JOIN information_schema.key_column_usage AS kcu ON tc.constraint_name = kcu.constraint_name
      JOIN information_schema.constraint_column_usage AS ccu ON ccu.constraint_name = tc.constraint_name
      WHERE constraint_type = 'FOREIGN KEY' AND tc.constraint_schema = source_schema AND kcu.constraint_schema = source_schema AND ccu.constraint_schema = source_schema AND tc.table_name=table_
    LOOP
      EXECUTE 'ALTER TABLE ' || buffer || ' ADD CONSTRAINT ' || name_ || ' FOREIGN KEY (' || columnfrom_ || ') REFERENCES ' || dest_schema || '.' || tableto_ || ' (' || columnto_ || ') DEFERRABLE INITIALLY DEFERRED';
    END LOOP;
   END LOOP;

  FOR table_ IN
    SELECT table_name::text FROM information_schema.TABLES WHERE table_schema = source_schema
  LOOP
    buffer := dest_schema || '.' || table_;
    FOR column_, default_ IN
      SELECT column_name::text, REPLACE(column_default::text, source_schema, dest_schema) FROM information_schema.COLUMNS WHERE table_schema = dest_schema AND table_name = table_ AND column_default LIKE 'nextval(%' || source_schema || '%::regclass)'
    LOOP
      EXECUTE 'ALTER TABLE ' || buffer || ' ALTER COLUMN ' || column_ || ' SET DEFAULT ' || default_;
    END LOOP;
  END LOOP;
END;

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
