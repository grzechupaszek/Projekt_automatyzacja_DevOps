#!/usr/bin/env bash
# Bootstrap LAB-05 — jednorazowy skrypt uruchamiany LOKALNIE.
# Tworzy: Storage Account na remote state TF + rejestrację aplikacji (OIDC).
# Autor: Grzegorz Paszek, nr albumu 422374
set -euo pipefail

# ---- Parametry (dostosuj jeśli trzeba) -------------------------------------
LOCATION="westeurope"

# Remote state
STATE_RG="rg-tf-state"
STORAGE_ACCOUNT="stlab05tf422374"   # globalnie unikalna, 3-24 znaki, [a-z0-9]
CONTAINER_NAME="tfstate"

# OIDC / Workload Identity Federation
APP_NAME="gha-lab05-422374"
GITHUB_ORG="grzechupaszek"
GITHUB_REPO="Projekt_automatyzacja_DevOps"
# ----------------------------------------------------------------------------

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

echo "==> 1. Storage Account na TF state"
az group create --name "$STATE_RG" --location "$LOCATION"

az storage account create \
  --resource-group "$STATE_RG" \
  --name "$STORAGE_ACCOUNT" \
  --sku Standard_LRS \
  --encryption-services blob

az storage container create \
  --name "$CONTAINER_NAME" \
  --account-name "$STORAGE_ACCOUNT"

echo "==> 2. Rejestracja aplikacji (service principal) dla OIDC"
APP_ID=$(az ad app create --display-name "$APP_NAME" --query appId -o tsv)
az ad sp create --id "$APP_ID"

echo "==> 3. Nadanie roli Contributor na subskrypcji"
az role assignment create \
  --assignee "$APP_ID" \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"

echo "==> 4. Federated credentials (OIDC) dla GitHub Actions"
# branch main (push)
az ad app federated-credential create --id "$APP_ID" --parameters "{
  \"name\": \"gha-main\",
  \"issuer\": \"https://token.actions.githubusercontent.com\",
  \"subject\": \"repo:${GITHUB_ORG}/${GITHUB_REPO}:ref:refs/heads/main\",
  \"audiences\": [\"api://AzureADTokenExchange\"]
}"

# pull requests (terraform plan)
az ad app federated-credential create --id "$APP_ID" --parameters "{
  \"name\": \"gha-pr\",
  \"issuer\": \"https://token.actions.githubusercontent.com\",
  \"subject\": \"repo:${GITHUB_ORG}/${GITHUB_REPO}:pull_request\",
  \"audiences\": [\"api://AzureADTokenExchange\"]
}"

echo ""
echo "============================================================"
echo " GOTOWE. Wpisz te wartości jako sekrety w GitHub:"
echo "============================================================"
echo "AZURE_CLIENT_ID        = $APP_ID"
echo "AZURE_TENANT_ID        = $TENANT_ID"
echo "AZURE_SUBSCRIPTION_ID  = $SUBSCRIPTION_ID"
echo "TF_STORAGE_ACCOUNT     = $STORAGE_ACCOUNT"
echo "ACR_LOGIN_SERVER       = acrlab422374.azurecr.io"
echo "AKS_NAME               = aks-lab05"
echo "RESOURCE_GROUP         = rg-lab05"
echo "============================================================"
