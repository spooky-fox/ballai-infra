module "ballai_worker" {
  source = "../../modules/ballai-worker"

  name_prefix = var.name_prefix
  account_id  = var.cloudflare_account_id
}

module "github_actions_runners" {
  count  = var.enable_github_actions_runners ? 1 : 0
  source = "../../modules/github-actions-codebuild-runners"

  name_prefix           = "${var.name_prefix}-gha"
  github_owner          = var.github_owner
  runner_group_id       = var.github_runner_group_id
  org_registration_name = ""

  repositories = merge(
    {
      ballai = {
        repository_name = "ballai"
        description     = "Linux GitHub Actions jobs for Ballai app repo"
        compute_type    = "BUILD_GENERAL1_MEDIUM"
      }
      "ballai-infra" = {
        repository_name = "ballai-infra"
        description     = "Terraform CI and apply workflows"
        compute_type    = "BUILD_GENERAL1_MEDIUM"
      }
      "ballai-infra-prod" = {
        repository_name = "ballai-infra"
        description     = "Terraform workflows for environments/prod"
        compute_type    = "BUILD_GENERAL1_MEDIUM"
      }
      "ballai-infra-lanzo-web" = {
        repository_name = "ballai-infra"
        description     = "Terraform workflows for environments/prod/lanzo-web"
        compute_type    = "BUILD_GENERAL1_MEDIUM"
      }
      "lanzo-web" = {
        repository_name = "lanzo-web"
        description     = "Website build/lint/test workflows"
        compute_type    = "BUILD_GENERAL1_MEDIUM"
      }
    },
    var.enable_github_actions_codebuild_backup ? {
      "ballai-backup" = {
        repository_name = "ballai"
        description     = "Backup Linux CodeBuild pool for spooky-fox/ballai (distinct runs-on label)"
        compute_type    = "BUILD_GENERAL1_LARGE"
      }
      "ballai-infra-backup" = {
        repository_name = "ballai-infra"
        description     = "Backup Linux CodeBuild pool for spooky-fox/ballai-infra"
        compute_type    = "BUILD_GENERAL1_LARGE"
      }
    } : {},
    var.github_actions_codebuild_extra_repositories
  )

  tags = {
    Project     = "ballai"
    ManagedBy   = "terraform"
    Environment = "prod"
  }
}
