DO $$
BEGIN
  IF NOT EXISTS (
    SELECT FROM pg_catalog.pg_roles WHERE rolname = 'dev'
  ) THEN
    CREATE ROLE dev LOGIN PASSWORD 'secret';
  END IF;
END
$$;
