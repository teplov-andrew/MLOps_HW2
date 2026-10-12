# MLOps HW2

Загрузка транзакций из CSV в Kafka и ClickHouse, поиск категории наибольшей транзакции по каждому штату.

## 1. Подготовка

Создайте папку для исходных данных:

```bash
mkdir -p data
```

Скачайте `train.csv` и `test.csv`
со [страницы соревнования](https://www.kaggle.com/competitions/teta-ml-1-2025/data)
и положите их в `data/`.

## 2. Запуск

```bash
docker compose up -d
docker compose ps -a
```

Дождитесь запуска Kafka и ClickHouse. `kafka-setup` создаёт топик `transactions`,
а `clickhouse-init` выполняет DDL из `sql/create_tables.sql`.
Оба вспомогательных сервиса должны завершиться с кодом 0.

## 3. Загрузка данных

```bash
docker compose run --rm --build producer
```

Скрипт `load2kafka.py` отправляет строки из обоих CSV в Kafka.
Для `test.csv` поле `target` заполняется `NULL`.
Повторная загрузка добавляет те же строки ещё раз.

## 4. Проверка результатов

Проверьте количество строк в ClickHouse. После одной загрузки обоих файлов
ожидается **1 048 575** строк:

```bash
docker compose exec clickhouse clickhouse-client --query "SELECT count() FROM hw2.transactions;"
```

Выполните запрос и сохраните результат в CSV:

```bash
mkdir -p results
docker compose exec -T clickhouse clickhouse-client < sql/max_transaction_by_state.sql > results/result.csv
```

Если данные ещё не появились, проверьте логи:

```bash
docker compose logs --tail=50 clickhouse kafka
```
