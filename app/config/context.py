from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

user = 'gualtfor'
password = 'admin1234'
host = 'postgres-db' #'challengedb.cwaajgnim8t3.us-east-1.rds.amazonaws.com'
port = 5432
database = 'postgres' #challengedb'

engine = create_engine(
    "postgresql+psycopg2://{0}:{1}@{2}:{3}/{4}".format(user, password, host, port, database)
    #"postgresql+psycopg2://gualtfor:admin1234@db-server:5432/postgres"
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()