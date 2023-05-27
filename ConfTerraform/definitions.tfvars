region = "us-east-1"

availability_zones = ["us-east-1a", "us-east-1b"]

namespace = "eg"

stage = "test"

name = "rds-mysql"

deletion_protection = false

database_name = "ChallengePython"

database_user = "gualtfor"

database_password = "admin1234"

database_port = 3306

multi_az = false

storage_type = "standard"

storage_encrypted = false

allocated_storage = 5

# Microsoft MYSQL on Amazon RDS
# https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MySQL.html
engine = "mysql"

# https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/MySQL.Concepts.VersionMgmt.html
engine_version = "5.7"

#major_engine_version = "5.7"
major_engine_version = "8"

instance_class = "db.t2.small"

#db_parameter_group = "mysql5.7"
db_parameter_group = "default.mysql5.7"

publicly_accessible = false

apply_immediately = true

bucket_name = "depot"

env = "Dev"

