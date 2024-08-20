#!/bin/bash

PREFIX=lab
LOCATION=eastus
RANDOM=$RANDOM
UNIQUE_ID=$PREFIX$RANDOM
CLUSTER_NAME=$UNIQUE_ID
RG=$UNIQUE_ID
ACR_NAME=$UNIQUE_ID
STORAGE_ACCT_NAME=$UNIQUE_ID
echo "Variaveis de ambiente..."
ENV_FILE="env_vars.sh"

echo "Exportando as Variaveis de ambiente..."

# Escrevendo as variáveis no arquivo
echo "export PREFIX=$PREFIX" > $ENV_FILE
echo "export LOCATION=$LOCATION" >> $ENV_FILE
echo "export UNIQUE_ID=$UNIQUE_ID" >> $ENV_FILE
echo "export CLUSTER_NAME=$CLUSTER_NAME" >> $ENV_FILE
echo "export RG=$RG" >> $ENV_FILE
echo "export ACR_NAME=$ACR_NAME" >> $ENV_FILE
echo "export STORAGE_ACCT_NAME=$STORAGE_ACCT_NAME" >> $ENV_FILE

echo "Variaveis de ambiente..."

echo "PREFIX=$PREFIX"
echo "RG=$UNIQUE_ID"
echo "LOCATION=$LOCATION"
echo "CLUSTER_NAME=$CLUSTER_NAME"
echo "UNIQUE_ID=$UNIQUE_ID"
echo "ACR_NAME=$ACR_NAME"
echo "STORAGE_ACCT_NAME=$STORAGE_ACCT_NAME"

echo "Criando grupo de recursos..."
az group create -g $RG -l $LOCATION

echo "Criando cluster AKS..."
az aks create -g $RG -n $CLUSTER_NAME \
--node-count 1 \
--enable-oidc-issuer \
--enable-workload-identity \
--enable-app-routing \
--generate-ssh-keys

echo "Obtendo credenciais do AKS..."
az aks get-credentials -g $RG -n $CLUSTER_NAME

echo "Exportando URL do emissor OIDC do AKS..."
export AKS_OIDC_ISSUER="$(az aks show -n $CLUSTER_NAME -g $RG --query "oidcIssuerProfile.issuerUrl" -otsv)"

echo "export AKS_OIDC_ISSUER=$AKS_OIDC_ISSUER" >> $ENV_FILE

echo "Criando identidade gerenciada..."
az identity create --name $PREFIX-identity --resource-group $RG --location $LOCATION

echo "Exportando Client ID da identidade gerenciada..."
export USER_ASSIGNED_CLIENT_ID=$(az identity show --resource-group $RG --name $PREFIX-identity --query 'clientId' -o tsv)

echo "export USER_ASSIGNED_CLIENT_ID=$USER_ASSIGNED_CLIENT_ID" >> $ENV_FILE

echo "Criando ServiceAccount no Kubernetes..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    azure.workload.identity/client-id: ${USER_ASSIGNED_CLIENT_ID}
  labels:
    azure.workload.identity/use: "true"
  name: $PREFIX-sa
  namespace: default
EOF

echo "Criando credencial federada para a identidade gerenciada..."
az identity federated-credential create \
--name $PREFIX-federated-id \
--identity-name $PREFIX-identity \
--resource-group $RG \
--issuer ${AKS_OIDC_ISSUER} \
--subject system:serviceaccount:default:$PREFIX-sa

echo "Criando conta de armazenamento..."
az storage account create \
--name $STORAGE_ACCT_NAME \
--resource-group $RG \
--location $LOCATION \
--sku Standard_LRS \
--encryption-services blob

echo "Obtendo ID da conta de armazenamento..."
STORAGE_ACCT_ID=$(az storage account show -g $RG -n $STORAGE_ACCT_NAME --query id -o tsv)

echo "export STORAGE_ACCT_ID=$STORAGE_ACCT_ID" >> $ENV_FILE

