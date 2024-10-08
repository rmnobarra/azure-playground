# Managed Identity

Configura um ambiente Kubernetes no Azure, incluindo a configuração de um cluster AKS, identidade gerenciada, conta de armazenamento e integração com o Azure Container Registry (ACR). e faz o deployment de uma aplicação .net que envia arquivos para um container dentro da storage account.

Demais funcionalidades do projeto:

* Aplicação .net 8 que envia arquivos para um container dentro uma storage account.
* Aplicação web que lista todos os arquivos dentro um container em uma storage account.
* Injeta falhas no ambiente para validar conhecimento.
* Verifica se a solução proposta irá resolver o problema proposto.
* Destroi o ambiente após o uso.
* [Deck de perguntas e respostas para validação de conhecimento](PERGUNTAS.md).

## Pré-requisitos

Antes de começar, certifique-se de ter os seguintes pré-requisitos instalados:

- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- Conta no [Azure](https://azure.microsoft.com/)
- Processador de JSON [jq](https://jqlang.github.io/jq/)

## Configuração

1. Clone este repositório:

    ```sh
    git clone https://github.com/rmnobarra/azure-playground.git
    cd labs/managed-identity
    ```

2. Configure as variáveis de ambiente necessárias:

    ```sh
    export PREFIX=lab
    export LOCATION=eastus
    ```

3. Execute o script de configuração:

    ```sh
    make
    ```

## Execução

Após a configuração, você pode verificar os logs do Pod criado no Kubernetes:

```sh
kubectl logs -f `kubectl get pods --selector=app=blob-lab --output=jsonpath='{.items[0].metadata.name}'`
```

## Diagrama

```mermaid
graph TD;
    subgraph Azure
        RG[Resource Group]
        AKS[AKS Cluster]
        ACR[Azure Container Registry]
        Identity[Managed Identity]
        StorageAccount[Storage Account]
        Container[Blob Container]
        User[Azure User]

        RG --> AKS
        RG --> ACR
        RG --> Identity
        RG --> StorageAccount

        StorageAccount --> Container

        User -- "Role Assignment: Storage Blob Data Contributor" --> StorageAccount
        Identity -- "Role Assignment: Storage Blob Data Contributor" --> StorageAccount

        AKS -->|Workload Identity| Identity
        AKS -->|OIDC| Identity
        ACR --> AKS

        AKS -->|kubectl| ServiceAccount[Service Account]
        ServiceAccount --> PodBlobLab[Pod: blob-lab]
        ServiceAccount --> DeploymentBlobLab[Deployment: blob-lab]
        ServiceAccount --> PodBlobAPI[Pod: blob-api]
        ServiceAccount --> DeploymentBlobAPI[Deployment: blob-api]
        
        PodBlobLab -->|Image| ACR
        PodBlobLab -->|Access| StorageAccount
        DeploymentBlobLab --> PodBlobLab
        
        PodBlobAPI -->|Image| ACR
        PodBlobAPI -->|Access| StorageAccount
        DeploymentBlobAPI --> PodBlobAPI
        
        subgraph Networking
            Service[Service: blob-api-service]
            Ingress[Ingress: blob-api-ingress]
            
            PodBlobAPI --> Service
            Service --> Ingress
        end
    end
```