module "db" {
  source  = "terraform-aws-modules/rds/aws"


  identifier = local.name

  # All available versions: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts
  engine               = "postgres"
  engine_version       = "14.1"
  family               = "postgres14" # DB parameter group
  major_engine_version = "14"         # DB option group
  instance_class       = "db.t4g.large"

  allocated_storage     = 20
  max_allocated_storage = 100

  db_name  = "completePostgresql"
  username = "complete_postgresql"
  port     = 5432

  multi_az               = true
  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [module.vpc.default_security_group_id]

  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  create_cloudwatch_log_group     = true

  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  create_monitoring_role                = true
  monitoring_interval                   = 60
  monitoring_role_name                  = "example-monitoring-role-name"
  monitoring_role_use_name_prefix       = true
  monitoring_role_description           = "Description for monitoring role"

  parameters = [
    {
      name  = "autovacuum"
      value = 1
    },
    {
      name  = "client_encoding"
      value = "utf8"
    }
  ]

  tags = local.common_tags
  db_option_group_tags = {
    "Sensitive" = "low"
  }
  db_parameter_group_tags = {
    "Sensitive" = "low"
  }
}



## parametrised groups unautorised
resource "aws_elasticache_cluster" "example" {
  cluster_id           = "cluster-example"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
 # parameter_group_name = "default.redis3.2"
  port                 = 11211
}


##kafka
resource "aws_kms_key" "kms" {
  description = "example"
}

resource "aws_cloudwatch_log_group" "test" {
  name = "msk_broker_logs1"
}

resource "aws_s3_bucket" "bucket" {
  bucket = "msk-broker-logs-bucket1"
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.bucket.id
  acl    = "private"
}

resource "aws_iam_role" "firehose_role" {
  name = "firehose_test_role1"

  assume_role_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
  {
    "Action": "sts:AssumeRole",
    "Principal": {
      "Service": "firehose.amazonaws.com"
    },
    "Effect": "Allow",
    "Sid": ""
  }
  ]
}
EOF
}

resource "aws_kinesis_firehose_delivery_stream" "test_stream" {
  name        = "terraform-kinesis-firehose-msk-broker-logs-stream"
  destination = "s3"

  s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.bucket.arn
  }

  tags = {
    LogDeliveryEnabled = "placeholder"
  }

  lifecycle {
    ignore_changes = [
      tags["LogDeliveryEnabled"],
    ]
  }
}

resource "aws_msk_cluster" "example" {
  cluster_name           = "example"
  kafka_version          = "3.2.0"
  number_of_broker_nodes = 2

  broker_node_group_info {
    instance_type = "kafka.m5.large"
    client_subnets = module.vpc.public_subnets
    storage_info {
      ebs_storage_info {
        volume_size = 1000
      }
    }
    security_groups = [module.vpc.default_security_group_id]
  }

  encryption_info {
    encryption_at_rest_kms_key_arn = aws_kms_key.kms.arn
  }

  open_monitoring {
    prometheus {
      jmx_exporter {
        enabled_in_broker = true
      }
      node_exporter {
        enabled_in_broker = true
      }
    }
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.test.name
      }
      firehose {
        enabled         = true
        delivery_stream = aws_kinesis_firehose_delivery_stream.test_stream.name
      }
      s3 {
        enabled = true
        bucket  = aws_s3_bucket.bucket.id
        prefix  = "logs/msk-"
      }
    }
  }

  tags = {
    foo = "bar"
  }
}

output "zookeeper_connect_string" {
  value = aws_msk_cluster.example.zookeeper_connect_string
}

output "bootstrap_brokers_tls" {
  description = "TLS connection host:port pairs"
  value       = aws_msk_cluster.example.bootstrap_brokers_tls
}