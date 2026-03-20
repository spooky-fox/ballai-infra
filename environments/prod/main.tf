module "ballai_worker" {
  source = "../../modules/ballai-worker"

  name_prefix = var.name_prefix
  account_id  = var.cloudflare_account_id
}
