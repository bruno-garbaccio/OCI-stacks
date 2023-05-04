resource "oci_core_volume" "jupyter_volume" { 
  count = var.jupyter_block ? 1 : 0
  availability_domain = var.jupyter_ad
  compartment_id = var.targetCompartment
  display_name = "${local.jupyter_name}-jupyter-volume"
  
  size_in_gbs = var.jupyter_block_volume_size
  vpus_per_gb = split(".", var.jupyter_block_volume_performance)[0]
} 

resource "oci_core_volume_attachment" "jupyter_volume_attachment" { 
  count = var.jupyter_block ? 1 : 0 
  attachment_type = "iscsi"
  volume_id       = oci_core_volume.jupyter_volume[0].id
  instance_id     = oci_core_instance.jupyter.id
  display_name    = "${local.jupyter_name}-jupyter-volume-attachment"
  device          = "/dev/oracleoci/oraclevdb"
} 

resource "oci_resourcemanager_private_endpoint" "rms_private_endpoint" {
  count = var.private_deployment ? 1 : 0
  compartment_id = var.targetCompartment
  display_name   = "rms_private_endpoint"
  description    = "rms_private_endpoint_description"
  vcn_id         = local.vcn_id
  subnet_id      = local.subnet_id
}

resource "oci_core_instance" "jupyter" {
  depends_on          = [local.jupyter_subnet]
  availability_domain = var.jupyter_ad
  compartment_id      = var.targetCompartment
  shape               = var.jupyter_shape

  dynamic "shape_config" {
    for_each = local.is_jupyter_flex_shape
      content {
        ocpus = shape_config.value
        memory_in_gbs = var.jupyter_custom_memory ? var.jupyter_memory : 16 * shape_config.value
      }
  }
  agent_config {
    is_management_disabled = true
    }
  display_name        = "${local.jupyter_name}-jupyter"

  freeform_tags = {
    "cluster_name" = local.jupyter_name
    "parent_cluster" = local.jupyter_name
  }

  metadata = {
    ssh_authorized_keys = "${var.ssh_key}\n${tls_private_key.ssh.public_key_openssh}"
    user_data           = base64encode(data.template_file.jupyter_config.rendered)
  }
  source_details {
    source_id = var.unsupported_jupyter_image
    boot_volume_size_in_gbs = var.jupyter_boot_volume_size
    source_type = "image"
  }

  create_vnic_details {
    subnet_id = local.jupyter_subnet_id
    assign_public_ip = local.jupyter_bool_ip
  }
} 

resource "null_resource" "jupyter" { 
  depends_on = [oci_core_instance.jupyter, oci_core_volume_attachment.jupyter_volume_attachment ] 
  triggers = { 
    jupyter = oci_core_instance.jupyter.id
  } 

  provisioner "remote-exec" {
    inline = [
      "#!/bin/bash",
      "sudo mkdir -p /opt/oci-hpc",      
      "sudo chown ${var.jupyter_username}:${var.jupyter_username} /opt/oci-hpc/",
      "mkdir -p /opt/oci-hpc/bin",
      "mkdir -p /opt/oci-hpc/playbooks",
      "mkdir -p /opt/oci-hpc/logs",
      "mkdir -p /opt/oci-hpc/samples"
      ]
    connection {
      host        = local.host
      type        = "ssh"
      user        = var.jupyter_username
      private_key = tls_private_key.ssh.private_key_pem
    }
  }
  provisioner "file" {
    source        = "playbooks"
    destination   = "/opt/oci-hpc/"
    connection {
      host        = local.host
      type        = "ssh"
      user        = var.jupyter_username
      private_key = tls_private_key.ssh.private_key_pem
    }
  }


  provisioner "file" {
    source      = "bin"
    destination = "/opt/oci-hpc/"
    connection {
      host        = local.host
      type        = "ssh"
      user        = var.jupyter_username
      private_key = tls_private_key.ssh.private_key_pem
    }
  }
  provisioner "file" {
    source      = "samples"
    destination = "/opt/oci-hpc/"
    connection {
      host        = local.host
      type        = "ssh"
      user        = var.jupyter_username
      private_key = tls_private_key.ssh.private_key_pem
    }
  }

  provisioner "file" { 
    content        = templatefile("${path.module}/configure.tpl", { 
      configure = var.configure
    })
    destination   = "/tmp/configure.conf"
    connection {
      host        = local.host
      type        = "ssh"
      user        = var.jupyter_username
      private_key = tls_private_key.ssh.private_key_pem
    }
  }

  provisioner "file" {
    content     = tls_private_key.ssh.private_key_pem
    destination = "/home/${var.jupyter_username}/.ssh/cluster.key"
    connection {
      host        = local.host
      type        = "ssh"
      user        = var.jupyter_username
      private_key = tls_private_key.ssh.private_key_pem
    }
  }


  provisioner "remote-exec" {
    inline = [
      "#!/bin/bash",
      "chmod 600 /home/${var.jupyter_username}/.ssh/cluster.key",
      "cp /home/${var.jupyter_username}/.ssh/cluster.key /home/${var.jupyter_username}/.ssh/id_rsa",
      "chmod a+x /opt/oci-hpc/bin/*.sh",
      "timeout --foreground 60m /opt/oci-hpc/bin/jupyter.sh"
      ]
    connection {
      host        = local.host
      type        = "ssh"
      user        = var.jupyter_username
      private_key = tls_private_key.ssh.private_key_pem
    }
  }
}
resource "null_resource" "cluster" { 
  depends_on = [null_resource.jupyter, oci_core_instance.jupyter, oci_core_volume_attachment.jupyter_volume_attachment ] 
  triggers = { 
    jupyter = oci_core_instance.jupyter.id
  } 
  provisioner "file" {
    content        = templatefile("${path.module}/inventory.tpl", {  
      jupyter_name = oci_core_instance.jupyter.display_name, 
      jupyter_ip = oci_core_instance.jupyter.private_ip,
      public_subnet = data.oci_core_subnet.public_subnet.cidr_block, 
      private_subnet = data.oci_core_subnet.private_subnet.cidr_block, 
      jupyter_block = var.jupyter_block, 
      jupyter_username = var.jupyter_username,
      inst_prin = var.inst_prin,
      region = var.region,
      tenancy_ocid = var.tenancy_ocid,
      api_fingerprint = var.api_fingerprint,
      api_user_ocid = var.api_user_ocid,
      host = local.host
      })

    destination   = "/opt/oci-hpc/playbooks/inventory"
    connection {
      host        = local.host
      type        = "ssh"
      user        = var.jupyter_username
      private_key = tls_private_key.ssh.private_key_pem
    }
  }

  provisioner "remote-exec" {
    inline = [
      "#!/bin/bash",
      "timeout 2h /opt/oci-hpc/bin/configure.sh | tee /opt/oci-hpc/logs/initial_configure.log",
      "exit_code=$${PIPESTATUS[0]}",
      "exit $exit_code"     ]
    connection {
      host        = local.host
      type        = "ssh"
      user        = var.jupyter_username
      private_key = tls_private_key.ssh.private_key_pem
    }
  }
}
