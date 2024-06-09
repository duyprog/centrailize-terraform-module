locals {
  len_public_subnets  = length(var.public_subnets)
  len_private_subnets = length(var.private_subnets)

  max_subnet_length = max(local.len_public_subnets, local.len_private_subnets)

  # Will note later 
  vpc_id = aws_vpc.this[0].id

  create_vpc = var.create_vpc
}

################################################################################
# VPC
################################################################################

resource "aws_vpc" "this" {
  count      = local.create_vpc ? 1 : 0
  cidr_block = var.cidr

  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(
    { "Name" = var.name },
    var.tags,
    var.vpc_tags
  )
}
################################################################################
# Internet Gateway
################################################################################

resource "aws_internet_gateway" "this" {
  count  = local.create_public_subnets && var.create_igw ? 1 : 0
  vpc_id = local.vpc_id
  tags = merge(
    { Name = "${var.name}-igw" },
    var.tags,
    var.igw_tags
  )
}

################################################################################
# Public Subnets
################################################################################

locals {
  create_public_subnets = local.create_vpc && local.len_public_subnets > 0
}

resource "aws_subnet" "public" {
  count             = local.create_public_subnets && local.len_public_subnets >= length(var.azs) ? local.len_public_subnets : 0
  availability_zone = element(var.azs, count.index)
  # https://developer.hashicorp.com/terraform/language/functions/element
  # https://developer.hashicorp.com/terraform/language/functions/concat
  cidr_block              = element(var.public_subnets, count.index)
  map_public_ip_on_launch = var.map_public_ip_on_launch
  vpc_id                  = local.vpc_id

  tags = merge(
    {
      Name = try(
        var.public_subnet_names[count.index],
        format("${var.name}-${var.public_subnet_suffix}-%s", element(var.azs, count.index))
      )
    },
    var.tags,
    var.public_subnet_tags
  )
}

resource "aws_route_table" "public" {
  count  = local.create_public_subnets ? 1 : 0
  vpc_id = local.vpc_id

  tags = merge(
    {
      Name = "${var.name}-public-route-table"
    },
    var.tags,
    var.public_route_table_tags
  )
}

resource "aws_route_table_association" "public" {
  count          = local.create_public_subnets ? local.len_public_subnets : 0
  route_table_id = element(aws_route_table.public[*].id, count.index)
  subnet_id      = element(aws_subnet.public[*].id, count.index)
}

resource "aws_route" "public_internet_gateway" {
  count                  = var.enable_nat_gateway ? 1 : 0
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.public[0].id
  gateway_id             = aws_internet_gateway.this[0].id
}

################################################################################
# Public Network ACLs
################################################################################

resource "aws_network_acl" "public" {
  count  = local.create_public_subnets ? 1 : 0
  vpc_id = local.vpc_id

  tags = merge(
    { Name = "${var.name}-public-acl-${count.index}" },
    var.tags,
    var.public_acl_tags
  )
}

resource "aws_network_acl_rule" "public_inbound" {
  count = local.create_public_subnets ? length(var.public_inbound_acl_rules) : 0

  network_acl_id = aws_network_acl.public[0].id

  egress      = false
  rule_number = var.public_inbound_acl_rules[count.index]["rule_number"]
  rule_action = var.public_inbound_acl_rules[count.index]["rule_action"]
  protocol    = var.public_inbound_acl_rules[count.index]["protocol"]
  # https://developer.hashicorp.com/terraform/language/functions/lookup
  from_port  = lookup(var.public_inbound_acl_rules[count.index], "from_port", null)
  to_port    = lookup(var.public_inbound_acl_rules[count.index], "to_port", null)
  cidr_block = lookup(var.public_inbound_acl_rules[count.index], "cidr_block", null)
}

resource "aws_network_acl_rule" "public_outbound" {
  count = local.create_public_subnets ? length(var.public_inbound_acl_rules) : 0

  network_acl_id = aws_network_acl.public[count.index].id

  egress      = true
  rule_number = var.public_outbound_acl_rules[count.index]["rule_number"]
  rule_action = var.public_outbound_acl_rules[count.index]["rule_action"]
  protocol    = var.public_inbound_acl_rules[count.index]["protocol"]
  from_port   = lookup(var.public_outbound_acl_rules[count.index], "from_port", null)
  to_port     = lookup(var.public_outbound_acl_rules[count.index], "to_port", null)
  cidr_block  = lookup(var.public_outbound_acl_rules[count.index], "cidr_block", null)
}

