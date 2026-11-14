locals {
  new_network    = var.network_mode == "new"
  vcn_id         = local.new_network ? oci_core_vcn.main[0].id : var.existing_vcn_id
  subnet_id      = local.new_network ? oci_core_subnet.main[0].id : var.existing_subnet_id
  subnet_cidr    = local.new_network ? "10.42.1.0/24" : data.oci_core_subnet.existing[0].cidr_block
  selected_shape = try(one([for s in data.oci_core_shapes.available.shapes : s if s.name == var.shape]), null)
  image          = try(data.oci_core_images.ol9.images[0], null)
  # Numeric containment avoids Terraform-version-dependent CIDR helpers.
  ip_number    = try(sum([for i, octet in split(".", var.private_ip) : tonumber(octet) * pow(256, 3 - i)]), -1)
  subnet_first = sum([for i, octet in split(".", cidrhost(local.subnet_cidr, 0)) : tonumber(octet) * pow(256, 3 - i)])
  subnet_last  = sum([for i, octet in split(".", cidrhost(local.subnet_cidr, -1)) : tonumber(octet) * pow(256, 3 - i)])
}
data "oci_core_images" "ol9" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "9"
  shape                    = var.shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
  state                    = "AVAILABLE"
}
data "oci_identity_availability_domains" "selected_region" {
  compartment_id = var.compartment_ocid
  lifecycle {
    postcondition {
      condition     = contains([for ad in self.availability_domains : ad.name], var.availability_domain)
      error_message = "Availability domain does not belong to the selected provider region. Reselect region and AD; do not reuse saved selections."
    }
  }
}
data "oci_core_shapes" "available" {
  depends_on          = [data.oci_identity_availability_domains.selected_region]
  compartment_id      = var.compartment_ocid
  availability_domain = var.availability_domain
}
data "oci_core_subnet" "existing" {
  count     = local.new_network ? 0 : 1
  subnet_id = var.existing_subnet_id
  lifecycle {
    postcondition {
      condition     = self.vcn_id == var.existing_vcn_id && self.compartment_id == var.compartment_ocid
      error_message = "Existing subnet must belong to the selected VCN and compartment. Reselect network after changing region."
    }
    postcondition {
      condition     = self.availability_domain == null || self.availability_domain == "" || self.availability_domain == var.availability_domain
      error_message = "AD-specific subnet must match the selected availability domain; regional subnets are allowed."
    }
  }
}
data "oci_core_vcn" "existing" {
  count  = local.new_network ? 0 : 1
  vcn_id = var.existing_vcn_id
  lifecycle {
    postcondition {
      condition     = self.compartment_id == var.compartment_ocid
      error_message = "Existing VCN must belong to the selected compartment and be readable in the selected provider region."
    }
  }
}
resource "oci_core_vcn" "main" {
  count          = local.new_network ? 1 : 0
  compartment_id = var.compartment_ocid
  cidr_blocks    = ["10.42.0.0/16"]
  display_name   = "${var.instance_name}-vcn"
  dns_label      = "pocvcn"
}
resource "oci_core_internet_gateway" "main" {
  count          = local.new_network ? 1 : 0
  compartment_id = var.compartment_ocid
  vcn_id         = local.vcn_id
  enabled        = true
}
resource "oci_core_route_table" "main" {
  count          = local.new_network ? 1 : 0
  compartment_id = var.compartment_ocid
  vcn_id         = local.vcn_id
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.main[0].id
  }
}
# Empty owned list: all VM policy comes from our NSG, not VCN default SSH rules.
resource "oci_core_security_list" "empty" {
  count          = local.new_network ? 1 : 0
  compartment_id = var.compartment_ocid
  vcn_id         = local.vcn_id
  display_name   = "${var.instance_name}-empty"
}
resource "oci_core_subnet" "main" {
  count             = local.new_network ? 1 : 0
  compartment_id    = var.compartment_ocid
  vcn_id            = local.vcn_id
  cidr_block        = "10.42.1.0/24"
  dns_label         = "pocsubnet"
  route_table_id    = oci_core_route_table.main[0].id
  security_list_ids = [oci_core_security_list.empty[0].id]
}
resource "oci_core_network_security_group" "main" {
  depends_on     = [data.oci_core_vcn.existing, data.oci_core_subnet.existing, data.oci_identity_availability_domains.selected_region]
  compartment_id = var.compartment_ocid
  vcn_id         = local.vcn_id
  display_name   = "${var.instance_name}-ssh"
}
resource "oci_core_network_security_group_security_rule" "ssh" {
  network_security_group_id = oci_core_network_security_group.main.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = var.ssh_ingress_cidr
  source_type               = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}
