locals {
  known_thumbprints = []

  github_organizations = toset([
    for repo, branch in var.allowed_sources : split("/", repo)[0]
  ])
}

data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

############################################################################################
# CREATE OIDC PROVIDER FOR GITHUB ACTIONS
############################################################################################
resource "aws_iam_openid_connect_provider" "this" {
  client_id_list = concat(
    [for org in local.github_organizations: "https://github.com/${org}"],
    ["sts.amazonaws.com"]
  )

  url = "https://token.actions.githubusercontent.com"
  
  thumbprint_list = concat(
    local.known_thumbprints,
    [data.tls_certificate.github.certificates[0].sha1_fingerprint]
  )
}