-- =============================================================
-- 04_risk_scoring_pipeline.sql
-- Window-function-based risk scoring: flags cards with 3+ fraud
-- events in a trailing 30-day window (LAG + rolling SUM/COUNT)
-- and flags sudden transaction-amount spikes (10x prior txn).
-- Combines both into a risk_score and risk_tier classification.
-- Feeds: risk_tier_summary.csv, critical_transactions.csv
-- =============================================================

CREATE VIEW risk_scored_transactions AS
WITH card_fraud_events AS (
    SELECT
        t.TransactionID,
        t.card1,
        t.TransactionAmt,
        t.isFraud,
        fm.txn_timestamp,
        -- Rolling 30-day fraud count per card
        SUM(t.isFraud) OVER (
            PARTITION BY t.card1
            ORDER BY fm.txn_timestamp
            RANGE BETWEEN INTERVAL '30 days' PRECEDING AND CURRENT ROW
        ) AS fraud_count_30d,
        -- Rolling 30-day transaction count per card
        COUNT(*) OVER (
            PARTITION BY t.card1
            ORDER BY fm.txn_timestamp
            RANGE BETWEEN INTERVAL '30 days' PRECEDING AND CURRENT ROW
        ) AS txn_count_30d,
        -- Previous transaction time on same card
        LAG(fm.txn_timestamp) OVER (
            PARTITION BY t.card1 ORDER BY fm.txn_timestamp
        ) AS prev_txn_time,
        -- Previous transaction amount on same card
        LAG(t.TransactionAmt) OVER (
            PARTITION BY t.card1 ORDER BY fm.txn_timestamp
        ) AS prev_txn_amt
    FROM transactions t
    JOIN fraud_master fm ON t.TransactionID = fm.TransactionID
    WHERE fm.txn_timestamp IS NOT NULL
),

card_risk_signals AS (
    SELECT
        *,
        EXTRACT(EPOCH FROM (txn_timestamp - prev_txn_time)) / 60 AS mins_since_last_txn,
        -- Flag: 3+ frauds in last 30 days
        CASE WHEN fraud_count_30d >= 3 THEN 1 ELSE 0 END AS high_risk_flag,
        -- Flag: amount is 10x previous transaction
        CASE
            WHEN TransactionAmt > 10 * COALESCE(prev_txn_amt, TransactionAmt)
            THEN 1 ELSE 0
        END AS amount_spike_flag
    FROM card_fraud_events
)

SELECT
    TransactionID,
    card1,
    txn_timestamp,
    TransactionAmt,
    isFraud,
    fraud_count_30d,
    txn_count_30d,
    ROUND(mins_since_last_txn::NUMERIC, 1) AS mins_since_last_txn,
    high_risk_flag,
    amount_spike_flag,
    (high_risk_flag + amount_spike_flag) AS risk_score,
    CASE
        WHEN (high_risk_flag + amount_spike_flag) >= 2 THEN 'CRITICAL'
        WHEN (high_risk_flag + amount_spike_flag) = 1  THEN 'HIGH'
        ELSE 'NORMAL'
    END AS risk_tier
FROM card_risk_signals;

-- Summary: transaction volume, confirmed fraud, and fraud rate by risk tier
SELECT
    risk_tier,
    COUNT(*)                        AS total_txns,
    SUM(isFraud)                    AS actual_frauds,
    ROUND(100.0 * AVG(isFraud), 2)  AS fraud_rate_pct,
    ROUND(AVG(TransactionAmt), 2)   AS avg_amount
FROM risk_scored_transactions
GROUP BY risk_tier
ORDER BY fraud_rate_pct DESC;

-- NOTE: risk_score here is a small additive flag score (0-2), not a
-- continuous severity metric — CRITICAL-tier rows will mostly share
-- the same low integer score since the tier itself is derived from it.
-- The `critical_transactions` export used TransactionAmt (not risk_score)
-- to prioritize/color-code rows within the Critical tier for this reason.
