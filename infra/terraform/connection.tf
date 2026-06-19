###############################################################################
# BigQuery CLOUD_RESOURCE connection — `us.vertex`
#
# bigquery/02_ai_layer.sql references `stock-trading-498512.us.vertex`, a
# CLOUD_RESOURCE connection whose service account holds roles/aiplatform.user so
# the ops.text_embed / ops.gemini remote models can call Vertex AI.
#
# This connection ALREADY EXISTS. Import it (do not recreate):
#   terraform import google_bigquery_connection.vertex \
#     projects/stock-trading-498512/locations/us/connections/vertex
#
# Note: the import id uses lowercase location "us" (the connection resource path
# is lowercased), even though the connection's `location` attribute is "US".
#
# IAM REMINDER (not managed here): the connection's service account
# (output cloud_resource_service_account below) must keep roles/aiplatform.user at
# the project level, granted out-of-band per bigquery/02_ai_layer.sql. We do not
# manage that grant in this module to avoid fighting the existing setup; add a
# google_project_iam_member if you want it codified.
###############################################################################

resource "google_bigquery_connection" "vertex" {
  project       = var.project_id
  connection_id = "vertex"
  location      = var.region
  friendly_name = "vertex"
  description   = "CLOUD_RESOURCE connection for Vertex remote models (ops.text_embed, ops.gemini)."

  cloud_resource {}
}

output "vertex_connection_id" {
  description = "Full resource id of the Vertex BigQuery connection."
  value       = google_bigquery_connection.vertex.name
}

output "vertex_connection_service_account" {
  description = <<-EOT
    Service account auto-created for the CLOUD_RESOURCE connection. Grant it
    roles/aiplatform.user so the remote Vertex models work (see 02_ai_layer.sql).
  EOT
  value       = google_bigquery_connection.vertex.cloud_resource[0].service_account_id
}
