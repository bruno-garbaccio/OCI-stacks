#
# oci-vault-get-secret-python version 1.0.
#
# Copyright (c) 2020 Oracle, Inc.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

import io
import json
import os
import oci
import paramiko
import logging
import hashlib
import subprocess
import yaml
import base64
import random
import string
from datetime import datetime
from fdk import response

ssh_key = "/tmp/id_rsa_func"


def get_text_secret(secret_ocid,ssh_key):
    #decrypted_secret_content = ""
    signer = oci.auth.signers.get_resource_principals_signer()
    client = oci.secrets.SecretsClient({}, signer=signer)
    secret_content = client.get_secret_bundle(secret_ocid).data.secret_bundle_content.content.encode('utf-8')
    decrypted_secret_content = base64.b64decode(secret_content).decode("utf-8")
    myfile = open(ssh_key, "w")
    myfile.write(decrypted_secret_content)
    myfile.close()
    out = subprocess.Popen(["chmod", "600", ssh_key], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    return (ssh_key)

def list_jobs(ssh_key, user, public_ip):  
    """
    Run squeue on bastion. Access via public IP. Return Json
    """  
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(public_ip, username=user,key_filename=ssh_key) ##### # Put IP here 
    stdin, stdout, stderr = ssh.exec_command('squeue -o "%i %P %j %u %T %M %D %f %R"')
    # JOBID PARTITION NAME USER STATE TIME NODES FEATURES NODELIST(REASON)
    out = stdout.readlines()
  
    squeue_list = []
    for line in out[1:]:
        line = line.split()
        squeue_list.append({"jobid": line[0], "partition": line[1], "name": line[2], "user": line[3], "state":line[4], "time": line[5], "num_node": line[6], "features": line[7], "nodelist_reason": " ".join(line[8:]) })
    
    temp = {"squeue": squeue_list}
    jsondict = json.dumps(temp)
    return (jsondict)

def cancel_job(ssh_key, user, public_ip, jobid_list):
    """
    Run scancel on bastion. Access via public IP. Return "success" or error message in json.
    jobid_list is a string. Can be one job ID,"jobid", or an array with space as separator "jobid1 jobid2"
    """  
    scancel = []
    jobids = jobid_list.strip().split(" ")

    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(public_ip, username=user,key_filename=ssh_key) ##### # Put IP here 

    for jobid in jobids:
        command = 'scancel %s -v' % (jobid)  # adapt job ID
        stdin, stdout, stderr = ssh.exec_command(command)
        out = stderr.readlines()
        if not "error" in out[-1].lower():
            temp = {"jobid": jobid, "scancel": "job %s killed succesfully" % (jobid)}
        else:
            temp = {"jobid": jobid, "scancel": out[-1].strip()}
        scancel.append(temp)

    jsondict = json.dumps(scancel)
    return (jsondict) 

def submit_job(ssh_key, user, public_ip, partition, constraint, jobname, nb_cpus, nb_nodes, nb_gpus, base64_message):
    """
    Run sbatch on bastion. Access via public IP. Return "success" or error message in json.
    Convert base64 job to string and write the job submission file in /tmp.
    Get the options of the job submission (queue, nb nodes...) and submit job.
    """  
    # decode base64 to ascii
    base64_bytes = base64_message.encode('utf-8')
    message_bytes = base64.b64decode(base64_bytes)
    message = message_bytes.decode('utf-8')
    # datetime object containing current date and time
    now = datetime.now()
    # generate filepath with random string and current date time in /tmp
    dt_string = now.strftime("%d%m%Y%H%M%S")
    print("date and time =", dt_string)
    letters = string.ascii_lowercase
    rdm_str = ''.join(random.choice(letters) for i in range(8)) # random string of 8 carachters
    filepath = '/tmp/%s-%s.sbatch' % (rdm_str,dt_string)
    # create submission options
    if "N/A" in nb_gpus:
        ntasks = str(int(nb_nodes) * int(nb_cpus))
        submitopts = '--partition=%s --constraint=%s --job-name=%s --ntasks=%s --ntasks-per-node=%s --exclusive' % (partition, constraint, jobname, ntasks, nb_cpus)
    else:    
#        gpus = str(int(nb_nodes) * int(nb_gpus))
#        submitopts = '--partition=%s --constraint=%s --job-name=%s --gpus-per-node=%s  --gpus=%s' % (partition, constraint, jobname, nb_gpus, gpus)
        submitopts = '--partition=%s --constraint=%s --job-name=%s --gpus-per-node=%s  --nodes=%s' % (partition, constraint, jobname, nb_gpus, nb_nodes)
    #connect to bastion
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(public_ip, username=user,key_filename=ssh_key) 
    # write submission file on bastion
    sftp = ssh.open_sftp()
    remote_file=sftp.file(filepath, "w") 
    remote_file.write(message)
    remote_file.flush()
    sftp.close()
#    command = 'sbatch --chdir /opt/oci-hpc/web-portal/ %s %s' % (submitopts, filepath)
    command = 'sbatch --chdir web-portal/ %s %s' % (submitopts, filepath)
    #### submit sbatch with options and random filename in /tmp
    stdin, stdout, stderr = ssh.exec_command(command)  
    out = stdout.readlines()
    if not out:
        err = stderr.readlines()[-1]
        temp = {"msg": err.strip() }  
    else:
        temp = {"msg": out[-1].strip()}
    
    
    jsondict = json.dumps(temp)
    return (jsondict) 

def list_nodes(ssh_key, user, public_ip):
    """
    Run sinfo on bastion. Access via public IP. Return json.
    """ 
    
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(public_ip, username=user,key_filename=ssh_key) ##### # Put IP here 
    stdin, stdout, stderr = ssh.exec_command('sinfo -o "%P %a %l %D %t %N %f"')  #### sinfo
    # PARTITION AVAIL TIMELIMIT NODES STATE NODELIST AVAIL_FEATURES  
    # compute* up infinite 1 alloc compute-e3-node-791 VM.Standard.E3.Flex,e3  
    out = stdout.readlines()
    
    sinfo_list = []
    

    for line in out[1:]:
        line = line.strip().split()
        if line[3] == "0":
            sinfo_list.append({"partition": line[0], "avail": line[1], "timelimit": line[2], "num_nodes": line[3], "state":"null", "nodelist": "null", "shape": "null", "features": "null" })
        else:    
            sinfo_list.append({"partition": line[0], "avail": line[1], "timelimit": line[2], "num_nodes": line[3], "state":line[4], "nodelist": line[5], "shape": line[6].split(",")[0], "features": line[6].split(",")[1] }) 
    temp = {"sinfo": sinfo_list}
    jsondict = json.dumps(temp)
    return (jsondict) 

def get_features(ssh_key, user, public_ip, path_conf_file):
    """
    get features from queues.conf on Bastion. Access via public IP.
    Return full json + nb gpus.
    """      
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(public_ip, username=user,key_filename=ssh_key) ##### # Put IP here 
    sftp = ssh.open_sftp()
    remote_file = sftp.open(path_conf_file)
    config_dict = yaml.safe_load(remote_file)
    remote_file.close()
    sftp.close()
    for queue in config_dict["queues"]:
        for instance in queue["instance_types"]:
            instance["nb_gpus"] = "N/A"
            instance["nb_cpus"] = instance["instance_pool_ocpus"]
            del instance["instance_pool_ocpus"]
            if "GPU" in instance["shape"]:
                instance["nb_gpus"] = instance["shape"].split(".")[-1]
                instance["nb_cpus"] = "N/A"
            elif not "Flex" in instance["shape"]:
                instance["nb_cpus"] = instance["shape"].split(".")[-1]
            else:
                pass
            
    jsondict = json.dumps(config_dict)
    return (jsondict)

def get_jobs_sacct(ssh_key, user, public_ip, searchdate):
    """
    Get all jobs after a certain date. Access via public IP.
    Return json.
    """          
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(public_ip, username=user,key_filename=ssh_key) 
    # get slurm accounting
    command = "sacct --json --starttime %s | jq '[ .jobs | .[] | {jobid: .job_id, name: .name, working_directory: .working_directory,partition: .partition, features: .constraints, nodelist: .nodes, time: .time | .elapsed, num_nodes: .allocation_nodes, state: .state | .current, reason: .state | .reason }]'" % (searchdate)
    stdin, stdout, stderr = ssh.exec_command(command) 
    list_job = json.load(stdout)
    
    jsondict = json.dumps(list_job)    
    return (jsondict)

def get_log(ssh_key, user, public_ip, working_directory, jobid):
    """
    Access via public IP.
    Return json with jobID and log in base64.
    """        
    #connect to bastion
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(public_ip, username=user,key_filename=ssh_key) 
    # get log
    sftp = ssh.open_sftp()
    filepath = os.path.join(working_directory, "slurm-%s.out" % (jobid))
    try:
        remote_file=sftp.file(filepath, "r") 
        data = remote_file.read()
        remote_file.flush()
        sftp.close()
        base64_message = base64.b64encode(data)
        message = base64_message.decode('utf-8')
    except Exception as ex:
        print('ERROR: during execution', ex, flush=True)
        data = str(ex)
        message_bytes = data.encode('utf-8')
        base64_message = base64.b64encode(message_bytes)
        message = base64_message.decode('utf-8')
        pass
    
        
    temp = {"jobid": jobid, "log": message } 
    jsondict = json.dumps(temp)
    return(jsondict)


def handler(ctx, data: io.BytesIO=None):
    logging.getLogger().info("function start")


    try:
        payload_bytes = data.getvalue()
        if payload_bytes==b'':
            raise KeyError('No keys in payload')
        payload = json.loads(payload_bytes)
        user = payload["user"]
        public_ip = payload["public_ip"]
        secret_ocid = payload["secret_ocid"]
        selected_function = payload["selected_function"]
    except Exception as ex:
        print('ERROR: Missing key in payload', ex, flush=True)
        raise

    resp = ""

    get_text_secret(secret_ocid,ssh_key)
    # Choose which function to use.
    if selected_function == "list_jobs":
        searchdate = payload["searchdate"]
        resp = get_jobs_sacct(ssh_key, user, public_ip, searchdate)
    elif selected_function == "cancel_job":
        jobid_list = payload["jobid_list"]
        resp = cancel_job(ssh_key, user, public_ip, jobid_list)
    elif selected_function == "submit_job":
        partition = payload["partition"]
        constraint = payload["constraint"]
        jobname = payload["jobname"]
        nb_cpus = payload["nb_cpus"]
        nb_nodes = payload["nb_nodes"]
        nb_gpus = payload["nb_gpus"]
        base64_message = payload["base64_message"]
        resp = submit_job(ssh_key, user, public_ip, partition, constraint, jobname, nb_cpus, nb_nodes, nb_gpus, base64_message)    
    elif selected_function == "list_nodes":
        resp = list_nodes(ssh_key, user, public_ip)
    elif selected_function == "get_features": 
        path_conf_file = payload["path_conf_file"]
        resp = get_features(ssh_key, user, public_ip, path_conf_file)
    else:
        jobid = payload["jobid"]
        working_directory = payload["working_directory"]
        resp = get_log(ssh_key, user, public_ip, working_directory, jobid)    


    logging.getLogger().info("function end")
    return response.Response(
        ctx,
        response_data=resp,
        headers={"Content-Type": "application/json"}
    )
