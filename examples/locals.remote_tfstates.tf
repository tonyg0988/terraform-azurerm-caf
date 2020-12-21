data "terraform_remote_state" "remote" {
  for_each = try(var.landingzone.tfstates, {})

  backend = var.landingzone.backend_type
  config = {
    storage_account_name = local.landingzone[try(each.value.level, "current")].storage_account_name
    container_name       = local.landingzone[try(each.value.level, "current")].container_name
    resource_group_name  = local.landingzone[try(each.value.level, "current")].resource_group_name
    subscription_id      = var.tfstate_subscription_id
    key                  = each.value.tfstate
  }
}

locals {
  landingzone = {
    current = {
      storage_account_name = var.tfstate_storage_account_name
      container_name       = var.tfstate_container_name
      resource_group_name  = var.tfstate_resource_group_name
    }
    lower = {
      storage_account_name = var.lower_storage_account_name
      container_name       = var.lower_container_name
      resource_group_name  = var.lower_resource_group_name
    }
  }

  remote = {
    diagnostics = {
      # Get the diagnostics settings of services to create
      diagnostic_event_hub_namespaces = var.diagnostic_event_hub_namespaces
      diagnostic_log_analytics        = var.diagnostic_log_analytics
      diagnostic_storage_accounts     = var.diagnostic_storage_accounts

      # Combine the diagnostics definitions
      diagnostics_definition = merge(data.terraform_remote_state.remote[var.landingzone.global_settings_key].outputs.diagnostics.diagnostics_definition, var.diagnostics_definition)
      diagnostics_destinations = {
        event_hub_namespaces = merge(
          try(data.terraform_remote_state.remote[var.landingzone.global_settings_key].outputs.diagnostics.diagnostics_destinations.event_hub_namespaces, {}),
          try(var.diagnostics_destinations.event_hub_namespaces, {})
        )
        log_analytics = merge(
          try(data.terraform_remote_state.remote[var.landingzone.global_settings_key].outputs.diagnostics.diagnostics_destinations.log_analytics, {}),
          try(var.diagnostics_destinations.log_analytics, {})
        )
        storage = merge(
          try(data.terraform_remote_state.remote[var.landingzone.global_settings_key].outputs.diagnostics.diagnostics_destinations.storage, {}),
          try(var.diagnostics_destinations.storage, {})
        )
      }
      # Get the remote existing diagnostics objects
      storage_accounts     = data.terraform_remote_state.remote[var.landingzone.global_settings_key].outputs.diagnostics.storage_accounts
      log_analytics        = data.terraform_remote_state.remote[var.landingzone.global_settings_key].outputs.diagnostics.log_analytics
      event_hub_namespaces = data.terraform_remote_state.remote[var.landingzone.global_settings_key].outputs.diagnostics.event_hub_namespaces
    }

    keyvaults = {
      for key, value in try(var.landingzone.tfstates, {}) : key => merge(try(data.terraform_remote_state.remote[key].outputs.keyvaults[key], {}))
    }
  }
}