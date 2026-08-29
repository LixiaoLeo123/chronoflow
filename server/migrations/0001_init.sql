PRAGMA journal_mode=WAL;
PRAGMA foreign_keys=ON;

CREATE TABLE users (
    id TEXT PRIMARY KEY,
    username TEXT NOT NULL UNIQUE COLLATE NOCASE,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE TABLE refresh_tokens (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash TEXT NOT NULL UNIQUE,
    expires_at TEXT NOT NULL,
    revoked_at TEXT,
    created_at TEXT NOT NULL
);

CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id);

CREATE TABLE invites (
    code TEXT PRIMARY KEY,
    created_by TEXT REFERENCES users(id) ON DELETE SET NULL,
    used_by TEXT REFERENCES users(id) ON DELETE SET NULL,
    used_at TEXT,
    expires_at TEXT NOT NULL,
    created_at TEXT NOT NULL
);

CREATE TABLE activities (
    id TEXT PRIMARY KEY,
    account_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    color INTEGER NOT NULL,
    archived INTEGER NOT NULL DEFAULT 0,
    deleted INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE INDEX idx_activities_account_updated ON activities(account_id, updated_at);
CREATE UNIQUE INDEX idx_activities_active_color
    ON activities(account_id, color)
    WHERE deleted = 0 AND archived = 0;

CREATE TABLE time_blocks (
    id TEXT PRIMARY KEY,
    account_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    activity_id TEXT NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
    kind TEXT NOT NULL CHECK (kind IN ('focus', 'shortBreak', 'longBreak')),
    start_at TEXT NOT NULL,
    end_at TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('active', 'completed', 'cancelled')),
    deleted INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    CHECK (end_at > start_at)
);

CREATE INDEX idx_time_blocks_account_updated ON time_blocks(account_id, updated_at);
CREATE INDEX idx_time_blocks_account_start ON time_blocks(account_id, start_at);

CREATE TABLE timer_settings (
    account_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    focus_minutes INTEGER NOT NULL DEFAULT 25,
    short_break_minutes INTEGER NOT NULL DEFAULT 5,
    long_break_minutes INTEGER NOT NULL DEFAULT 15,
    rounds_before_long_break INTEGER NOT NULL DEFAULT 4,
    auto_start_breaks INTEGER NOT NULL DEFAULT 1,
    auto_start_focus INTEGER NOT NULL DEFAULT 0,
    updated_at TEXT NOT NULL
);
