[jupyter]
${jupyter_name} ansible_host=${jupyter_ip} ansible_user=${jupyter_username} role=jupyter
[all:vars]
ansible_connection=ssh
public_subnet=${public_subnet} 
private_subnet=${private_subnet}
jupyter_block = ${jupyter_block} 
jupyter_username=${jupyter_username}
region= ${region}
tenancy_ocid = ${tenancy_ocid}
inst_prin = ${inst_prin}
api_fingerprint = ${api_fingerprint}
api_user_ocid = ${api_user_ocid}
host = ${host}

