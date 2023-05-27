from sqlalchemy.types import INTEGER, String
import SchemasTables as ST
""" class estra():
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
            raise RuntimeError("Please confirm your choise")git 
            

if __name__ == "__main__":  
    #presto = estra() """
presto = ST.Elements()
for i, j in presto.df_schema.items():
    print(f'CREATE TABLE IF NOT EXISTS {i} ({presto.format_query(j)});')
    print(f'INSERT INTO {i} ({presto.format_query(Listpar =presto.name_columns_csv[i])}) VALUES ({presto.format_query(Listpar =ST.Elements.name_columns_csv[i], inserdata=1)});')
    
f = 'primary/csvdata/filecsv.csv'
file_name = f.split('/')[-1].split('.csv')[0]
print(file_name)
    
    

    
