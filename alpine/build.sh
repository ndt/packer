#!/bin/bash

set -e

packer build -force \
  -var "ssh_pubkey=$(<~/.ssh/id_rsa.pub)" \
  -var "password=$(od -vAn -N8 -tu8 < /dev/urandom | cut -f 2 -d ' ')" \
  packer.json


#   "variables": {
#	  "password": "",
#	  "ssh_pubkey": ""
#    },
#    "provisioners": [
#	   {
#	     "type": "shell",
#	     "script": "install.sh",
#	     "environment_vars": [
#                "ROOT_PASSWORD={{user `password`}}",
#				 "SSH_PUBKEY={{user `ssh_pubkey`}}"
#        ]
#	   }
#    ]