################################################################################
# Private Subnets
################################################################################

locals {
  create_private_subnets = var.create_vpc && local.len_private_subnets > 0
}

resource "aws_subnet" "private" {
  count             = local.create_private_subnets ? local.len_private_subnets : 0
  availability_zone = element(var.azs, count.index)
  cidr_block        = element(var.private_subnets, count.index)
  vpc_id            = local.vpc_id

  tags = merge(
    {
      Name = try(
        var.private_subnet_names[count.index],
        format("${var.name}-${var.private_subnet_suffix}-%s", element(var.azs, count.index))
      )
    },
    var.tags,
    var.private_subnet_tags
  )
}

resource "aws_route_table" "private" {
  count = local.create_private_subnets ? 1 : 0

  vpc_id = local.vpc_id

  tags = merge(
    {
      Name = "${var.name}-private-table"
    },
    var.tags,
    var.private_route_table_tags
  )
}

resource "aws_route_table_association" "private" {
  count = local.create_private_subnets ? local.len_private_subnets : 0

  route_table_id = element(
    aws_route_table.private[*].id,
    var.single_nat_gateway ? 0 : count.index
  )
  subnet_id = element(aws_subnet.private[*].id, count.index)

}

################################################################################
# Private Network ACLs
################################################################################

resource "aws_network_acl" "private" {
  count = local.create_private_subnets ? 1 : 0

  vpc_id = local.vpc_id

  tags = merge(
    { Name = "${var.name}-private-acl-${count.index}" },
    var.tags,
    var.private_acl_tags
  )
}

resource "aws_network_acl_rule" "private_inbound" {
  count = local.create_private_subnets ? length(var.private_inbound_acl_rules) : 0

  network_acl_id = aws_network_acl.private[0].id

  egress      = false
  rule_number = var.private_inbound_acl_rules[count.index]["rule_number"]
  rule_action = var.private_inbound_acl_rules[count.index]["rule_action"]
  protocol    = var.private_inbound_acl_rules[count.index]["protocol"]
  # https://developer.hashicorp.com/terraform/language/functions/lookup
  from_port  = lookup(var.private_inbound_acl_rules[count.index], "from_port", null)
  to_port    = lookup(var.private_inbound_acl_rules[count.index], "to_port", null)
  cidr_block = lookup(var.private_inbound_acl_rules[count.index], "cidr_block", null)
}

resource "aws_network_acl_rule" "private_outbound" {
  count = local.create_private_subnets ? length(var.private_inbound_acl_rules) : 0

  network_acl_id = aws_network_acl.private[count.index].id

  egress      = true
  rule_number = var.private_outbound_acl_rules[count.index]["rule_number"]
  rule_action = var.private_outbound_acl_rules[count.index]["rule_action"]
  protocol    = var.private_inbound_acl_rules[count.index]["protocol"]
  from_port   = lookup(var.private_outbound_acl_rules[count.index], "from_port", null)
  to_port     = lookup(var.private_outbound_acl_rules[count.index], "to_port", null)
  cidr_block  = lookup(var.private_outbound_acl_rules[count.index], "cidr_block", null)
}

################################################################################
# NAT Gateway
################################################################################

locals {
  nat_gateway_count = var.single_nat_gateway ? 1 : var.one_nat_gateway_per_az ? length(var.azs) : local.max_subnet_length
}

resource "aws_eip" "nat" {
  count = local.create_vpc && var.enable_nat_gateway ? local.nat_gateway_count : 0

  domain = "vpc"
  tags = merge(
    { Name = "${var.name}-nat-epi-${count.index}" },
    var.tags
  )
}

resource "aws_nat_gateway" "this" {
  count = local.create_vpc && var.enable_nat_gateway ? local.nat_gateway_count : 0
  allocation_id = element(
    aws_eip.nat[*].id,
    var.single_nat_gateway ? 0 : count.index
  )
  subnet_id = element(
    aws_subnet.private[*].id,
    var.single_nat_gateway ? 0 : count.index
  )

  tags = merge(
    { Name = "${var.name}-nat-gw-${count.index}" },
    var.tags
  )

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route" "private_nat_gw" {
  count = local.create_vpc && var.enable_nat_gateway ? local.nat_gateway_count : 0

  route_table_id         = element(aws_route_table.private[*].id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.this[*].id, count.index)

  timeouts {
    create = "5m"
  }
}



