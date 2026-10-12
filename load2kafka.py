import csv
import json
import os
import sys
from datetime import datetime

from kafka import KafkaProducer


def main():
    errors = []
    producer = KafkaProducer(
        bootstrap_servers=os.getenv('KAFKA_BROKERS', 'localhost:9096'),
        value_serializer=lambda row: json.dumps(row).encode('utf-8'),
        acks='all',
        batch_size=131072,
        linger_ms=20,
        buffer_memory=67108864,
    )
    topic = os.getenv('KAFKA_TOPIC', 'transactions')
    files = sys.argv[1:] or ['data/train.csv', 'data/test.csv']

    for filename in files:
        with open(filename, newline='', encoding='utf-8') as file:
            count = 0
            for row in csv.DictReader(file):
                row['transaction_time'] = datetime.fromisoformat(
                    row['transaction_time']
                ).strftime('%Y-%m-%d %H:%M:%S')
                for column in ['post_code', 'population_city']:
                    row[column] = int(row[column])
                for column in ['lat', 'lon', 'merchant_lat', 'merchant_lon']:
                    row[column] = float(row[column])
                if 'target' in row:
                    row['target'] = int(row['target'])
                else:
                    row['target'] = None
                producer.send(topic, value=row).add_errback(errors.append)
                count += 1

        producer.flush()
        if errors:
            raise RuntimeError(errors[0])
        print(f'{filename}: отправлено {count} строк', flush=True)

    producer.close()


if __name__ == '__main__':
    main()
