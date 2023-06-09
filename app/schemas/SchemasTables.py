from tokenize import String
from sqlalchemy.types import INTEGER, String

class Elements():
   name_columns_csv = {'hired_employees': ["id", "name", "datetime", "department_id", "job_id"],
                       'departments': ["id", "department"], 'jobs': ["id", "job"]}
   
   df_schema = {"hired_employees": {
                    "id": "INTEGER PRIMARY KEY",
                    "name": "String(200)",
                    "datatime": "String(200)",
                    "department_id": "INTEGER",
                    "job_id": "INTEGER"
                },
                "departments":{
                    "id": "INTEGER PRIMARY KEY",
                    "department": "String(200)"
                },
                "jobs":{
                    "id": "INTEGER PRIMARY KEY",
                    "job": "String(200)"
                }
    }
   def format_query(self, Dict={}, Listpar=[], inserdata=0):
        ListParameters = []
        try:
            if not Listpar and not inserdata:
                for i, j in Dict.items():
                    ListParameters.append(' '.join([i, str(j)]))
                return ', '.join(ListParameters)
            if not Dict and not inserdata:
                return ', '.join(Listpar)
            for a in Listpar:
                ListParameters.append('%s')
            return ', '.join(ListParameters)
        except Exception :
            raise RuntimeError("Please confirm your choise")


   