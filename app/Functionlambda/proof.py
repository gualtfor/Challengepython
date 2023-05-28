from sqlalchemy.types import INTEGER, String
import SchemasTables as ST
import json
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
d= {"d": [{"f": 5, "g": {0: 6}}]}
proof = {'Records': [{'eventVersion': '2.1', 'eventSource': 'aws:s3', 'awsRegion': 'us-east-1', 'eventTime': '2023-05-28T01:56:58.271Z', 'eventName': 'ObjectCreated:Put', 'userIdentity': {'principalId': 'A2WBHEOLBB9376'}, 'requestParameters': {'sourceIPAddress': '191.109.174.28'}, 'responseElements': {'x-amz-request-id': '110MM7SCJTV70J0D', 'x-amz-id-2': 'thvifJZkLxWwiN+SkDGnGBvYo9TOIRtq+C7xmvMH1Z3PrdqCzK4wJZPFcCRdhmOwtsGovZPMedh1h+9NNYFDxJXiWrd15ES4RvMMjOcMUFI='}, 's3': {'s3SchemaVersion': '1.0', 'configurationId': 'tf-s3-lambda-20230528013929371800000002', 'bucket': {'name': 'bucketproof-challenge', 'ownerIdentity': {'principalId': 'A2WBHEOLBB9376'}, 'arn': 'arn:aws:s3:::bucketproof-challenge'}, 'object': {'key': 'datacsv/hired_employees.csv', 'size': 92933, 'eTag': '20e8c00619a800a48e4de8e98566a506', 'sequencer': '006472B4EA3E1795A0'}}}]}
print(proof["Records"][0]["s3"]["bucket"]["name"])

    
