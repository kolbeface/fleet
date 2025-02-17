variable "ecs_cluster" {
  type        = string
  description = "The name of the ECS cluster to use"
  nullable    = false
}

variable "vpc_id" {
  type    = string
  default = null
}

variable "fleet_config" {
  type = object({
    mem                          = optional(number, 4096)
    cpu                          = optional(number, 512)
    image                        = optional(string, "fleetdm/fleet:v4.31.1")
    family                       = optional(string, "fleet-kolbe")
    sidecars                     = optional(list(any), [])
    depends_on                   = optional(list(any), [])
    mount_points                 = optional(list(any), [])
    volumes                      = optional(list(any), [])
    extra_environment_variables  = optional(map(string), {})
    extra_iam_policies           = optional(list(string), [])
    extra_execution_iam_policies = optional(list(string), [])
    extra_secrets                = optional(map(string), {})
    security_groups              = optional(list(string), null)
    security_group_name          = optional(string, "fleet-kolbe")
    iam_role_arn                 = optional(string, null)
    service = optional(object({
      name = optional(string, "fleet-kolbe")
      }), {
      name = "fleet-kolbe"
    })
    database = object({
      password_secret_arn = string
      user                = string
      database            = string
      address             = string
      rr_address          = optional(string, null)
    })
    redis = object({
      address = string
      use_tls = optional(bool, true)
    })
    awslogs = optional(object({
      name      = optional(string, null)
      region    = optional(string, null)
      create    = optional(bool, true)
      prefix    = optional(string, "fleet-kolbe")
      retention = optional(number, 5)
      }), {
      name      = null
      region    = null
      prefix    = "fleet-kolbe"
      retention = 5
    })
    loadbalancer = object({
      arn = string
    })
    networking = object({
      subnets         = list(string)
      security_groups = optional(list(string), null)
    })
    autoscaling = optional(object({
      max_capacity                 = optional(number, 5)
      min_capacity                 = optional(number, 1)
      memory_tracking_target_value = optional(number, 80)
      cpu_tracking_target_value    = optional(number, 80)
      }), {
      max_capacity                 = 5
      min_capacity                 = 1
      memory_tracking_target_value = 80
      cpu_tracking_target_value    = 80
    })
    iam = optional(object({
      role = optional(object({
        name        = optional(string, "fleet-role-kolbe")
        policy_name = optional(string, "fleet-kolbe-iam-policy")
        }), {
        name        = "fleet-role-kolbe"
        policy_name = "fleet-kolbe-iam-policy"
      })
      execution = optional(object({
        name        = optional(string, "fleet-execution-role-kolbe")
        policy_name = optional(string, "fleet-execution-role-kolbe")
        }), {
        name        = "fleet-execution-role-kolbe"
        policy_name = "fleet-iam-policy-execution-kolbe"
      })
      }), {
      name = "fleetdm-execution-role-kolbe"
    })
  })
  default = {
    mem                          = 512
    cpu                          = 256
    image                        = "fleetdm/fleet:v4.31.1"
    family                       = "fleet-kolbe"
    sidecars                     = []
    depends_on                   = []
    mount_points                 = []
    volumes                      = []
    extra_environment_variables  = {}
    extra_iam_policies           = []
    extra_execution_iam_policies = []
    extra_secrets                = {}
    security_groups              = null
    security_group_name          = "fleet-kolbe"
    iam_role_arn                 = null
    service = {
      name = "fleet-kolbe"
    }
    database = {
      password_secret_arn = null
      user                = null
      database            = null
      address             = null
      rr_address          = null
    }
    redis = {
      address = null
      use_tls = true
    }
    awslogs = {
      name      = null
      region    = null
      create    = true
      prefix    = "fleet-kolbe"
      retention = 5
    }
    loadbalancer = {
      arn = null
    }
    networking = {
      subnets         = null
      security_groups = null
    }
    autoscaling = {
      max_capacity                 = 5
      min_capacity                 = 1
      memory_tracking_target_value = 80
      cpu_tracking_target_value    = 80
    }
    iam = {
      role = {
        name        = "fleet-role-kolbe"
        policy_name = "fleet-kolbe-iam-policy"
      }
      execution = {
        name        = "fleet-execution-role"
        policy_name = "fleet-iam-policy-execution"
      }
    }
  }
  description = "The configuration object for Fleet itself. Fields that default to null will have their respective resources created if not specified."
  nullable    = false
}

variable "migration_config" {
  type = object({
    mem = number
    cpu = number
  })
  default = {
    mem = 2048
    cpu = 1024
  }
  description = "The configuration object for Fleet's migration task."
  nullable    = false
}
