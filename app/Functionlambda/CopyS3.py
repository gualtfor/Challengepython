import json
import boto3
import csv
import os
import logging
import mysql.connector
import SchemasTables as ST
from mysql.connector import Error
from mysql.connector import errorcode


def lambda_handler(event, context):
    s3_client = boto3.client('s3')

    logger = logging.getLogger('INIT-DB')
    logger.setLevel(logging.INFO)
    try:
        db_host = os.environ['DB_HOST']
        db_name = os.environ['DB_INSTANCE_NAME']
        app_db_user = os.environ['APP_DB_USER']
        app_db_pass = os.environ['APP_DB_PASS']
        app_db_name = os.environ['APP_DB_NAME'] # name of the database in aws RDS
        env = os.environ['ENV']
        project = os.environ['PROJECT']
    except:
        return {
            'Error': 'UnableToGetEnvInformations'
        }
        
        
    bucket = event['Records'][0]['bucket']['name']
    csv_file = event['Records'][0]['object']['key']
    csv_file_obj = s3_client.get_object(Bucket=bucket, key=csv_file)
    lines = csv_file_obj['Body'].read().decode('utf-8').split()
    results = []
    for row in csv.DictReader(lines):
        results.append(row.values())
    print(results)
    
    # Check if the db exist
    logger.info('Checking the db exists...')
    with mysql.connector.connect(host=db_host, database=db_name, user=app_db_user, password=app_db_pass) as conn:
        conn.autocommit = True
        with conn.cursor() as cur:
            cur.execute(f"SELECT count(*) FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '${app_db_name}';")
            if cur.fetchone()[0] == 1:
                return {
                    'Error': 'DatabaseAlreadyCreated'
                }
                
    logger.info('DB does not exists, creating username and db')
    try:
        with mysql.connector.connect(host=db_host, database=db_name, user=app_db_user, password=app_db_pass) as conn:
            conn.autocommit = True
            with conn.cursor() as cur:
                cur.execute(f"CREATE USER {app_db_user} WITH PASSWORD '{app_db_pass}';")
                cur.execute(f"CREATE DATABASE {app_db_name};")
                cur.execute(f"GRANT ALL PRIVILEGES ON DATABASE {app_db_name} TO {app_db_user}")
    except Exception as e:
        logger.exception(e)
        logger.error('Unable to create database')
        return {
                'Error': 'UnableToCreateDatabase'
            }
        
    logger.info('Username and db created')

        
    try:
        with mysql.connector.connect(host=db_host, database=app_db_name, user=app_db_user, password=app_db_pass) as conn:
            conn.autocommit = True
            with conn.cursor() as cur:
                for i, j in ST.Elements.df_schema.items():
                    sql_create_table = f'CREATE TABLE IF NOT EXISTS {i} ({ST.Elements.format_query(j)});'
                    sql_insert_table = f'INSERT INTO {} ({ST.Elements.format_query(Listpar = ST.Elements.name_columns_csv[i])}) VALUES ({ST.Elements.format_query(Listpar = ST.Elements.name_columns_csv[i], inserdata=1)});'
                    cur.execute(sql_create_table)
                    cur.executemany(sql_insert_table, results)
                    
        logger.info('Created tables')
        return {
            'created': 'true'
        }
    except Exception as e:
        logger.exception(e)
        logger.error('Unable to create table')
        return {
            'created': 'false'
            } 
