locals {
  # Strip https:// prefix for IAM condition keys (AWS uses the bare hostname)
  oidc_provider_host = replace(var.worker_url, "https://", "")
}

# The Worker serves /.well-known/openid-configuration and /jwks endpoints.
# AWS STS validates JWT signatures by fetching the JWKS from this URL.
resource "aws_iam_openid_connect_provider" "worker" {
  url            = var.worker_url
  client_id_list = ["sts.amazonaws.com"]

  # AWS fetches the TLS thumbprint automatically for HTTPS OIDC providers
  # (since July 2023). Passing a dummy is fine; AWS ignores it and verifies
  # the cert chain against its own CA trust store.
  thumbprint_list = ["0000000000000000000000000000000000000000"]

  tags = merge(var.tags, {
    Purpose = "worker-oidc-federation"
  })
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.worker.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_host}:sub"
      values   = [var.worker_subject]
    }
  }
}

resource "aws_iam_role" "worker_bedrock" {
  name                 = var.role_name
  assume_role_policy   = data.aws_iam_policy_document.assume_role.json
  max_session_duration = var.max_session_duration
  tags                 = var.tags
}

data "aws_iam_policy_document" "bedrock_invoke" {
  statement {
    sid       = "BedrockInvokeModel"
    effect    = "Allow"
    actions   = ["bedrock:InvokeModel"]
    resources = var.bedrock_model_arns
  }
}

resource "aws_iam_role_policy" "bedrock_invoke" {
  name   = "bedrock-invoke"
  role   = aws_iam_role.worker_bedrock.id
  policy = data.aws_iam_policy_document.bedrock_invoke.json
}
