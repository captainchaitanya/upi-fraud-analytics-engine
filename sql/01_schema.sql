-- =============================================================
-- 01_schema.sql
-- UPI Fraud Detection Analytics — Schema Setup
-- =============================================================
-- NOTE: The `transactions` table (loaded from the IEEE-CIS
-- `train_transaction.csv`) is assumed to already exist with a
-- standard schema matching the source dataset's columns
-- (TransactionID, isFraud, TransactionAmt, ProductCD, card1-card6,
-- P_emaildomain, C1-C14, D1-D15, M1-M9, etc.), loaded via a
-- separate CSV import step (e.g., \copy or pgAdmin's import tool).
-- =============================================================

-- Identity table (from IEEE-CIS `train_identity.csv`)
-- Linked 1:1 to transactions via TransactionID
DROP TABLE IF EXISTS identity;

CREATE TABLE identity (
    TransactionID BIGINT PRIMARY KEY REFERENCES transactions(TransactionID),
    id_01 NUMERIC, id_02 NUMERIC, id_03 NUMERIC,
    id_04 NUMERIC, id_05 NUMERIC, id_06 NUMERIC,
    id_07 NUMERIC, id_08 NUMERIC, id_09 NUMERIC,
    id_10 NUMERIC, id_11 NUMERIC, id_12 VARCHAR(20),
    id_13 NUMERIC, id_14 NUMERIC, id_15 VARCHAR(20),
    id_16 VARCHAR(20), id_17 NUMERIC, id_18 NUMERIC,
    id_19 VARCHAR(100), id_20 VARCHAR(100),
    id_21 NUMERIC, id_22 NUMERIC, id_23 VARCHAR(100),
    id_24 VARCHAR(100), id_25 VARCHAR(100), id_26 VARCHAR(100),
    id_27 VARCHAR(20), id_28 VARCHAR(20), id_29 VARCHAR(20),
    id_30 VARCHAR(100), id_31 VARCHAR(100),
    id_32 NUMERIC, id_33 VARCHAR(20), id_34 VARCHAR(50),
    id_35 VARCHAR(5), id_36 VARCHAR(5), id_37 VARCHAR(5), id_38 VARCHAR(5),
    DeviceType VARCHAR(20),
    DeviceInfo VARCHAR(200)
);
