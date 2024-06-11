output "provider_arn" {
  value = aws_iam_openid_connect_provider.this.arn
}

output "provider_url" {
  value = aws_iam_openid_connect_provider.this.url
}