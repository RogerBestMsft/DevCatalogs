data "azuread_client_config" "Current" {}

data "azuread_application_published_app_ids" "well_known" {}

data "azuread_service_principal" "MSGraph" {
  application_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
} 