# Documentação do Repositório Terraform para Infraestrutura Azure

## Descrição
Este repositório contém uma configuração de infraestrutura como código utilizando **Terraform** para provisionar recursos na nuvem Azure, incluindo um Application Gateway, rede virtual (VNet), sub-redes, e mais.

O repositório também inclui um pipeline de CI/CD automatizado com GitHub Actions para validar e aplicar alterações de infraestrutura em diferentes branches.

---

## Componentes

### Arquivos Principais

- **`main.yml`**: Configuração do pipeline de CI/CD utilizando GitHub Actions.
- **`main.tf`**: Código principal do Terraform para definir os recursos na Azure.

---

## Estrutura do Repositório

### Pipeline CI/CD (`main.yml`)
O arquivo `main.yml` define um fluxo de trabalho GitHub Actions para validar, realizar o plano e aplicar alterações de infraestrutura.

#### **Fluxo do Pipeline**
1. **Eventos Disparadores**: O pipeline é disparado para os eventos:
    - Push em qualquer branch.
    - Pull requests fechados.
    - Manualmente usando `workflow_dispatch`.

2. **Permissões**:
    - `id-token`: Usado para login via Azure.
    - `contents`: Verifica o repositório.

3. **Etapas do Job `terraform`**:
    - **Checkout do código**: Obter o código do repositório.
    - **Setup Terraform**: Configura a versão do Terraform.
    - **Login no Azure**: Usa credenciais **armazenadas como secrets** no repositório.
    - **Terraform Init**: Inicializa o diretório e baixa os providers necessários.
    - **Terraform Validate**: Valida a sintaxe e estrutura do código de infraestrutura.
    - **Terraform Plan**: Gera o plano de execução.
    - **Terraform Apply**: Aplica as mudanças quando um pr e feito para a branch `main`.

#### **Secrets Necessários**
É necessário definir secrets no repositório para autenticar no Azure:
- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

---

### Infraestrutura Terraform (`main.tf`)
A configuração do arquivo `main.tf` provisiona os seguintes recursos na Azure:

1. **Provider AzureRM**
    - Define o provider AzureRM da Hashicorp.
    - Requer no mínimo a versão `3.0.0`.

2. **Variáveis**
    - Variáveis configuráveis para personalizar a infraestrutura:
        - **`subscription_id`**: Subscription ID do Azure.
        - **`location`**: Região onde os recursos serão provisionados. Default: `"eastus"`.
        - **`resource_group_name`**: Nome do grupo de recursos. Default: `"rg-postech-fiap-appgw"`.
        - **`appgw_name`**: Nome do Application Gateway. Default: `"postech-fiap-appgw"`.
        - **`function_host_name`**: Hostname da Azure Function utilizada. Default: `"postech-fiap-serverless.azurewebsites.net"`.
        - **`vnet_name`**: Nome da Virtual Network (VNet). Default: `"postech-fiap-vnet-appgw"`.
        - **`subnet_name`**: Nome da sub-rede na VNet. Default: `"postech-fiap-subnet-appgw"`.

3. **Recursos Criados**
    - **Virtual Network (VNet)**:
        - Espaço de endereçamento: `10.0.0.0/16`
    - **Subnet**:
        - Espaço de endereçamento: `10.0.1.0/24`
    - **Public IP**:
        - IP público fixo e com SKU `Standard`.
    - **Application Gateway**:
        - Nome: Configurável pela variável `appgw_name`.
        - Modelo SKU: `Standard_v2`.
        - Backend HTTP configurado para integrar com uma Azure Function através de FQDN.
        - Regras baseadas em caminhos para rotear requisições para `/api/*`.

4. **Outputs**
    - IP público (output: `public_ip`) do Application Gateway após provisionamento.

---

## Como Usar

### Pré-Requisitos
Certifique-se de que você tem:
1. **Terraform**:
    - Requerido: Versão `>= 1.0.0`.
    - Plug-in AzureRM: Versão `>= 3.0.0`.
2. **Azure CLI**:
    - Autenticação prévia requerida.
3. **GitHub Actions**:
    - Configure os secrets no repositório para integrações com Azure.


## Estrutura do Application Gateway

### Configuração
1. **Regras de Roteamento Baseadas em Caminhos**:
    - Baseia-se no mapeamento da URL para a Azure Function.
    - Caminho `/api/*` enviado para o host configurado.

2. **Estrutura de Rede**:
    - A VNet e o gateway estão configurados com uma sub-rede dedicada.

3. **Certificação**
    - Configurado para HTTPS backend em comunicação com Azure Function.

---

## Pipeline Automatizado

### Passos de CI/CD
- Push inicia validação do código Terraform.
- Plano é gerado para revisão.
- Apenas na branch `main`, as alterações são aplicadas automaticamente.

---