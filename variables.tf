variable "region" {
  type = string
}
variable "compartment_ocid" {
  type = string
}
variable "availability_domain" {
  type = string
}
variable "instance_name" {
  type    = string
  default = "poc-mattermost"
  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_-]{0,62}$", var.instance_name))
    error_message = "Use 1-63 letters, digits, underscores or hyphens, starting with a letter."
  }
}
variable "shape" {
  type    = string
  default = "VM.Standard.E4.Flex"
  validation {
    condition     = contains(["VM.Standard.E4.Flex", "VM.Standard.E5.Flex", "VM.Standard.E6.Flex", "VM.Standard3.Flex"], var.shape)
    error_message = "Only listed x86_64 Flex shapes support the pinned Team Edition image. A1/ARM is not supported."
  }
}
variable "ocpus" {
  type    = number
  default = 1
  validation {
    condition     = var.ocpus >= 1 && floor(var.ocpus) == var.ocpus
    error_message = "OCPUs must be a positive integer; live shape bounds are also checked."
  }
}
variable "memory_in_gbs" {
  type    = number
  default = 8
  validation {
    condition     = var.memory_in_gbs >= 8 && floor(var.memory_in_gbs) == var.memory_in_gbs
    error_message = "At least 8 GiB and an integer are required; live shape bounds are also checked."
  }
}
variable "ssh_public_key" {
  type = string
  validation {
    condition     = can(regex("^(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp(256|384|521)) [A-Za-z0-9+/=]+( [^\n]*)?$", trimspace(var.ssh_public_key)))
    error_message = "Supply one OpenSSH public key, never a private key."
  }
}
variable "ssh_ingress_cidr" {
  type = string
  validation {
    condition     = can(cidrnetmask(var.ssh_ingress_cidr)) && try(tonumber(split("/", var.ssh_ingress_cidr)[1]) >= 24, false)
    error_message = "SSH requires a restricted IPv4 CIDR /24 through /32; 0.0.0.0/0 is forbidden."
  }
}
variable "network_mode" {
  type    = string
  default = "new"
  validation {
    condition     = contains(["new", "existing"], var.network_mode)
    error_message = "Choose new or existing."
  }
}
variable "existing_vcn_id" {
  type    = string
  default = ""
}
variable "existing_subnet_id" {
  type    = string
  default = ""
}
variable "public_ip_mode" {
  type    = string
  default = "ephemeral"
  validation {
    condition     = contains(["ephemeral", "reserved_new", "none"], var.public_ip_mode)
    error_message = "Choose ephemeral, reserved_new, or none. Existing reserved IP adoption is deliberately unsupported."
  }
}
variable "existing_network_ready" {
  type        = bool
  default     = false
  description = "Confirm existing subnet has DNS and outbound HTTPS/package/registry access, appropriate routes, and restricted SSH/private access. Shared lists can broaden NSG permissions."
}
variable "private_ip_mode" {
  type    = string
  default = "auto"
  validation {
    condition     = contains(["auto", "manual"], var.private_ip_mode)
    error_message = "Choose auto or manual."
  }
}
variable "private_ip" {
  type    = string
  default = ""
  validation {
    condition     = var.private_ip == "" || can(cidrnetmask("${var.private_ip}/32"))
    error_message = "Enter a plain IPv4 address, not CIDR."
  }
}
