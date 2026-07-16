-- =============================================================
-- 05_velocity_anomalies.sql
-- Detects transaction "velocity" anomalies: cards making more
-- than 5 transactions within a rolling 10-minute window —
-- a common signature of automated/rapid-fire card testing fraud.
-- Feeds: velocity_summary.csv, velocity_flagged_transactions.csv
-- =============================================================

CREATE VIEW velocity_anomalies AS
WITH txn_windows AS (
    SELECT
        t.card1,
        t.TransactionID,
        t.TransactionAmt,
        t.isFraud,
        fm.txn_timestamp,
        COUNT(*) OVER (
            PARTITION BY t.card1
            ORDER BY fm.txn_timestamp
            RANGE BETWEEN INTERVAL '10 minutes' PRECEDING AND CURRENT ROW
        ) AS txns_in_10min,
        SUM(t.TransactionAmt) OVER (
            PARTITION BY t.card1
            ORDER BY fm.txn_timestamp
            RANGE BETWEEN INTERVAL '10 minutes' PRECEDING AND CURRENT ROW
        ) AS amount_in_10min
    FROM transactions t
    JOIN fraud_master fm ON t.TransactionID = fm.TransactionID
    WHERE fm.txn_timestamp IS NOT NULL
)
SELECT
    *,
    CASE WHEN txns_in_10min > 5 THEN 1 ELSE 0 END AS velocity_flag
FROM txn_windows;

-- Summary: fraud rate and average window stats, flagged vs. not flagged
SELECT
    velocity_flag,
    COUNT(*)                        AS total_txns,
    SUM(isFraud)                    AS fraud_count,
    ROUND(100.0 * AVG(isFraud), 2)  AS fraud_rate_pct,
    ROUND(AVG(TransactionAmt), 2)   AS avg_amount,
    ROUND(AVG(txns_in_10min), 1)    AS avg_txns_in_window
FROM velocity_anomalies
GROUP BY velocity_flag
ORDER BY velocity_flag DESC;

-- Detail export: top 5000 flagged transactions, sorted by burst intensity
SELECT card1, TransactionID, txn_timestamp, TransactionAmt,
       isFraud, txns_in_10min, amount_in_10min
FROM velocity_anomalies
WHERE velocity_flag = 1
ORDER BY txns_in_10min DESC
LIMIT 5000;
