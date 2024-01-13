locals {
  create_vpc = var.create_vpc 
  len_public_subnets = length(var.public_subnets)
}
resource "aws_vpc" "this" {
  count = local.create_vpc ? 1 : 0
  cidr_block = var.cidr
  enable_dns_hostnames = var.enable_dns_hostname
  enable_dns_support = var.enable_dns_support
  tags = merge(
    {"Name": var.name}, 
    var.vpc_tags 
  )
}

# Public Subnet 

locals {
  create_public_subnets = local.create_vpc && local.len_public_subnets > 0
}

resource "aws_subnet" "public" {
  count = local.create_public_subnets
}