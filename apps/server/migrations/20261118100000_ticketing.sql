-- migrate:up
CREATE TABLE users (
  id text PRIMARY KEY,
  name text NOT NULL,
  role text NOT NULL CHECK (role IN ('visitor', 'organizer', 'usher')),
  login text UNIQUE,
  password_hash text
);

CREATE TABLE events (
  id text PRIMARY KEY,
  name text NOT NULL,
  venue text NOT NULL,
  starts_at timestamptz NOT NULL,
  price_rsd int NOT NULL CHECK (price_rsd >= 0),
  capacity int NOT NULL CHECK (capacity >= 0),
  organizer_id text NOT NULL REFERENCES users (id)
);

CREATE TABLE tickets (
  id text PRIMARY KEY,
  event_id text NOT NULL REFERENCES events (id),
  holder_id text NOT NULL REFERENCES users (id),
  holder_name text NOT NULL,
  status text NOT NULL CHECK (status IN ('reserved', 'paid', 'used', 'cancelled', 'expired')),
  expires_at timestamptz,
  status_at timestamptz,
  status_by text REFERENCES users (id),
  cancel_reason text,
  created_at timestamptz NOT NULL,
  code text NOT NULL UNIQUE,
  CONSTRAINT tickets_reserved_has_deadline CHECK (status <> 'reserved' OR expires_at IS NOT NULL)
);

CREATE INDEX tickets_by_event ON tickets (event_id);
CREATE INDEX tickets_by_holder ON tickets (holder_id);

-- migrate:down
DROP TABLE tickets;
DROP TABLE events;
DROP TABLE users;
