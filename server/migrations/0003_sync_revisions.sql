ALTER TABLE activities ADD COLUMN sync_revision INTEGER NOT NULL DEFAULT 0;
ALTER TABLE time_blocks ADD COLUMN sync_revision INTEGER NOT NULL DEFAULT 0;

CREATE TABLE sync_sequence (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    value INTEGER NOT NULL DEFAULT 0
);

INSERT INTO sync_sequence (id, value)
SELECT 1, COALESCE(MAX(sync_revision), 0)
FROM (
    SELECT sync_revision FROM activities
    UNION ALL
    SELECT sync_revision FROM time_blocks
);

CREATE INDEX idx_activities_account_revision
    ON activities(account_id, sync_revision);
CREATE INDEX idx_time_blocks_account_revision
    ON time_blocks(account_id, sync_revision);
