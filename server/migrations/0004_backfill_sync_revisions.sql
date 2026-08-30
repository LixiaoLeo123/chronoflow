UPDATE activities SET sync_revision = rowid WHERE sync_revision = 0;
UPDATE time_blocks SET sync_revision =
    (SELECT COALESCE(MAX(sync_revision), 0) FROM activities) + rowid
WHERE sync_revision = 0;
UPDATE sync_sequence SET value = (
    SELECT COALESCE(MAX(sync_revision), 0) FROM (
        SELECT sync_revision FROM activities
        UNION ALL
        SELECT sync_revision FROM time_blocks
    )
);
