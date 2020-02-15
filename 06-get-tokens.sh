#!/bin/bash

APISERVER=$(kubectl config view --minify | grep server | cut -f 2- -d ":" | tr -d " ")
SECRET_NAME=$(kubectl get secrets | grep ^prometheus | cut -f1 -d ' ')
TOKEN=$(kubectl describe secret $SECRET_NAME | grep -E '^token' | cut -f2 -d':' | tr -d " ")
CA_CERT=$(kubectl config view --minify --raw --output 'jsonpath={..cluster.certificate-authority-data}' | base64 -D)

echo "Apiserver: ${APISERVER}"
echo "Token: ${TOKEN}"
echo "CA_CERT: ${CA_CERT}"
