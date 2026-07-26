locals {
  name_prefix = "bluepeak-${var.environment}"
  common_tags = {
    Project     = "BluePeak"
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = "platform-team"
  }
}

module "network" {
  source = "../../modules/network"

  name_prefix        = local.name_prefix
  vpc_cidr           = var.vpc_cidr
  az_count           = var.az_count
  single_nat_gateway = var.single_nat_gateway
  tags               = local.common_tags
}

module "security" {
  source = "../../modules/security"

  name_prefix = local.name_prefix
  vpc_id      = module.network.vpc_id
  app_port    = var.app_port
  tags        = local.common_tags
}

module "rds" {
  source = "../../modules/rds"

  name_prefix          = local.name_prefix
  db_subnet_ids        = module.network.db_subnet_ids
  db_sg_id             = module.security.db_sg_id
  database_name        = var.database_name
  instance_class       = var.db_instance_class
  multi_az             = var.db_multi_az
  deletion_protection  = var.environment == "prod"
  tags                 = local.common_tags
}

module "alb" {
  source = "../../modules/alb"

  name_prefix                = local.name_prefix
  vpc_id                      = module.network.vpc_id
  public_subnet_ids           = module.network.public_subnet_ids
  alb_sg_id                   = module.security.alb_sg_id
  app_port                    = var.app_port
  certificate_arn             = var.certificate_arn
  enable_deletion_protection  = var.environment == "prod"
  tags                        = local.common_tags
}

module "waf" {
  source = "../../modules/waf"

  name_prefix = local.name_prefix
  alb_arn     = module.alb.alb_arn
  tags        = local.common_tags
}

module "ecs" {
  source = "../../modules/ecs"

  name_prefix              = local.name_prefix
  aws_region               = var.aws_region
  app_subnet_ids           = module.network.app_subnet_ids
  app_sg_id                = module.security.app_sg_id
  target_group_arn         = module.alb.target_group_arn
  alb_arn_suffix           = module.alb.alb_arn_suffix
  target_group_arn_suffix  = module.alb.target_group_arn_suffix
  db_secret_arn            = module.rds.secret_arn
  container_image          = var.container_image
  app_port                 = var.app_port
  desired_count            = var.ecs_desired_count
  min_capacity             = var.ecs_min_capacity
  max_capacity             = var.ecs_max_capacity
  tags                     = local.common_tags
}

module "monitoring" {
  source = "../../modules/monitoring"

  name_prefix               = local.name_prefix
  aws_region                = var.aws_region
  alert_email               = var.alert_email
  alb_arn_suffix            = module.alb.alb_arn_suffix
  target_group_arn_suffix   = module.alb.target_group_arn_suffix
  ecs_cluster_name          = module.ecs.cluster_name
  ecs_service_name          = module.ecs.service_name
  rds_instance_id           = module.rds.instance_id
  tags                      = local.common_tags
}
