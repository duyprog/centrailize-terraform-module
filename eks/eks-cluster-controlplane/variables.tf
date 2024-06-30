# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETTERS
# ---------------------------------------------------------------------------------------------------------------------

variable "aws_partition" {
  description = "The AWS partition used for default AWS resources"
  type        = string
  default     = "aws"
}

# General EKS cluster properties

variable "cluster_name" {
  description = "The name of EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC in which EKS cluster's EC2 Instances will reside"
  type        = string
}

variable "vpc_control_plane_subnet_ids" {
  description = "A list of subnets into which the EKS Cluster's control plane nodes will be launched. They usually be all private subnets and include one in each AWS AZ"
  type        = list(string)
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL MODULE PARAMETERS
# ---------------------------------------------------------------------------------------------------------------------

variable "kubernetes_version" {
  description = "Version of Kubernetes to use"
  type        = string
  default     = "1.30"
}

variable "configure_openid_connect_provider" {
  description = "When set to true, this will inform the module to set up the OPENID Connect Provider for use with the IAM Roles for Service Accounts feature of EKS"
  type        = bool
  default     = true
}

variable "openid_connect_provider_thumbprint" {
  description = "The thumbprint to use for the OpenID Connect Provider"
  type        = string
  default     = null
}

variable "secret_envelope_encryption_kms_key_arn" {
  description = "ARN for KMS Key to use for envelope encryption of Kubernetes Secrets. By default Secrets in EKS are encrypted at rest using shared AWS managed keys"
  type        = string
  default     = null
}

variable "custom_tags_eks_cluster" {
  description = "A map of custom tags to apply to the EKS cluster"
  type        = map(string)
  default     = {}
  # Example 
  # {
  #   key1 = "value1"
  #   key2 = "value2"
  # }  
}

variable "custom_tags_security_group" {
  description = "A map of custom tags to apply to the security group for this EKS cluster"
  type        = map(string)
  default     = {}
}

variable "custom_tags_eks_addons" {
  description = "A map of custom tags to apply to the EKS addons"
  type        = map(string)
  default     = {}
}

variable "endpoint_public_access" {
  description = "Whether or not to enable public API endpoints which allow access to the Kubernetes API from outside VPC. Private access is always enable"
  type        = bool
  default     = true
}

variable "endpoint_public_access_cidrs" {
  description = "A list of CIDR blocks that should be allowed network access to the public Kubernetes API endpoint. Note that worker nodes automatically get access to the private endpoint, so this controls additional access. Note that this only restricts network reachability to the API, and does not account for authentication to the API. Note also that this only controls access to the private API endpoint, which is used for network access from inside the VPC. If you want to control access to the Kubernetes API from outside the VPC, then you must use the endpoint_public_access_cidrs."
  type        = list(string)
  default     = []
}

# variable "cluster_network_config_ip_family" {

# }

# variable "enabled_cluster_log_types" {

# }

variable "schedule_control_plane_services_on_fargate" {
  description = "When true, configures control plane services to run on Fargate so that the cluster can run without worker nodes. When true, requires kubergrunt to be available on the system."
  type        = bool
  default     = false
}

variable "cluster_iam_role_permissions_boundary" {
  description = "ARN of permissions boundary to apply to the cluster IAM role - the IAM role created for the EKS cluster as well as the default fargate IAM role."
  type        = string
  default     = null
}

variable "create_default_fargate_iam_role" {
  description = "When true, IAM role will be created and attached to Fargate control plane services. When true, requires that schedule_control_plane_services_on_fargate variable should be set true."
  type        = bool
  default     = true
}

variable "custom_fargate_iam_role_name" {
  description = "The name to use for the default Fargate execution IAM role that is created when create_default_fargate_iam_role is true. When null, defaults to CLUSTER_NAME-fargate-role."
  type        = string
  default     = null
}

variable "vpc_worker_subnet_ids" {
  description = "A list of the subnets into which the EKS Cluster's administrative pods will be launched. These should usually be all private subnets and include one in each AWS Availability Zone. Required when var.schedule_control_plane_services is true."
  type        = list(string)
  default     = []
}

variable "additional_security_groups" {
  description = "A list of additional security group IDs to attach to the control plane."
  type        = list(string)
  default     = []
}

variable "endpoint_private_access_cidrs" {
  description = "A list of CIDR blocks that should be allowed network access to the private Kubernetes API endpoint. Note that worker nodes automatically get access to the private endpoint, so this controls additional access. Note that this only restricts network reachability to the API, and does not account for authentication to the API. Note also that this only controls access to the private API endpoint, which is used for network access from inside the VPC. If you want to control access to the Kubernetes API from outside the VPC, then you must use the endpoint_public_access_cidrs."
  type        = list(string)
  default     = []
}

variable "endpoint_private_access_security_group_ids" {
  description = "Same as endpoint_private_access_cidrs, but exposes access to the provided list of security groups instead of CIDR blocks. The keys in the map are unique user defined identifiers that can be used for resource tracking purposes."
  # Ideally we can use a list(string) for this, but if we use a list and the security group is created in the same
  # module, then Terraform complains because the for_each keys are only knowable after apply.
  type    = map(string)
  default = {}
}

# VPC CNI Pod networking configurations for self-managed and managed node groups.

variable "vpc_cni_enable_prefix_delegation" {
  description = "When true, enable prefix delegation mode for the AWS VPC CNI component of the EKS cluster. In prefix delegation mode, each ENI will be allocated 16 IP addresses (/28) instead of 1, allowing you to pack more Pods per node. Note that by default, AWS VPC CNI will always preallocate 1 full prefix - this means that you can potentially take up 32 IP addresses from the VPC network space even if you only have 1 Pod on the node. You can tweak this behavior by configuring the var.vpc_cni_warm_ip_target input variable."
  type        = bool
  default     = false
}

variable "vpc_cni_warm_ip_target" {
  description = "The number of free IP addresses each node should maintain. When null, defaults to the aws-vpc-cni application setting (currently 16 as of version 1.9.0). In prefix delegation mode, determines whether the node will preallocate another full prefix. For example, if this is set to 5 and a node is currently has 9 Pods scheduled, then the node will NOT preallocate a new prefix block of 16 IP addresses. On the other hand, if this was set to the default value, then the node will allocate a new block when the first pod is scheduled."
  type        = number
  default     = null
}

variable "vpc_cni_minimum_ip_target" {
  description = "The minimum number of IP addresses (free and used) each node should start with. When null, defaults to the aws-vpc-cni application setting (currently 16 as of version 1.9.0). For example, if this is set to 25, every node will allocate 2 prefixes (32 IP addresses). On the other hand, if this was set to the default value, then each node will allocate only 1 prefix (16 IP addresses)."
  type        = number
  default     = null
}


# ---------------------------------------------------------------------------------------------------------------------
# MODULE DEPENDENCIES
# Workaround Terraform limitation where there is no module depends_on.
# See https://github.com/hashicorp/terraform/issues/1178 for more details.
# This can be used to make sure the module resources are created after other bootstrapping resources have been created.
# For example, you can pass in module.aws_auth_configmap.aws_auth_config_map_name to ensure the aws-auth ConfigMap
# exists before provisioning the control plane services Fargate Profile in this module.
# ---------------------------------------------------------------------------------------------------------------------

variable "fargate_profile_dependencies" {
  description = "Create a dependency between the control plane services Fargate Profile in this module to the interpolated values in this list (and thus the source resources). In other words, the resources in this module will now depend on the resources backing the values in this list such that those resources need to be created before the resources in this module, and the resources in this module need to be destroyed before the resources in the list."
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------------------------------------------------
# BACKWARD COMPATIBILITY FEATURE FLAGS
# The following variables are feature flags to enable and disable certain features in the module. These are primarily
# introduced to maintain backward compatibility by avoiding unnecessary resource creation.
# ---------------------------------------------------------------------------------------------------------------------

variable "create_cloudwatch_log_group" {
  description = "When true, precreate the CloudWatch Log Group to use for EKS control plane logging. This is useful if you wish to customize the CloudWatch Log Group with various settings such as retention periods and KMS encryption. When false, EKS will automatically create a basic log group to use. Note that logs are only streamed to this group if var.enabled_cluster_log_types is true."
  type        = bool
  default     = true
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "The ID (ARN, alias ARN, AWS ID) of a customer managed KMS Key to use for encrypting log data in the CloudWatch log group for EKS control plane logs."
  type        = string
  default     = null
}

variable "cloudwatch_log_group_tags" {
  description = "Tags to apply on the CloudWatch Log Group for EKS control plane logs, encoded as a map where the keys are tag keys and values are tag values."
  type        = map(string)
  default     = null
}

variable "cloudwatch_log_group_retention_in_days" {
  type        = number
  description = "Define retention in days of Cloud Watch log group"
}


variable "enable_eks_addons" {
  description = "When set to true, the module configures EKS add-ons (https://docs.aws.amazon.com/eks/latest/userguide/eks-add-ons.html) specified with `eks_addons`. VPC CNI configurations with `use_vpc_cni_customize_script` isn't fully supported with addons, as the automated add-on lifecycles could potentially undo the configuration changes."
  type        = bool
  default     = false
}

variable "eks_addons" {
  description = "Map of EKS add-ons, where key is name of the add-on and value is a map of add-on properties."
  type        = any
  default     = {}

  # EKS add-on advanced configuration via configuration_values must follow the configuration schema for the deployed version of the add-on.
  # See the following AWS Blog for more details on advanced configuration of EKS add-ons: https://aws.amazon.com/blogs/containers/amazon-eks-add-ons-advanced-configuration/
  # Example:
  #   eks_addons = {
  #     coredns    = {}
  #     kube-proxy = {}
  #     vpc-cni    = {
  #       addon_version        = "1.10.1-eksbuild.1"
  #       configuration_values = {
  #          ipvs      = {}
  #          mode      = "iptables"
  #          resources = {}
  #       }
  #       preserve                 = false
  #       resolve_conflicts        = "NONE"
  #       service_account_role_arn = "arn:aws:iam::123456789012:role/role-name"
  #     }
  #   }
}

# EBS CSI Driver feature configurations
variable "enable_ebs_csi_driver" {
  description = "When set to true, the module configures and install the EBS CSI Driver as an EKS managed AddOn (https://docs.aws.amazon.com/eks/latest/userguide/managing-ebs-csi.html). To use this feature, `configure_openid_connect_provider` must be set to true (the default value)."
  type        = bool
  default     = false
}

variable "ebs_csi_driver_sa_name" {
  description = "The Service Account name to be used with the EBS CSI Driver"
  type        = string
  default     = "ebs-csi-controller-sa"
}

variable "ebs_csi_driver_namespace" {
  description = "The namespace for the EBS CSI Driver. This will almost always be the kube-system namespace."
  type        = string
  default     = "kube-system"
}

variable "ebs_csi_driver_kms_key_arn" {
  description = "If using KMS encryption of EBS volumes, provide the KMS Key ARN to be used for a policy attachment."
  type        = string
  default     = null
}

variable "ebs_csi_driver_addon_config" {
  description = "Configuraiton object for the EBS CSI Driver EKS AddOn"
  type        = any
  default     = {}

  # EKS add-on advanced configuration via configuration_values must follow the configuration schema for the deployed version of the add-on.
  # See the following AWS Blog for more details on advanced configuration of EKS add-ons: https://aws.amazon.com/blogs/containers/amazon-eks-add-ons-advanced-configuration/
  # Example:
  # {
  #   addon_version        = "v1.14.0-eksbuild.1"
  #   configuration_values = {}
  #   preserve                 = false
  #   resolve_conflicts        = "NONE"
  #   service_account_role_arn = "arn:aws:iam::123456789012:role/role-name"
  # }
}

variable "ebs_csi_driver_addon_tags" {
  description = "A map of custom tags to apply to the EBS CSI Driver AddOn. The key is the tag name and the value is the tag value."
  type        = map(string)
  default     = {}

  # Example:
  #   {
  #     key1 = "value1"
  #     key2 = "value2"
  #   }
}

# Configuration of Kubernetes config context on operator's machine

variable "configure_kubectl" {
  description = "Whether or not to automatically configure kubectl on the current operator machine. To use this, you need a working python install with the AWS CLI installed and configured."
  type        = bool
  default     = false
}

variable "kubectl_config_context_name" {
  description = "Name of the kubectl config file context for accessing the EKS cluster."
  type        = string
  default     = ""
}

variable "kubectl_config_path" {
  description = "Path to the kubectl config file. Defaults to $HOME/.kube/config"
  type        = string
  default     = ""
}

# ---------------------------------------------------------------------------------------------------------------------
# BACKWARD COMPATIBILITY FEATURE FLAGS
# The following variables are feature flags to enable and disable certain features in the module. These are primarily
# introduced to maintain backward compatibility by avoiding unnecessary resource creation.
# ---------------------------------------------------------------------------------------------------------------------

variable "use_managed_iam_policies" {
  description = "When true, all IAM policies will be managed as dedicated policies rather than inline policies attached to the IAM roles. Dedicated managed policies are friendlier to automated policy checkers, which may scan a single resource for findings. As such, it is important to avoid inline policies when targeting compliance with various security standards."
  type        = bool
  default     = true
}

locals {
  use_inline_policies = var.use_managed_iam_policies == false
}
 