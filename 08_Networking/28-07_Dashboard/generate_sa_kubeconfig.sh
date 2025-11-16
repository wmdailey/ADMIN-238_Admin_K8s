#!/bin/bash

# Title: generate_sa_kubeconfig.sh
# Author: Md Shamim 
# Date: 15SEPT22
# Modified: WKD
# Version: 3.2.0
# Date: 7APR25
# Purpose: This script is used to create a custom kubeconfig file for Service 
# Accounts. The script requires an input of "Service Account name" and "namespace name", 
# and "yes" for execution.

# DEBUG
#set -x
#set -eu
#set >> /tmp/setvar.txt

read -p 'Enter the ServiceAccount Name: ' name
read -p 'Enter the Namespace Name: ' namespace

export SA_NAME=$name
export NAMESPACE=$namespace

echo
echo "Credentials and kubeconfig will be created for:"
echo -e "  ServiceAccount Name: ${SA_NAME}\n  Namespace: ${NAMESPACE}"
echo
echo -n  "Proceed? \"yes\" or \"no\":  " 
read value

if [ $value == "yes" ]
then
    mkdir ${SA_NAME}
    cd ${SA_NAME}
    
    #Create a Service Account
    kubectl get namespace ${NAMESPACE} 2>/dev/null
    if [ $? -eq 1 ]; then 
       kubectl create namespace $NAMESPACE 
    else
       echo
    fi

    #Change context
    kubectl config set-context --current --namespace=$NAMESPACE
    
    #CA extraction from current kubeconfig file
    kubectl config view --raw -o jsonpath='{..cluster.certificate-authority-data}' | base64 --decode > ca.crt

    #Create a Service Account
    kubectl get serviceaccount ${SA_NAME} 2>/dev/null
    if [ $? -eq 1 ]; then 
       kubectl create serviceaccount ${SA_NAME} --namespace $NAMESPACE 
    else
       echo
    fi

    #Generate TOKEN for the Service Account 
    kubectl create token $SA_NAME --duration=60000s > token 
   
    #Set ENV
    export CA_CRT=$(cat ca.crt | base64 -w 0)
    export CONTEXT=$(kubectl config current-context)
    export CLUSTER_ENDPOINT=$(kubectl config view -o jsonpath='{.clusters[?(@.name=="'"$CONTEXT"'")].cluster.server}')
    export SA_NAME=$name
    export NAMESPACE=$namespace
    export TOKEN=$(cat token)
    
    #Configure kubeconfig file
    curl file:///$(pwd)/../template-kubeconfig.yaml | sed "s#<context>#${CONTEXT}# ;
    s#<cluster-name>#${CONTEXT}# ;
    s#<ca.crt>#${CA_CRT}# ;
    s#<cluster-endpoint>#${CLUSTER_ENDPOINT}# ;
    s#<service-account>#${SA_NAME}# ;
    s#<namespace>#${NAMESPACE}# ;
    s#<token>#${TOKEN}#" > config

    echo
    echo  "The credentials and kubeconfig file are located in $name." 
else
    echo "Next time"
    exit 
fi
