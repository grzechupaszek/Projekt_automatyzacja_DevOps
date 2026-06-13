# Projekt DevOps 2026 — GitOps na AKS (ocena 5.0 / LAB-05)

**Autor:** Grzegorz Paszek
**Nr albumu:** 422374

Pełny pipeline GitOps dla aplikacji kontenerowej na Azure Kubernetes Service:

- infrastruktura (ACR + AKS) jako kod w Terraform,
- `terraform plan` na każdym PR (komentarz), `terraform apply` po merge do `main`,
- remote state w Azure Storage Account,
- autoryzacja GitHub Actions → Azure przez OIDC (bez długożyciowych sekretów),
- build → test → push obrazu do ACR → rollout w AKS automatycznie.

## Struktura

```
.
├── app/                  # aplikacja Flask + testy
│   ├── app.py            #   endpointy / i /health
│   ├── requirements.txt
│   └── test_app.py
├── Dockerfile
├── k8s/
│   └── deployment.yaml   # Deployment + Service (LoadBalancer)
├── infra/                # Terraform: ACR + AKS + remote backend
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── scripts/
│   └── bootstrap.sh      # jednorazowy bootstrap: storage + OIDC
└── .github/workflows/
    ├── infra.yml         # terraform plan (PR) / apply (main)
    └── ci.yml            # build/test/push/deploy aplikacji
```

## Uruchomienie lokalne

```bash
cd app
pip install -r requirements.txt
pytest                       # testy
python app.py                # http://localhost:8080/health
```

Lub w kontenerze:

```bash
docker build -t app .
docker run -p 8080:8080 app
```

## Wdrożenie — patrz instrukcja krok po kroku poniżej

Parametry zasobów Azure:

| Zasób | Nazwa |
|---|---|
| Resource group (app) | `rg-lab05` |
| ACR | `acrlab422374` (`acrlab422374.azurecr.io`) |
| AKS | `aks-lab05` |
| Resource group (state) | `rg-tf-state` |
| Storage Account (state) | `stlab05tf422374` |
| Container | `tfstate` |
