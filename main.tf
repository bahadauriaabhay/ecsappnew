module "network" {
  source               = "./modules/network"
}
module "ecs" {
  source               = "./modules/ecs"
  asg_arn              = module.asg.asg_arn
  name                 = "demo1"
  vpc_id               = module.network.vpcid
  public_sg            = [module.sgALB.sgid]  
  public_sub           = [module.network.public_subnet_ids1,module.network.public_subnet_ids2]   
  on_demand_percentage = 0
  asg_min              = 1
  asg_max              = 3
  desired_capacity     = 1
  asg_target_capacity  = 80
  imageURI             = "895249166333.dkr.ecr.us-east-1.amazonaws.com/myimages:latest"
  container_cpu        = 100
  container_memory     = 512
  containerPort        = 8090
  hostPort             = 8090
  ssm_variables        = {"DB_ENDPOINT":module.rds.ssm_parameter_rds_endpoint, "DB_NAME": module.rds.ssm_parameter_rds_dbname,"DB_USER": module.rds.ssm_parameter_rds_user, "DB_PASS":module.rds.ssm_parameter_rds_password }
  
  path = "/swagger-ui.html"
  port = 8090
}

module "sg" {
  source              = "./modules/sg"
  name                = "ecs" 
  sg_cidr             = [module.network.cidr_block]
  sg_vpc_id           = module.network.vpcid
  from_port           = 8090
  to_port             = 8091
#  port                = 80
    
}

  module "sgALB" {
  source              = "./modules/sg"
  name                = "ecs2" 
  sg_cidr             = ["0.0.0.0/0"]
  sg_vpc_id           = module.network.vpcid
  from_port           = 80
  to_port             = 80
#  port                = 80
}

  module "sgRDS" {
  source              = "./modules/sg"
  name                = "ecs3" 
  sg_cidr             = ["0.0.0.0/0"]
  sg_vpc_id           = module.network.vpcid
  from_port           = 3306
  to_port             = 3306
}

module "asg" {
  source              = "./modules/asg"
  name                = "demo1"
  asg_max             = 1
  asg_min             = 1
  health_check_type   = "ELB"
  desired_capacity    = 1
  force_delete        = "true"
  instance_types      = "t2.micro"
  asg_sg              = [module.sg.sgid] 
  vpc_zone_id         = [module.network.private_subnet_ids1,module.network.private_subnet_ids2]

}   

module "rds" {
  source               = "./modules/rds"
  allocated_storage    = 10
  db_name              = "database23"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  username             = "database23"

  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  db_subnet_group_name = module.network.aws_db_subnet_group-default
  vpc_security_group_ids = [module.sgRDS.sgid]
}