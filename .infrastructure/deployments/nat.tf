module "fck-nat" {
  source = "RaJiska/fck-nat/aws"

  name      = "${local.name}-fck-nat"
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnets[0]

  update_route_tables = true
  route_tables_ids = { for index, az in local.vpc_availability_zones :
    "${local.name}-private-${az}" => module.vpc.private_route_table_ids[index]
  }
}
