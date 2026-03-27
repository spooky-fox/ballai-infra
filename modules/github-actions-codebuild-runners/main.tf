locals {
  projects = {
    for key, repo in var.repositories :
    key => merge(repo, {
      project_name = "${var.name_prefix}-${key}"
      repo_url     = "https://github.com/${var.github_owner}/${repo.repository_name}.git"
    })
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codebuild" {
  for_each = local.projects

  name               = "${each.value.project_name}-service-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

data "aws_iam_policy_document" "codebuild_permissions" {
  for_each = local.projects

  statement {
    sid    = "Logs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "codebuild_inline" {
  for_each = local.projects

  role   = aws_iam_role.codebuild[each.key].id
  policy = data.aws_iam_policy_document.codebuild_permissions[each.key].json
}

resource "aws_cloudwatch_log_group" "runner" {
  for_each = local.projects

  name              = "/aws/codebuild/${each.value.project_name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_codebuild_project" "runner" {
  for_each = local.projects

  name           = each.value.project_name
  description    = coalesce(each.value.description, "GitHub Actions ephemeral runner for ${each.value.repository_name}")
  service_role   = aws_iam_role.codebuild[each.key].arn
  build_timeout  = 60
  queued_timeout = 480

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type = "NO_CACHE"
  }

  environment {
    compute_type                = each.value.compute_type
    image                       = each.value.image
    type                        = each.value.environment
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "CODEBUILD_CONFIG_GITHUB_ACTIONS_RUNNER_GROUP_ID"
      value = tostring(var.runner_group_id)
    }
    environment_variable {
      name  = "CODEBUILD_CONFIG_GITHUB_ACTIONS_ORG_REGISTRATION_NAME"
      value = var.org_registration_name
    }
  }

  source {
    type      = "GITHUB"
    location  = each.value.repo_url
    buildspec = ""
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.runner[each.key].name
    }
  }

  tags = merge(var.tags, {
    "Repository" = each.value.repository_name
    "Purpose"    = "github-actions-runner"
  })
}

resource "aws_codebuild_webhook" "runner" {
  for_each = local.projects

  project_name = aws_codebuild_project.runner[each.key].name
  build_type   = "BUILD"

  filter_group {
    filter {
      type    = "EVENT"
      pattern = "WORKFLOW_JOB_QUEUED"
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "queued_duration_p95" {
  for_each = var.enable_alarms ? local.projects : {}

  alarm_name          = "${each.value.project_name}-queued-duration-p95"
  alarm_description   = "CodeBuild GitHub runner queue duration p95 is elevated."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 120
  treat_missing_data  = "notBreaching"
  namespace           = "AWS/CodeBuild"
  metric_name         = "QueuedDuration"
  period              = 60
  extended_statistic  = "p95"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions

  dimensions = {
    ProjectName = aws_codebuild_project.runner[each.key].name
  }
}

resource "aws_cloudwatch_metric_alarm" "duration_p95" {
  for_each = var.enable_alarms ? local.projects : {}

  alarm_name          = "${each.value.project_name}-duration-p95"
  alarm_description   = "CodeBuild GitHub runner execution duration is elevated."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 1800
  treat_missing_data  = "notBreaching"
  namespace           = "AWS/CodeBuild"
  metric_name         = "Duration"
  period              = 300
  extended_statistic  = "p95"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions

  dimensions = {
    ProjectName = aws_codebuild_project.runner[each.key].name
  }
}