echo "Obtendo ID do usuário atual..."
CURRENT_USER=$(az ad signed-in-user show --query id -o tsv)

echo "export CURRENT_USER=$CURRENT_USER" >> $ENV_FILE

echo "Atribuindo função 'Storage Blob Data Contributor' ao usuário atual..."
az role assignment create \
--role "Storage Blob Data Contributor" \
--assignee $CURRENT_USER \
--scope "${STORAGE_ACCT_ID}"

echo "Atribuindo função 'Storage Blob Data Contributor' à identidade gerenciada..."
az role assignment create \
--role "Storage Blob Data Contributor" \
--assignee $USER_ASSIGNED_CLIENT_ID \
--scope "${STORAGE_ACCT_ID}"

echo "Criando container de armazenamento..."
az storage container create --account-name $STORAGE_ACCT_NAME --name data --auth-mode login

echo "Entrando no diretório 'blob-console-app'..."
cd blob-console-app

echo "Criando Registro de Container do Azure..."
az acr create -g $RG -n $ACR_NAME --sku Standard

echo "Construindo e enviando imagem para o ACR..."
az acr build -t blob-lab -r $ACR_NAME .

echo "Associando ACR ao cluster AKS..."
az aks update -g $RG -n $CLUSTER_NAME --attach-acr $ACR_NAME

echo "Criando Workload blob console no Cluster AKS..."

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: blob-lab
  namespace: default
  labels:
    azure.workload.identity/use: "true"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: blob-lab
  template:
    metadata:
      labels:
        app: blob-lab
        azure.workload.identity/use: "true"
    spec:
      serviceAccountName: $PREFIX-sa
      containers:
        - image: ${ACR_NAME}.azurecr.io/blob-lab
          name: blob-lab
          env:
          - name: STORAGE_ACCT_NAME
            value: ${STORAGE_ACCT_NAME}
          - name: CONTAINER_NAME
            value: data
      nodeSelector:
        kubernetes.io/os: linux
EOF

echo "Entrando no diretório 'BlobApi'..."
cd ../BlobApi

echo "Construindo e enviando imagem para o ACR..."
az acr build -t blob-api -r $ACR_NAME .

echo "Criando Workload blob API no Cluster AKS..."

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: blob-api
  namespace: default
  labels:
    azure.workload.identity/use: "true"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: blob-api
  template:
    metadata:
      labels:
        app: blob-api
        azure.workload.identity/use: "true"
    spec:
      serviceAccountName: $PREFIX-sa
      containers:
        - image: ${ACR_NAME}.azurecr.io/blob-api
          name: blob-api
          env:
          - name: STORAGE_ACCT_NAME
            value: ${STORAGE_ACCT_NAME}
          - name: CONTAINER_NAME
            value: data
          - name: PORT
            value: "5001"
          ports: 
            - containerPort: 5001
      nodeSelector:
        kubernetes.io/os: linux
---
apiVersion: v1
kind: Service
metadata:
  name: blob-api-service
  namespace: default
spec:
  selector:
    app: blob-api
  ports:
    - name: http         
      protocol: TCP
      port: 80
      targetPort: 5001
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: blob-api-ingress
  namespace: default
spec:
  ingressClassName: webapprouting.kubernetes.azure.com
  rules:
  - host: ""
    http:
      paths:
      - backend:
          service:
            name: blob-api-service
            port:
              number: 80
        path: /
        pathType: Prefix
EOF


echo "Aguardando 30 segundos para o Pod iniciar..."
sleep 30

echo "Verificando logs do Pod no workdload 1..."

timeout 30s kubectl logs -f `kubectl get pods --selector=app=blob-lab --output=jsonpath='{.items[0].metadata.name}'`

echo "Verificando logs do Pod no workdload 2..."

curl `kubectl get ingress blob-api-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}'`/api/blobs | jq

# troubleshooting
#echo "Encaminhando a porta para o deploy blob-api..."
#kubectl port-forward deployment/blob-api 5001:5001 &