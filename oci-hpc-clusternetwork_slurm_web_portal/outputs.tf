output "bastion" {
  value = local.host
}

output "private_ips" {
  value = join(" ", local.cluster_instances_ips)
}

output "backup" {
  value = var.slurm_ha ? local.host_backup : "No Slurm Backup Defined"
}

output "login" {
  value = var.login_node ? local.host_login : "No Login Node Defined"
}

output "Visual_Builder" {
	value = "If you selected 'Slurm web portal', please create a Visual Builder instance in OCI\n(Developer Services > Visual Builder > Visual Studio) \nImport the zip file that can be downloaded below"
}

output "api-endpoint"{
  value = var.web_submission_portal ? oci_apigateway_deployment.generated_oci_apigateway_deployment[0].endpoint : "No Web Portal"
}

output "scp-command"{
  value = var.web_submission_portal ? "scp -i <rsa_private_key> ${var.bastion_username}@${local.host}:/opt/oci-hpc/samples/${local.cluster_name}-slurm-app.zip <TARGET_LOCATION>" : "No Web Portal"
}

output "web-portal-url"{
  value = var.web_submission_portal && var.build_app ? "https://objectstorage.${var.region}.oraclecloud.com${oci_objectstorage_preauthrequest.preauthenticated_request[0].access_uri}index.html" : "No deployment on Object Storage"
}

