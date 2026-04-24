locals {
  projects = {
    for key, repo in var.repositories :
    key => merge(repo, {
      project_name = "${var.name_prefix}-${key}"
      repo_url     = "https://github.com/${var.github_owner}/${repo.repository_name}.git"
    })
  }

  alarm_definitions = {
    queued_duration_p95 = {
      metric_name = "QueuedDuration"
      threshold   = 120
      period      = 60
      name_suffix = "queued-duration-p95"
      description = "CodeBuild GitHub runner queue duration p95 is elevated."
    }
    duration_p95 = {
      metric_name = "Duration"
      threshold   = 1800
      period      = 300
      name_suffix = "duration-p95"
      description = "CodeBuild GitHub runner execution duration is elevated."
    }
  }

  alarm_instances = merge([
    for alarm_key, alarm in local.alarm_definitions : {
      for proj_key, proj in local.projects :
      "${proj_key}:${alarm_key}" => {
        project_key  = proj_key
        project_name = proj.project_name
        metric_name  = alarm.metric_name
        threshold    = alarm.threshold
        period       = alarm.period
        name_suffix  = alarm.name_suffix
        description  = alarm.description
      }
    }
  ]...)
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
    resources = [
      aws_cloudwatch_log_group.runner[each.key].arn,
      "${aws_cloudwatch_log_group.runner[each.key].arn}:*"
    ]
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

resource "aws_cloudwatch_metric_alarm" "this" {
  for_each = var.enable_alarms ? local.alarm_instances : {}

  alarm_name          = "${each.value.project_name}-${each.value.name_suffix}"
  alarm_description   = each.value.description
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = each.value.threshold
  treat_missing_data  = "notBreaching"
  namespace           = "AWS/CodeBuild"
  metric_name         = each.value.metric_name
  period              = each.value.period
  extended_statistic  = "p95"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions

  dimensions = {
    ProjectName = aws_codebuild_project.runner[each.value.project_key].name
  }
}
