locals {
  # Canonical secret is DUFFEL_API_TOKEN. Keep DUFFLE_API_KEY for compatibility while
  # runtime and deployment paths converge on a single key name.
  effective_duffel_token = trimspace(var.duffel_api_token) != "" ? var.duffel_api_token : var.duffle_api_key
}

module "ballai_worker" {
  source = "../../components/terraform/ballai-worker"

  name_prefix = var.name_prefix
  account_id  = var.cloudflare_account_id

  worker_secrets = {
    AUTH_SECRET                        = var.worker_auth_secret
    TOGETHER_API_KEY                   = var.together_api_key
    TAVILY_API_KEY                     = var.tavily_api_key
    KAGI_API_KEY                       = var.kagi_api_key
    SERPAPI_KEY                        = var.serpapi_key
    GOOGLE_SERVICE_ACCOUNT_EMAIL       = var.google_service_account_email
    GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY = var.google_service_account_private_key
    TILLER_SPREADSHEET_ID              = var.tiller_spreadsheet_id
    TILLER_PERSONAL_SPREADSHEET_ID     = var.tiller_personal_spreadsheet_id
    TILLER_BUSINESS_SPREADSHEET_ID     = var.tiller_business_spreadsheet_id
    GENIUS_SCAN_FOLDER_ID              = var.genius_scan_folder_id
    DUFFEL_API_TOKEN                   = local.effective_duffel_token
    DUFFLE_API_KEY                     = local.effective_duffel_token
  }
}

module "worker_oidc" {
  source = "../../components/terraform/worker-oidc-federation"

  worker_url = "https://ballai-api.ballai.workers.dev"

  tags = {
    Project     = "ballai"
    ManagedBy   = "terraform"
    Environment = "prod"
  }
}

module "github_actions_runners" {
  count  = var.enable_github_actions_runners ? 1 : 0
  source = "../../components/terraform/github-actions-codebuild-runners"

  name_prefix           = "${var.name_prefix}-gha"
  github_owner          = var.github_owner
  runner_group_id       = var.github_runner_group_id
  org_registration_name = ""

  repositories = {
    ballai = {
      repository_name = "ballai"
      description     = "Linux GitHub Actions jobs for Ballai app repo"
    }
    "ballai-infra" = {
      repository_name = "ballai-infra"
      description     = "Terraform CI and apply workflows"
    }
    "ballai-infra-prod" = {
      repository_name = "ballai-infra"
      description     = "Terraform workflows for environments/prod"
    }
    "ballai-infra-lanzo-web" = {
      repository_name = "ballai-infra"
      description     = "Terraform workflows for environments/prod/lanzo-web"
    }
    "lanzo-web" = {
      repository_name = "lanzo-web"
      description     = "Website build/lint/test workflows"
    }
  }

  tags = {
    Project     = "ballai"
    ManagedBy   = "terraform"
    Environment = "prod"
  }
}
