################################################################################
# VPC
################################################################################
variable "create_vpc" {
  description = "Controls if VPC should be created"
  type        = bool
  default     = true
}

variable "name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
  default     = ""
}

variable "cidr" {
  description = "The IPv4 CIDR block for the VPC. CIDR can be explicitly set or it can be devired from IPAM using `ipv4_netmask_length` & `ipv4_ipam_pool_id`"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "A list of availability zones names or ids in the region"
  type        = list(string)
  default     = []
}
# variable "secondary_cidr_blocks" {
#   description = "List of secondary CIDR blocks to associate with the VPC to extend the IP Address pool"
#   type        = list(string)
#   default     = []
# }

# variable "instance_tenancy" {
#   description = "A tenancy option for instances launched into the VPC"
#   type        = string
#   default     = "default"
# }


variable "enable_dns_hostnames" {
  description = "Should be true to enable DNS hostnames in VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Should be true to enable DNS support in VPC"
  type        = bool
  default     = true
}

variable "vpc_tags" {
  description = "Additional tags for the VPC"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

################################################################################
# Publiс Subnets
################################################################################

variable "public_subnets" {
  description = "A list of public subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "map_public_ip_on_launch" {
  description = "Specify true to indicate that instances launched into this subnet should be assigned a public ip address. Default is false"
  type        = bool
  default     = false
}

variable "public_subnet_names" {
  description = "Explicit values to use in the Name tag on public subnets. If empty, Name tags are generated"
  type        = list(string)
  default     = []
}

variable "public_subnet_suffix" {
  description = "Suffix to append to public subnets name"
  type        = string
  default     = "public"
}

variable "public_subnet_tags" {
  description = "Additional tags for public subnets"
  type        = map(string)
  default     = {}
}

variable "public_route_table_tags" {
  description = "Additional tags for public route tables"
  type        = map(string)
  default     = {}
}

################################################################################
# Public Network ACLs
################################################################################

variable "public_dedicated_network_acl" {
  description = "Whether to use dedicated network ACL (not default) and custom rules for public subnets"
  type        = bool
  default     = false
}

variable "public_inbound_acl_rules" {
  description = "Public subnets inbound network ACL"
  type        = list(map(string))
  default = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    }
  ]
}

variable "public_outbound_acl_rules" {
  description = "Public subnets outbound network ACLs"
  type        = list(map(string))
  default = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]
}

variable "public_acl_tags" {
  description = "Additional tags for the public subnets network ACL"
  type        = map(string)
  default     = {}
}

################################################################################
# Private Subnets
################################################################################
variable "private_subnets" {
  description = "A list of private subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "private_subnet_names" {
  description = "Explicit values to use in the Name tag on private subnets. If empty, Name tags are generated"
  type        = list(string)
  default     = []
}

variable "private_subnet_suffix" {
  description = "Suffix to append to private subnets name"
  type        = string
  default     = "private"
}

variable "private_subnet_tags" {
  description = "Additional tags for private subnets"
  type        = map(string)
  default     = {}
}

variable "private_route_table_tags" {
  description = "Additional tags for private route tables"
  type        = map(string)
  default     = {}
}

################################################################################
# Private Network ACLs
################################################################################

variable "private_dedicated_network_acl" {
  description = "Whether to use dedicated network ACL (not default) and custom rules for private subnets"
  type        = bool
  default     = false
}

variable "private_inbound_acl_rules" {
  description = "Private subnets inbound network ACLs"
  type        = list(map(string))
  default = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]
}

variable "private_outbound_acl_rules" {
  description = "Private subnets outbound network ACLs"
  type        = list(map(string))
  default = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]
}

variable "private_acl_tags" {
  description = "Additional tags for the private subnets network ACL"
  type        = map(string)
  default     = {}
}

################################################################################
# Internet Gateway
################################################################################

variable "create_igw" {
  description = "Controls if Internet Gateway is created for public subnets and the relate routes that connect them"
  type        = bool
  default     = true
}

variable "igw_tags" {
  description = "Additional tags for the Internet Gateway"
  type        = map(string)
  default     = {}
}

################################################################################
# NAT Gateway
################################################################################
variable "enable_nat_gateway" {
  description = "Controls if NAT Gateway is created for private subnets"
  type        = bool
  default     = false
}

variable "nat_gw_tags" {
  description = "Additional tags for the NAT Gateway"
  type        = map(string)
  default     = {}
}

variable "single_nat_gateway" {
  description = "Should be true if you want to provision a single NAT Gateway accross all of your private subnets"
  type        = bool
  default     = false
}

variable "one_nat_gateway_per_az" {
  description = "Should be true if you want only one NAT Gateway per availability zone, require `var.azs` to be set, and the number of `public subnet` created to be greater than or equal to the number of availability zones"
  type        = bool
  default     = false
}


