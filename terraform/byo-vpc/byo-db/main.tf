module "ecs" {
  source      = "./byo-ecs"
  ecs_cluster = module.cluster.cluster_name
  fleet_config = merge(var.fleet_config, {
    loadbalancer = {
      arn = module.alb.target_group_arns[0]
    }
  })
  migration_config = var.migration_config
  vpc_id           = var.vpc_id
}

module "cluster" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "4.1.2"

  autoscaling_capacity_providers        = var.ecs_cluster.autoscaling_capacity_providers
  cluster_configuration                 = var.ecs_cluster.cluster_configuration
  cluster_name                          = var.ecs_cluster.cluster_name
  cluster_settings                      = var.ecs_cluster.cluster_settings
  create                                = var.ecs_cluster.create
  default_capacity_provider_use_fargate = var.ecs_cluster.default_capacity_provider_use_fargate
  fargate_capacity_providers            = var.ecs_cluster.fargate_capacity_providers
  tags                                  = var.ecs_cluster.tags
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "8.2.1"

  name = var.alb_config.name

  load_balancer_type = "application"

  vpc_id          = var.vpc_id
  subnets         = var.alb_config.subnets
  security_groups = concat(var.alb_config.security_groups, [aws_security_group.alb.id])
  access_logs     = var.alb_config.access_logs

  target_groups = [
    {
      name             = var.alb_config.name
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "ip"
      health_check = {
        path                = "/healthz"
        matcher             = "200"
        timeout             = 10
        interval            = 15
        healthy_threshold   = 5
        unhealthy_threshold = 5
      }
    }
  ]
  
  # Require TLS 1.2 as earlier versions are insecure
  listener_ssl_policy_default = "ELBSecurityPolicy-TLS-1-2-2017-01"

  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = var.alb_config.certificate_arn
      target_group_index = 0
    }
  ]

  http_tcp_listeners = [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  ]
}

resource "aws_lb_listener" "fleet" {
  load_balancer_arn = module.alb.lb_arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.alb_config.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = module.alb.target_group_arns[0]
  }
}

resource "aws_lb_listener_rule" "static" {
  listener_arn = aws_lb_listener.fleet.arn
  priority     = 1

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Error - Unauthorized"
      status_code  = "503"
    }
  }
    condition {
      path_pattern {
        values = ["/login"]
      }
  }
}

resource "aws_security_group" "alb" {
  #checkov:skip=CKV2_AWS_5:False positive
  vpc_id      = var.vpc_id
  description = "Fleet ALB Security Group"
  ingress {
    description      = "Ingress from all, its a public load balancer"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = var.alb_config.allowed_cidrs
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "For http to https redirect"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = var.alb_config.allowed_cidrs
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "Egress to all"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
