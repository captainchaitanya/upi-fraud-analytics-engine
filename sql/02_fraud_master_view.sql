-- =============================================================
-- 02_fraud_master_view.sql
-- Joined view combining transactions + identity, with derived
-- timestamp fields (the dataset's TransactionDT is seconds
-- elapsed from a reference point, not a real timestamp).
-- =============================================================

CREATE VIEW fraud_master AS
SELECT
    t.TransactionID,
    t.isFraud,
    t.TransactionAmt,
    t.ProductCD,
    t.card4,
    t.card6,
    t.P_emaildomain,
    t.C1, t.C2, t.C6, t.C11,
    t.D1, t.D10, t.D15,
    t.M4, t.M6,
    TIMESTAMP '2017-11-30 00:00:00' + (t.TransactionDT * INTERVAL '1 second') AS txn_timestamp,
    EXTRACT(HOUR FROM TIMESTAMP '2017-11-30 00:00:00' + (t.TransactionDT * INTERVAL '1 second')) AS txn_hour,
    EXTRACT(DOW  FROM TIMESTAMP '2017-11-30 00:00:00' + (t.TransactionDT * INTERVAL '1 second')) AS txn_dow,
    i.DeviceType,
    i.DeviceInfo,
    i.id_30 AS operating_system,
    i.id_31 AS browser,
    i.id_15 AS found_device
FROM transactions t
LEFT JOIN identity i ON t.TransactionID = i.TransactionID;
