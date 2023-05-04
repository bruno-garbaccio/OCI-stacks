# Stack to create an Jupyter notebook an a GPU VM. 

This stack deploys a GPU VM in a new VCN. JupyterLab is installed in a 
virtual conda environment (tf) and listens to port 8888. In addition,
the following python packages are installed in teh virtual environment "tf":

* python=3.9
* cudatoolkit=11.2.2
* cudnn=8.1.0
* tensorflow
* matplotlib
* jupyterlab

The full url is available in the "outputs" of the job execution in Oracle
Resource Manager.

The Jupyter notebook is executed as a service.To get the full url in case of a reboot, simply run:

```
ssh -y -i /path/private_key -o StrictHostKeyChecking=no opc@public_ip /opt/oci-hpc/bin/json.sh
```

## Supported OS: 
This stack is dedicated for a GPU VM deployment. It has been tested on A10
VM with a OL8 Gen2-GPU image.
List of all images per region: https://docs.oracle.com/en-us/iaas/images/ Default is set to FRA on a Gen2-GPU image for OL8


