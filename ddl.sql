--- User

BEGIN;

CREATE TABLE "user" (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    timezone VARCHAR(50) NOT NULL,
    created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE "journal" (
  id SERIAL PRIMARY KEY,
  meta_data JSON,
  created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE "ledgers" (
    entry_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id INTEGER NOT NULL,
    type INTEGER NOT NULL CHECK(type >= 0 AND type <= 2), -- 0 - Token, 1 - Fiat, 2 - Fee
    from_balance NUMERIC(18, 2) NOT NULL,
    to_balance NUMERIC(18, 2) NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    journal_id NOT NULL INT REFERENCES journal(id)
);

CREATE TABLE "exchange_rates" (
    id SERIAL PRIMARY KEY,
    journal_id NOT NULL INT REFERENCES journal(id),
    rate NUMERIC(18, 6) NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION set_modified_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.modified = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_modified_timestamp
    BEFORE UPDATE ON "user" 
FOR EACH ROW
EXECUTE PROCEDURE set_modified_timestamp();


CREATE OR REPLACE FUNCTION prevent_updates_and_deletions()
RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION 'This table is append only. Updates and deletions are not allowed.';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ledger_append_only
BEFORE UPDATE OR DELETE on "ledger"
FOR EACH ROW
EXECUTE PROCEDURE prevent_updates_and_deletions();

CREATE TRIGGER exchange_rate_append_only
BEFORE UPDATE OR DELETE on "exchange_rates"
FOR EACH ROW
EXECUTE PROCEDURE prevent_updates_and_deletions();

COMMIT;

CREATE OR REPLACE FUNCTION get_utc_offset(tz_name VARCHAR)
RETURNS INT AS $$
DECLARE
  utc_offset INT;
BEGIN
  SELECT EXTRACT(epoch FROM now() AT TIME ZONE tzname) - EXTRACT(epoch FROM now()),
  FROM pg_timezone_names
  WHERE tzname = tz_name
  INTO utc_offset;

  RETURN utc_offset;
END;
$$ LANGUAGE plpgsql;

CREATE INDEX ledgers_user_id_idx ON ledgers(user_id) CONCURRENTLY;

---- APIs ----
-- User won some amount of dream token at a particular time of the day
-- Let's say user has won 1 token
-- Add one entry to journal for the request and user that journal_id here for reference

DO $$
  DECLARE 
    cur_timestamp TIMESTAMP := CURRENT_TIMESTAMP;
    user_last_balance INT DEFAULT 0; 
    owner_last_balance INT DEFAULT 0; 
  BEGIN
    SELECT to_balance 
    FROM ledgers 
    WHERE
      user_id = 2 and
      type = 0 -- token
    ORDER BY timestamp DESC
    LIMIT 1
    INTO user_last_balance;

    SELECT to_balance 
    FROM ledgers 
    WHERE
      user_id = 1 and -- user_id of owner is assumed to be 1
      type = 0 -- token
    ORDER BY timestamp DESC
    LIMIT 1
    INTO owner_last_balance;

   -- Check if there is no last_balance, otherwise assign 0
    INSERT INTO "ledgers"(user_id, type, from_balance, to_balance, journal_id, timestamp)
    VALUES
      (2, 0, user_last_balance, 1, journal_id, cur_timestamp), 
      (1, 0, owner_last_balance, -1, journal_id, cur_timestamp) -- 1 user_id is Dreamland user.
  COMMIT;
END $$;

-- API 2: History of dream tokens a user has won for the current day so far
SELECT 
  to_balance - from_balance as amount,
  timestamp
FROM ledgers 
WHERE 
  user_id = 1 AND 
  type = 0 AND  -- Token
  timestamp >= ((NOW()::DATE)::TIMESTAMP + get_utc_offset(SELECT timezone from "user" WHERE user_id = 1)); -- Considering the uesr's timezone and date there


--- Automated Conversion every hour from tokens to USD
DO $$
BEGIN
  -- Add a journal entry for reference
  -- Add two entries in Token ledger for user and owner
  -- Add two entries in Fiat ledger for user and owner
  -- Add one entry in Fiat ledger for owner to add fees
  -- Add one entry in exchange_rates table 
END $$;

--- API 3: History of USD Amounts a user has won till now
