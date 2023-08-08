resource "oci_kms_vault" "ssh_vault" {
    count          = var.web_submission_portal && !var.use_existing_vault ? 1 : 0
    compartment_id = var.targetCompartment
    display_name = "${local.cluster_name}-vault"
    vault_type = "DEFAULT"
}

resource "oci_kms_key" "master_key" {
    count          = var.web_submission_portal && !var.use_existing_master_key ? 1 : 0
    compartment_id = var.targetCompartment
    display_name = "${local.cluster_name}-master-key"
    key_shape {
        #Required
        algorithm = "AES"
        length = "32"

    }
    management_endpoint = data.oci_kms_vault.vault[0].management_endpoint
}

resource "oci_vault_secret" "generate_secret" {
    count          = var.web_submission_portal ? 1 : 0
    compartment_id = var.targetCompartment
    secret_content {
        #Required
        content = base64encode(tls_private_key.ssh.private_key_pem)
        content_type = "BASE64"
    }
    secret_name = "${local.cluster_name}-secret"
    vault_id = data.oci_kms_vault.vault[0].id
    key_id = data.oci_kms_key.master_key[0].id
    secret_rules {
        #Required
        rule_type = "SECRET_REUSE_RULE"
        is_enforced_on_deleted_secret_versions = "true"
    }
}



resource "oci_identity_auth_token" "auth_token" {
    count          = var.web_submission_portal && !var.use_existing_auth_token ? 1 : 0
    description = "${local.cluster_name}-token"
    user_id = var.current_user_ocid
}


resource "oci_artifacts_container_repository" "container_repository" {
    count          = var.web_submission_portal && !var.use_existing_registry ? 1 : 0
    compartment_id = var.targetCompartment
    display_name = "${local.cluster_name}-registry"
}


resource "oci_functions_application" "fn_application" {
    count          = var.web_submission_portal ? 1 : 0
	  compartment_id = var.targetCompartment
    display_name = "${local.cluster_name}-app"
    subnet_ids = [local.bastion_subnet_id, local.subnet_id ]
}

//resource "time_sleep" "wait_for_registry_to_be_ready" {
// count          = var.web_submission_portal ? 1 : 0
//  depends_on = [oci_identity_auth_token.auth_token]
//  create_duration = "30s"
//}

resource "null_resource" "Login2OCIR" {
  count          = var.web_submission_portal ? 1 : 0
  depends_on = [oci_functions_application.fn_application, local.registry_id, local.auth_token]

  provisioner "local-exec" {
    command     = "echo '${local.auth_token}' | docker login -u '${local.ocir_namespace}/${data.oci_identity_user.user.name}' ${local.region_key}.ocir.io --password-stdin"
    working_dir = "${path.module}/function/"
  } 
}


resource "null_resource" "function_Push2OCIR" {
  count          = var.web_submission_portal ? 1 : 0
  depends_on = [null_resource.Login2OCIR]

  provisioner "local-exec" {
    command     = "fn update context oracle.compartment-id ${var.targetCompartment}"
    working_dir = "${path.module}/function/"
  }

  provisioner "local-exec" {
    command     = "fn build --verbose"
    working_dir = "${path.module}/function/"
  }

  provisioner "local-exec" {
    command     = "image=$(docker images | grep oci-get-slurm-job-python | awk -F ' ' '{print $3}') ; docker tag $image ${local.region_key}.ocir.io/${local.ocir_namespace}/${data.oci_artifacts_container_repository.container_repo[0].display_name}:latest"
    working_dir = "${path.module}/function/"
  }

  provisioner "local-exec" {
    command     = "docker push ${local.region_key}.ocir.io/${local.ocir_namespace}/${data.oci_artifacts_container_repository.container_repo[0].display_name}:latest"
    working_dir = "${path.module}/function/"
  }  
}

resource "oci_functions_function" "function" {
    count          = var.web_submission_portal ? 1 : 0
	  depends_on = [null_resource.function_Push2OCIR]
    application_id = oci_functions_application.fn_application[0].id
    display_name = "oci-get-slurm-job-python"
    image = "${local.region_key}.ocir.io/${local.ocir_namespace}/${data.oci_artifacts_container_repository.container_repo[0].display_name}:latest"
    memory_in_mbs = "256" 
    config = { 
      "REGION" : "${var.region}"
    }
}

resource "oci_apigateway_gateway" "generated_oci_apigateway_gateway" {
	count          = !var.use_existing_api_gw && var.web_submission_portal ? 1 : 0	
	compartment_id = var.targetCompartment
	endpoint_type = local.type_api_gateway
	response_cache_details {
		type = "NONE"
	}
	subnet_id = local.bastion_subnet_id
  display_name = "${local.cluster_name}-api-gw"
}

