variable "allowed_sources" {
  description = "Map of github repositories to the list of branches that are allowed to assume the IAM role. The repository should be encoded as org/repo-name"
  type = map(list(string))
}

variable "additional_thumbprints" {
  default = null 
  description = "List of additional thumbprints for the OIDC provider"
  type = list(string)
}