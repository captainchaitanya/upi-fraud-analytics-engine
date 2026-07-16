-- =============================================================
-- 03_fraud_rate_analysis.sql
-- Exploratory fraud-rate breakdowns by card type, hour of day,
-- device type, email domain, and transaction amount bucket.
-- Feeds: fraud_by_card_product.csv, fraud_by_hour.csv,
--        fraud_by_device.csv, fraud_by_email_domain.csv,
--        fraud_by_amount_bucket.csv
-- =============================================================

-- Overall fraud rate across the full dataset
SELECT COUNT(*),
       SUM(isFraud) AS total_fraud,
       ROUND(100.0 * AVG(isFraud), 2) AS fraud_rate_pct
FROM fraud_master;

-- Fraud rate by card network / card type / product
SELECT
    card4                           AS card_network,
    card6                           AS card_type,
    ProductCD                       AS product,
    COUNT(*)                        AS total_txns,
    SUM(isFraud)                    AS fraud_count,
    ROUND(100.0 * AVG(isFraud), 3)  AS fraud_rate_pct,
    ROUND(AVG(TransactionAmt), 2)   AS avg_txn_amount,
    ROUND(AVG(CASE WHEN isFraud = 1 THEN TransactionAmt END), 2) AS avg_fraud_amount
FROM fraud_master
WHERE card4 IS NOT NULL
GROUP BY card4, card6, ProductCD
ORDER BY fraud_rate_pct DESC;

-- Fraud rate by hour of day
SELECT
    txn_hour,
    COUNT(*)                        AS total_txns,
    SUM(isFraud)                    AS fraud_count,
    ROUND(100.0 * AVG(isFraud), 3)  AS fraud_rate_pct,
    ROUND(AVG(TransactionAmt), 2)   AS avg_amount
FROM fraud_master
GROUP BY txn_hour
ORDER BY txn_hour;

-- Fraud rate by device type
SELECT
    COALESCE(DeviceType, 'Unknown')  AS device_type,
    COUNT(*)                         AS total_txns,
    SUM(isFraud)                     AS fraud_count,
    ROUND(100.0 * AVG(isFraud), 3)   AS fraud_rate_pct,
    ROUND(AVG(TransactionAmt), 2)    AS avg_txn_amount
FROM fraud_master
GROUP BY DeviceType
ORDER BY fraud_rate_pct DESC;

-- Fraud rate by payer email domain (top 20, min 200 txns to filter noise)
SELECT
    P_emaildomain                   AS payer_email_domain,
    COUNT(*)                        AS total_txns,
    SUM(isFraud)                    AS fraud_count,
    ROUND(100.0 * AVG(isFraud), 3)  AS fraud_rate_pct
FROM fraud_master
WHERE P_emaildomain IS NOT NULL
GROUP BY P_emaildomain
HAVING COUNT(*) > 200
ORDER BY fraud_rate_pct DESC
LIMIT 20;

-- Fraud rate by transaction amount bucket
SELECT
    CASE
        WHEN TransactionAmt < 50    THEN '1_Under $50'
        WHEN TransactionAmt < 100   THEN '2_$50-100'
        WHEN TransactionAmt < 200   THEN '3_$100-200'
        WHEN TransactionAmt < 500   THEN '4_$200-500'
        WHEN TransactionAmt < 1000  THEN '5_$500-1K'
        ELSE                             '6_Over $1K'
    END                             AS amount_bucket,
    COUNT(*)                        AS total_txns,
    SUM(isFraud)                    AS fraud_count,
    ROUND(100.0 * AVG(isFraud), 3)  AS fraud_rate_pct
FROM fraud_master
GROUP BY 1
ORDER BY 1;
