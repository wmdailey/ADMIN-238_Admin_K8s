#!/bin/bash

# Title: generate_kubeconfig.sh
# Author: Md Shamim 
# Date: 15SEPT22
# Edit: WKD
# Version: 3.2.0
# Date: 25APR22
# Purpose: This script is used to create a custom kubeconfig file for individual 
# users. The script requires an input of "username", "group name", "namespace name", 
# and "yes" for execution.

# DEBUG
#set -x
#set -eu
#set >> /tmp/setvar.txt


read -p 'Enter the Username : ' name
read -p 'Enter the Group Name : ' group
read -p 'Enter the Namespace Name: ' namespace

export CLIENT=$name
export GROUP=$group
export NAMESPACE=$namespace

echo
echo "Credentials and a kubeconfig will be created for:"
echo -e  "  Username: ${CLIENT}\n  Group Name: ${GROUP}\n  Namespace: ${NAMESPACE}"
echo
echo -n "Proceed? \"yes\" or \"no\":  " 
read value

if [ $value == "yes" ]
then
    mkdir ${CLIENT}
    cd ${CLIENT}
    
    #Generate key
    openssl genrsa -out ${CLIENT}.key 2048
    
    #Generate csr
    openssl req -new -key ${CLIENT}.key -subj "/CN=${CLIENT}/O=${GROUP}" -out ${CLIENT}.csr
    
    #CSR to base64
    export CSR_CLIENT=$(cat ${CLIENT}.csr | base64 -w 0)
    
    #Create CSR object file
    curl file:///$(pwd)/../user-csr.yaml | sed "s/<name>/${CLIENT}/ ; s/<csr-base64>/${CSR_CLIENT}/" > ${CLIENT}_csr.yaml
   
    #Create CSR object
    kubectl create -f ${CLIENT}_csr.yaml
   
    #Approve CSR 
    kubectl certificate approve ${CLIENT}
    
    #extracting client certificate
    kubectl get csr ${CLIENT} -o jsonpath='{.status.certificate}' | base64 --decode > ${CLIENT}.crt
    
    #CA extraction 
    kubectl config view --raw -o jsonpath='{..cluster.certificate-authority-data}' | base64 --decode > ca.crt
   
    #Set ENV
    export CA_CRT=$(cat ca.crt | base64 -w 0)
    export CONTEXT=$(kubectl config current-context)
    export CLUSTER_ENDPOINT=$(kubectl config view -o jsonpath='{.clusters[?(@.name=="'"$CONTEXT"'")].cluster.server}')
    export USER=${CLIENT}
    export CRT=$(cat ${CLIENT}.crt | base64 -w 0)
    export KEY=$(cat ${CLIENT}.key | base64 -w 0)
    export NAMESPACE=$namespace
    
    #Configure kubeconfig file
    curl file:///$(pwd)/../user-kubeconfig.yaml | sed "s#<context>#${CONTEXT}# ;
    s#<cluster-name>#${CONTEXT}# ;
    s#<ca.crt>#${CA_CRT}# ;
    s#<cluster-endpoint>#${CLUSTER_ENDPOINT}# ;
    s#<user-name>#${USER}# ;
    s#<namespace>#${NAMESPACE}# ;
    s#<user.crt>#${CRT}# ; 
    s#<user.key>#${KEY}#" > config

    echo
    echo  "The credentials and kubeconfig file are located in $name." 
else
    echo "Next Time"
    exit 
fi
