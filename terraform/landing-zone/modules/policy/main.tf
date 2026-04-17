# Tagging policy initiative
resource "azurerm_policy_definition" "require_tags" {
  for_each     = toset(["Environment", "CostCenter", "Owner", "CreatedBy"])
  name         = "require-tag-${lower(each.key)}"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Require tag: ${each.key}"

  policy_rule = jsonencode({
    if = {
      field = "tags['${each.key}']"
      exists = "false"
    }
    then = {
      effect = "deny"
    }
  })
}

resource "azurerm_subscription_policy_assignment" "require_tags" {
  for_each             = azurerm_policy_definition.require_tags
  name                 = "assign-${each.value.name}"
  display_name         = each.value.display_name
  policy_definition_id = each.value.id
  subscription_id      = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
}

# Audit Diagnostic Settings policy
resource "azurerm_policy_assignment" "audit_diagnostics" {
  name                 = "audit-diagnostic-settings"
  display_name         = "Audit resources without diagnostic settings"
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/7f89b1eb-583c-429a-8828-af049802c1d9"
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
}

data "azurerm_client_config" "current" {}