resource "oci_apigateway_deployment" "generated_oci_apigateway_deployment" {
	count          = var.web_submission_portal ? 1 : 0
	compartment_id = var.targetCompartment
	display_name = "${local.cluster_name}-deployment"
	gateway_id = local.api_gw_id
	path_prefix = "/${local.cluster_name}-oci-slurm"
	specification {
		logging_policies {
			execution_log {
				is_enabled = "true"
				log_level = "INFO"
			}
		}
		request_policies {
			cors {
				allowed_headers = ["authorization", "content-type", "x-appbuilder-client-id"]
				allowed_methods = ["*"]
				allowed_origins = ["*"]
				is_allow_credentials_enabled = "true"
				max_age_in_seconds = "0"
			}			
			mutual_tls {
				is_verified_certificate_required = "false"
			}
		}
		routes {
			backend {
				function_id = oci_functions_function.function[0].id
				type = "ORACLE_FUNCTIONS_BACKEND"
			}
			logging_policies {
			}
			methods = ["GET", "POST"]
			path = "/list_jobs"
		}
		routes {
			backend {
				function_id = oci_functions_function.function[0].id
				type = "ORACLE_FUNCTIONS_BACKEND"
			}
			logging_policies {
			}
			methods = ["GET", "POST"]
			path = "/cancel_job"
		}
		routes {
			backend {
				function_id = oci_functions_function.function[0].id
				type = "ORACLE_FUNCTIONS_BACKEND"
			}
			logging_policies {
			}
			methods = ["GET", "POST"]
			path = "/submit_job"
		}
		routes {
			backend {
				function_id = oci_functions_function.function[0].id
				type = "ORACLE_FUNCTIONS_BACKEND"
			}
			logging_policies {
			}
			methods = ["GET", "POST"]
			path = "/list_nodes"
		}
		routes {
			backend {
				function_id = oci_functions_function.function[0].id
				type = "ORACLE_FUNCTIONS_BACKEND"
			}
			logging_policies {
			}
			methods = ["GET", "POST"]
			path = "/get_features"
		}
		routes {
			backend {
				function_id = oci_functions_function.function[0].id
				type = "ORACLE_FUNCTIONS_BACKEND"
			}
			logging_policies {
			}
			methods = ["GET", "POST"]
			path = "/get_log"
		}
	}
}
resource "null_resource" "web_portal_bastion" { 
  count          = var.web_submission_portal ? 1 : 0
  depends_on = [oci_core_instance.bastion, oci_core_volume_attachment.bastion_volume_attachment ] 
  provisioner "remote-exec" {
    inline = [
      "#!/bin/bash",
      "sudo mkdir -p /home/${var.bastion_username}/web-portal",
      "sudo chown ${var.bastion_username}:${var.bastion_username} /home/${var.bastion_username}/web-portal"
      ]
    connection {
      host        = local.host
      type        = "ssh"
      user        = var.bastion_username
      private_key = tls_private_key.ssh.private_key_pem
    }
  }  
}  

resource "local_file" "updateWebAppvariables" {
  count          = var.web_submission_portal ? 1 : 0	
  content  = templatefile("${path.module}/web-portal/variables.json.tpl", {
    user = var.bastion_username,
    secret_ocid = oci_vault_secret.generate_secret[0].id,
    public_ip = local.host,
    searchdate = formatdate("YYYY-MM-DD",timestamp())
  })
  filename = "${path.module}/web-portal/slurmFrontend/webApps/slurmfrontend/resources/variables.json"  
}

resource "local_file" "updateWebAppEndpoint" {
  count          = var.web_submission_portal ? 1 : 0	
  content  = templatefile("${path.module}/web-portal/catalog.json.tpl", {
    endpoint = oci_apigateway_deployment.generated_oci_apigateway_deployment[0].endpoint
  })
  filename = "${path.module}/web-portal/slurmFrontend/services/catalog.json"  
}

resource "null_resource" "ziparchive" {
  count          = var.web_submission_portal ? 1 : 0	
  depends_on = [local_file.updateWebAppvariables, local_file.updateWebAppEndpoint ] 
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = "cd web-portal && zip -r ../${local.cluster_name}.zip slurmFrontend"
  }  
}

resource "null_resource" "config_on_bastion" { 
  count          = var.web_submission_portal ? 1 : 0
  depends_on = [null_resource.cluster, null_resource.ziparchive ] 
  provisioner "file" {
    source      = "${local.cluster_name}.zip"
    destination = "/opt/oci-hpc/samples/${local.cluster_name}-slurm-app.zip"
    connection {
      host        = local.host
      type        = "ssh"
      user        = var.bastion_username
      private_key = tls_private_key.ssh.private_key_pem
    }
  }
} 


resource "oci_objectstorage_bucket" "bucket" {
    count          = var.web_submission_portal && var.build_app ? 1 : 0
    compartment_id = var.targetCompartment
    name = local.cluster_name
    namespace = local.ocir_namespace  
  provisioner "local-exec" {
    when = destroy
    command = "oci os object bulk-delete -bn ${self.name} --force"
  }
}


resource "local_file" "updateBuildScript" {
  count          = var.web_submission_portal && var.build_app ? 1 : 0
  depends_on = [null_resource.ziparchive, oci_objectstorage_bucket.bucket ]	
  content  = templatefile("${path.module}/web-portal/buildAndDeploy.sh.tpl", {
    endpoint = oci_apigateway_deployment.generated_oci_apigateway_deployment[0].endpoint,
    user = var.bastion_username,
    secret_ocid = oci_vault_secret.generate_secret[0].id,
    public_ip = local.host,
    searchdate = formatdate("YYYY-MM-DD",timestamp()),
    namespace =  local.ocir_namespace,
    bucket =    oci_objectstorage_bucket.bucket[0].name

  })
  filename = "${path.module}/web-portal/slurmFrontend/buildAndDeploy.sh"  
}




resource "null_resource" "deploy" {
  count          = var.web_submission_portal && var.build_app ? 1 : 0	
  depends_on = [local_file.updateBuildScript] 
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = "cd web-portal/slurmFrontend && chmod a+x buildAndDeploy.sh && ./buildAndDeploy.sh"
  }  
}

resource "oci_objectstorage_preauthrequest" "preauthenticated_request" {
    count          = var.web_submission_portal && var.build_app ? 1 : 0	
    depends_on = [null_resource.deploy] 
    access_type = "AnyObjectRead"
    bucket = oci_objectstorage_bucket.bucket[0].name
    name = local.cluster_name
    namespace = local.ocir_namespace
    time_expires = timeadd(timestamp(), "8760h")

    #Optional
    bucket_listing_action = "ListObjects"
}

