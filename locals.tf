locals {
  names = var.disable_naming_conventions ? merge(
    {
      business_unit     = var.metadata.business_unit
      environment       = var.metadata.environment
      location          = var.resource_group.location
      market            = var.metadata.market
      subscription_type = var.metadata.subscription_type
    },
    var.metadata.product_group != "" ? { product_group = var.metadata.product_group } : {},
    var.metadata.product_name != "" ? { product_name = var.metadata.product_name } : {},
    var.metadata.resource_group_type != "" ? { resource_group_type = var.metadata.resource_group_type } : {}
  ) : module.metadata.names

  tags = var.disable_naming_conventions ? merge(var.tags, { "admin" = var.admin.name, "email" = var.admin.email }) : merge(module.metadata.tags, { "admin" = var.admin.name, "email" = var.admin.email }, try(var.tags))

  cluster_name = "${local.names.resource_group_type}-${local.names.product_name}-terraform-${local.names.location}-${var.admin.name}-${terraform.workspace}"

  resource_group = module.resource_group

  aks_private_subnet_id = can(var.storage.storage_account.name) ? var.virtual_network.aks_private_subnet_id : module.virtual_network.aks["hpcc"].subnets.private.id
  aks_public_subnet_id  = can(var.storage.storage_account.name) ? var.virtual_network.aks_public_subnet_id : module.virtual_network.aks["hpcc"].subnets.public.id
  aks_route_table_id    = can(var.storage.storage_account.name) ? var.virtual_network.aks_route_table_id : module.virtual_network.aks["hpcc"].route_table_id

  hpcc_repository    = "https://github.com/hpcc-systems/helm-chart/raw/master/docs/hpcc-${var.hpcc.version}.tgz"
  storage_repository = "https://github.com/hpcc-systems/helm-chart/raw/master/docs/hpcc-azurefile-0.1.0.tgz"
  elk_repository     = "https://github.com/hpcc-systems/helm-chart/raw/master/docs/elastic4hpcclogs-1.0.0.tgz"

  hpcc_chart    = can(var.hpcc.chart) ? var.hpcc.chart : local.hpcc_repository
  storage_chart = can(var.storage.chart) ? var.storage.chart : local.storage_repository
  elk_chart     = can(var.elk.chart) ? var.elk.chart : local.elk_repository

  az_command = try("az aks get-credentials --name ${module.kubernetes.name} --resource-group ${local.resource_group.name} --overwrite", "")
  web_urls   = { auto_launch_eclwatch = "http://$(kubectl get svc --field-selector metadata.name=eclwatch | awk 'NR==2 {print $4}'):8010" }

  is_windows_os = substr(pathexpand("~"), 0, 1) == "/" ? false : true
}
