#!/bin/bash

# Check if Minikube is running
if ! minikube status &> /dev/null; then
  echo "Minikube is not running."
  exit 1
fi

# Check if the 'dev' namespace exists
if kubectl get namespace dev &> /dev/null; then
  echo "Namespace 'dev' exists."
else
  echo "Namespace 'dev' does not exist. Creating..."
  kubectl create namespace dev
  echo "Namespace 'dev' created."
fi

# Check if the 'production' namespace exists
if kubectl get namespace production &> /dev/null; then
  echo "Namespace 'production' exists."
else
  echo "Namespace 'production' does not exist. Creating..."
  kubectl create namespace production
  echo "Namespace 'production' created."
fi
