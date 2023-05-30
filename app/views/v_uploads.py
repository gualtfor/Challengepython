from fastapi import UploadFile, File, APIRouter
import pandas as pd
from io import StringIO
from app.config.context import get_db, engine
from app.schemas.tables import df_schema, name_columns_csv
from pandas_schema.validation import CustomElementValidation
from pandas_schema import Schema, Column
import numpy as np

router = APIRouter()

def check_int(num):
    try:
        int(num)
    except ValueError:
        return False
    return True


int_validation = [CustomElementValidation(
    lambda i: check_int(i), lambda i: print(i))]
null_validation = [CustomElementValidation(
    lambda d: d is not np.nan, lambda i: print(i))]

sch_employee = Schema([
    Column('id', null_validation + int_validation),
    Column('name', null_validation),
    Column('datetime', null_validation),
    Column('department_id', null_validation + int_validation),
    Column('job_id', null_validation + int_validation)
])


sch_jobs = Schema([
        Column('id', null_validation + int_validation),
        Column('job', null_validation)
    ])

sch_departments = Schema([
    Column('id', null_validation + int_validation),
    Column('department', null_validation)
])



@router.post("/upload/{table}", tags=["Upload Files"])
async def create_upload_file(table, file: UploadFile = File(...)):
    contents = await file.read()
    s = str(contents, 'utf-8')
    data = StringIO(s)
    df = pd.read_csv(data, names=name_columns_csv[table], sep=',')
    if table == 'hired_employees':
        errors = sch_employee.validate(df)
    if table == 'jobs':
        errors = sch_jobs.validate(df)
    if table == 'departments':
        errors = sch_departments.validate(df)
    errors_index_rows = [e.row for e in errors]
    data_clear = df.drop(index=errors_index_rows)
    data_clear.to_sql(table, engine, if_exists='append', index=False, chunksize=1000, dtype=df_schema[table])
    errors_rows = df.filter(items=errors_index_rows, axis=0)
    errors_rows.to_sql(table + '_errors', engine, if_exists='append', index=False, chunksize=1000, dtype=df_schema[table])
    return {file.filename}