resource "oci_core_network_security_group_security_rule" "egress" {
  network_security_group_id = oci_core_network_security_group.main.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
}
resource "oci_core_instance" "main" {
  compartment_id      = var.compartment_ocid
  availability_domain = var.availability_domain
  display_name        = var.instance_name
  shape               = var.shape
  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_in_gbs
  }
  source_details {
    source_type             = "image"
    source_id               = try(local.image.id, "")
    boot_volume_size_in_gbs = 50
  }
  create_vnic_details {
    subnet_id        = local.subnet_id
    assign_public_ip = var.public_ip_mode == "ephemeral"
    private_ip       = var.private_ip_mode == "manual" ? var.private_ip : null
    nsg_ids          = [oci_core_network_security_group.main.id]
  }
  # Public reserved IP attaches after instance creation; guest retries downloads meanwhile.
  metadata = {
    ssh_authorized_keys = trimspace(var.ssh_public_key)
    user_data = base64encode("#cloud-config\n${yamlencode({ write_files = [
      { path = "/usr/local/sbin/mattermost-bootstrap", permissions = "0700", content = file("${path.module}/cloud-init/bootstrap.sh") },
      { path = "/opt/mattermost/init-db.sh", permissions = "0644", content = file("${path.module}/cloud-init/init-db.sh") },
      { path = "/opt/mattermost/compose.yaml", permissions = "0600", content = file("${path.module}/compose.yaml") }
    ], runcmd = [["/usr/local/sbin/mattermost-bootstrap"]] })}")
  }
  lifecycle {
    precondition {
      condition     = try(local.image.size_in_mbs <= 50 * 1024, false)
      error_message = "No compatible Oracle Linux 9 image or image boot minimum exceeds fixed 50 GiB. Refusing enlargement."
    }
    precondition {
      condition     = try(var.ocpus >= local.selected_shape.ocpu_options[0].min && var.ocpus <= local.selected_shape.ocpu_options[0].max && var.memory_in_gbs >= local.selected_shape.memory_options[0].min_in_gbs && var.memory_in_gbs <= local.selected_shape.memory_options[0].max_in_gbs && var.memory_in_gbs / var.ocpus >= local.selected_shape.memory_options[0].min_per_ocpu_in_gbs && var.memory_in_gbs / var.ocpus <= local.selected_shape.memory_options[0].max_per_ocpu_in_gbs, false)
      error_message = "Shape unavailable in AD or OCPU/memory outside live shape bounds. Capacity/quota still require OCI launch validation."
    }
    precondition {
      condition     = local.new_network ? var.public_ip_mode != "none" : var.existing_network_ready
      error_message = "New private-only networking has no NAT and is unsupported. Existing network requires explicit egress, DNS and SSH/private-access confirmation."
    }
    precondition {
      condition     = local.new_network ? true : try(data.oci_core_subnet.existing[0].vcn_id == var.existing_vcn_id && (var.public_ip_mode == "none" || !data.oci_core_subnet.existing[0].prohibit_public_ip_on_vnic), false)
      error_message = "Existing subnet must belong to selected VCN and permit public IP when requested."
    }
    precondition {
      condition     = var.private_ip_mode == "auto" ? var.private_ip == "" : local.ip_number >= local.subnet_first + 2 && local.ip_number < local.subnet_last
      error_message = "Manual IPv4 must be in subnet, excluding OCI reserved first two and last addresses. Auto mode requires empty address. Availability is checked by OCI at launch."
    }
  }
}
data "oci_core_vnic_attachments" "main" {
  compartment_id = var.compartment_ocid
  instance_id    = oci_core_instance.main.id
}
data "oci_core_private_ips" "main" {
  vnic_id = data.oci_core_vnic_attachments.main.vnic_attachments[0].vnic_id
}
resource "oci_core_public_ip" "reserved" {
  count          = var.public_ip_mode == "reserved_new" ? 1 : 0
  compartment_id = var.compartment_ocid
  lifetime       = "RESERVED"
  display_name   = "${var.instance_name}-reserved"
  private_ip_id  = one([for ip in data.oci_core_private_ips.main.private_ips : ip.id if ip.is_primary])
}
