output "project_badge" {
  value = aws_codebuild_project.project.badge_url
}

output "nginx_repo_url" {
  value = aws_ecr_repository.nginx.repository_url
}

output "nodejs_repo_url" {
  value = aws_ecr_repository.nodejs.repository_url
}
