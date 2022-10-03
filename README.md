# postgres-cdc-debezium


## Objective:
- Verify if debezium is able to handle toastable column values.
- What is [TOAST](https://wiki.postgresql.org/wiki/TOAST)?
    - a mechanism PostgreSQL uses to keep physical data rows from exceeding the size of a data block (typically 8KB)
    - TLDR; instead of storing the entire large block of data, it stores a small pointer to that location instead.

- Why is this important?
    - Change data capture (CDC) are used to create a near real-time replication to data warehouses, such as [BigQuery](https://cloud.google.com/blog/products/data-analytics/real-time-cdc-replication-bigquery)

with the current version of `wal2json`, toasted values are ignored.
- https://github.com/debezium/debezium/pull/790
- https://github.com/eulerto/wal2json/issues/98

## How to setup?
1. Host services in background
```
docker-compose up -d
```
2. Connect debezium to postgresql
```
curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @register-postgres.json
```
3. Access the postgres (to make changes)
```
docker exec -ti snl-debezium_postgres_1 psql -U postgresuser -d shipment_db
```
4. Open a new tab, and monitor kafka output
```
docker run --tty \
--network snl-debezium_default \
confluentinc/cp-kafkacat \
kafkacat -b kafka:9092 -C \
-s key=s -s value=avro \
-r http://schema-registry:8081 \
-t postgres.public.sales_target
```


## How to replicate this?
With default settings
```
-- need to insert a large text which after compress will still be toasted

INSERT INTO public.sales_target (sale_value, biography) VALUES (1, (SELECT array_to_string(ARRAY(SELECT chr((65 + round(random() * 25)) :: integer) FROM generate_series(1,4000)), '')));

{
    'id': 4,
    'sale_value': 1,
    'biography': 'beep',
    'created_at': 1663951227410675,
    'updated_at': 1663951227410675'
}


UPDATE public.sales_target 
set sale_value  = 2
where id = 4;

-- notice that biography is missing here
{
    'id': 4,
    'sale_value': 2,
    'created_at': 1664549952652282,
    'updated_at': 1664550008941498
}

```

Add `"schema.refresh.mode":"columns_diff_exclude_unchanged_toast"` into register-postgres.json and rerun everything again, you will notice for the update statement, `biography` column exists.
```
{
    'id': 4,
    'sale_value': 2,
    'biography': '__debezium_unavailable_value',
    'created_at': 1664549952652282,
    'updated_at': 1664550008941498
}

```


- Type of plugin:
    - wal2json
    - pgoutput (comes with postgres >= 10.x)