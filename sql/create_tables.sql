CREATE DATABASE IF NOT EXISTS hw2;

CREATE TABLE IF NOT EXISTS hw2.transactions
(
    transaction_time DateTime,
    merch LowCardinality(String),
    cat_id LowCardinality(String),
    amount Decimal64(2),
    name_1 String,
    name_2 String,
    gender LowCardinality(String),
    street String,
    one_city LowCardinality(String),
    us_state LowCardinality(String),
    post_code UInt32,
    lat Float64,
    lon Float64,
    population_city UInt32,
    jobs LowCardinality(String),
    merchant_lat Float64,
    merchant_lon Float64,
    target Nullable(UInt8)
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(transaction_time)
ORDER BY (us_state, transaction_time);

ALTER TABLE hw2.transactions
ADD PROJECTION IF NOT EXISTS max_transaction_by_state
(
    SELECT
        us_state,
        argMax(cat_id, tuple(amount, cat_id)) AS max_category,
        max(amount) AS max_amount
    GROUP BY us_state
);

ALTER TABLE hw2.transactions
MATERIALIZE PROJECTION max_transaction_by_state
SETTINGS mutations_sync = 1;

CREATE TABLE IF NOT EXISTS hw2.transactions_kafka
(
    transaction_time DateTime,
    merch String,
    cat_id String,
    amount Decimal64(2),
    name_1 String,
    name_2 String,
    gender String,
    street String,
    one_city String,
    us_state String,
    post_code UInt32,
    lat Float64,
    lon Float64,
    population_city UInt32,
    jobs String,
    merchant_lat Float64,
    merchant_lon Float64,
    target Nullable(UInt8)
)
ENGINE = Kafka
SETTINGS
    kafka_broker_list = 'kafka:9092',
    kafka_topic_list = 'transactions',
    kafka_group_name = 'clickhouse-hw2',
    kafka_format = 'JSONEachRow',
    kafka_num_consumers = 1;

CREATE MATERIALIZED VIEW IF NOT EXISTS hw2.transactions_mv
TO hw2.transactions
AS SELECT * FROM hw2.transactions_kafka;
