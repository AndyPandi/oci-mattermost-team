mock_provider "oci" {
  mock_data "oci_core_vcn" {
    defaults = { compartment_id = "test-compartment" }
  }
}
override_data {
  target = data.oci_identity_availability_domains.selected_region
  values = { availability_domains = [{ name = "test-ad" }] }
}
override_data {
  target = data.oci_core_images.ol9
  values = { images = [{ id = "test-image", display_name = "Oracle-Linux-9-test", size_in_mbs = 47719 }] }
}
override_data {
  target = data.oci_core_shapes.available
  values = { shapes = [{ name = "VM.Standard.E4.Flex", ocpu_options = [{ min = 1, max = 64 }], memory_options = [{ min_in_gbs = 1, max_in_gbs = 1024, min_per_ocpu_in_gbs = 1, max_per_ocpu_in_gbs = 64 }] }] }
}
variables {
  region              = "test-region"
  compartment_ocid    = "test-compartment"
  availability_domain = "test-ad"
  ssh_public_key      = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAITestOnly"
  ssh_ingress_cidr    = "203.0.113.1/32"
}
run "accept_world_ssh" {
  command = plan
  variables { ssh_ingress_cidr = "0.0.0.0/0" }
  assert {
    condition     = oci_core_network_security_group_security_rule.ssh.source == "0.0.0.0/0" && oci_core_network_security_group_security_rule.ssh.protocol == "6" && oci_core_network_security_group_security_rule.ssh.tcp_options[0].destination_port_range[0].min == 22 && oci_core_network_security_group_security_rule.ssh.tcp_options[0].destination_port_range[0].max == 22
    error_message = "Only TCP 22 must use the requested SSH CIDR."
  }
}
run "accept_broad_ssh" {
  command = plan
  variables { ssh_ingress_cidr = "10.0.0.0/8" }
  assert {
    condition     = oci_core_network_security_group_security_rule.ssh.source == "10.0.0.0/8" && oci_core_network_security_group_security_rule.ssh.protocol == "6" && oci_core_network_security_group_security_rule.ssh.tcp_options[0].destination_port_range[0].min == 22 && oci_core_network_security_group_security_rule.ssh.tcp_options[0].destination_port_range[0].max == 22
    error_message = "Only TCP 22 must use the requested SSH CIDR."
  }
}
run "accept_subnet_ssh" {
  command = plan
  variables { ssh_ingress_cidr = "203.0.113.0/24" }
  assert {
    condition     = oci_core_network_security_group_security_rule.ssh.source == "203.0.113.0/24" && oci_core_network_security_group_security_rule.ssh.protocol == "6" && oci_core_network_security_group_security_rule.ssh.tcp_options[0].destination_port_range[0].min == 22 && oci_core_network_security_group_security_rule.ssh.tcp_options[0].destination_port_range[0].max == 22
    error_message = "Only TCP 22 must use the requested SSH CIDR."
  }
}
run "accept_host_ssh" {
  command = plan
  variables { ssh_ingress_cidr = "203.0.113.1/32" }
  assert {
    condition     = oci_core_network_security_group_security_rule.ssh.source == "203.0.113.1/32" && oci_core_network_security_group_security_rule.ssh.protocol == "6" && oci_core_network_security_group_security_rule.ssh.tcp_options[0].destination_port_range[0].min == 22 && oci_core_network_security_group_security_rule.ssh.tcp_options[0].destination_port_range[0].max == 22
    error_message = "Only TCP 22 must use the requested SSH CIDR."
  }
}
run "reject_ssh_ipv6" {
  command = plan
  variables { ssh_ingress_cidr = "::/0" }
  expect_failures = [var.ssh_ingress_cidr]
}
run "reject_ssh_ipv6_host" {
  command = plan
  variables { ssh_ingress_cidr = "2001:db8::1/128" }
  expect_failures = [var.ssh_ingress_cidr]
}
run "reject_ssh_octet" {
  command = plan
  variables { ssh_ingress_cidr = "256.1.1.1/24" }
  expect_failures = [var.ssh_ingress_cidr]
}
run "reject_ssh_prefix" {
  command = plan
  variables { ssh_ingress_cidr = "203.0.113.1/33" }
  expect_failures = [var.ssh_ingress_cidr]
}
run "reject_ssh_negative_prefix" {
  command = plan
  variables { ssh_ingress_cidr = "203.0.113.1/-1" }
  expect_failures = [var.ssh_ingress_cidr]
}
run "reject_ssh_missing_prefix" {
  command = plan
  variables { ssh_ingress_cidr = "203.0.113.1" }
  expect_failures = [var.ssh_ingress_cidr]
}
run "reject_ssh_text" {
  command = plan
  variables { ssh_ingress_cidr = "not-a-cidr" }
  expect_failures = [var.ssh_ingress_cidr]
}
run "reject_arm" {
  command = plan
  variables {
    shape = "VM.Standard.A1.Flex"
  }
  expect_failures = [var.shape]
}
run "reject_ocpu" {
  command = plan
  variables {
    ocpus = 0.5
  }
  expect_failures = [var.ocpus]
}
run "reject_memory" {
  command = plan
  variables {
    memory_in_gbs = 4
  }
  expect_failures = [var.memory_in_gbs]
}
run "reject_ipv4" {
  command = plan
  variables {
    private_ip = "999.1.1.1"
  }
  expect_failures = [var.private_ip]
}
run "reject_existing_reserved" {
  command = plan
  variables {
    public_ip_mode = "reserved_existing"
  }
  expect_failures = [var.public_ip_mode]
}

run "valid_defaults" {
  command = plan
  assert {
    condition     = tonumber(oci_core_instance.main.source_details[0].boot_volume_size_in_gbs) == 50
    error_message = "Boot storage must remain fixed at 50 GiB."
  }
}
run "reject_new_private_only" {
  command = plan
  variables { public_ip_mode = "none" }
  expect_failures = [oci_core_instance.main]
}
run "reject_reserved_private_address" {
  command = plan
  variables {
    private_ip_mode = "manual"
    private_ip      = "10.42.1.1"
  }
  expect_failures = [oci_core_instance.main]
}
run "reject_outside_subnet" {
  command = plan
  variables {
    private_ip_mode = "manual"
    private_ip      = "192.0.2.10"
  }
  expect_failures = [oci_core_instance.main]
}
run "reject_shape_memory_ratio" {
  command = plan
  variables { memory_in_gbs = 128 }
  expect_failures = [oci_core_instance.main]
}
run "reject_large_image" {
  command = plan
  override_data {
    target = data.oci_core_images.ol9
    values = { images = [{ id = "large-image", display_name = "large", size_in_mbs = 60000 }] }
  }
  expect_failures = [oci_core_instance.main]
}

run "reject_vcn_mismatch" {
  command = plan
  variables {
    network_mode           = "existing"
    existing_vcn_id        = "test-vcn"
    existing_subnet_id     = "test-subnet"
    existing_network_ready = true
  }
  override_data {
    target = data.oci_core_subnet.existing[0]
    values = { compartment_id = "test-compartment", availability_domain = "", vcn_id = "other-vcn", cidr_block = "10.42.1.0/24", prohibit_public_ip_on_vnic = false }
  }
  expect_failures = [data.oci_core_subnet.existing]
}

run "reject_public_ip_prohibited" {
  command = plan
  variables {
    network_mode           = "existing"
    existing_vcn_id        = "test-vcn"
    existing_subnet_id     = "test-subnet"
    existing_network_ready = true
  }
  override_data {
    target = data.oci_core_subnet.existing[0]
    values = { compartment_id = "test-compartment", availability_domain = "", vcn_id = "test-vcn", cidr_block = "10.42.1.0/24", prohibit_public_ip_on_vnic = true }
  }
  expect_failures = [oci_core_instance.main]
}

run "reject_missing_network_confirmation" {
  command = plan
  variables {
    network_mode           = "existing"
    existing_vcn_id        = "test-vcn"
    existing_subnet_id     = "test-subnet"
    existing_network_ready = false
  }
  override_data {
    target = data.oci_core_subnet.existing[0]
    values = { compartment_id = "test-compartment", availability_domain = "", vcn_id = "test-vcn", cidr_block = "10.42.1.0/24", prohibit_public_ip_on_vnic = false }
  }
  expect_failures = [oci_core_instance.main]
}

run "reject_stale_region_ad" {
  command = plan
  override_data {
    target = data.oci_identity_availability_domains.selected_region
    values = { availability_domains = [{ name = "new-region-ad" }] }
  }
  expect_failures = [data.oci_identity_availability_domains.selected_region]
}
run "reject_private_ssh_key" {
  command = plan
  variables { ssh_public_key = "-----BEGIN OPENSSH PRIVATE KEY-----" }
  expect_failures = [var.ssh_public_key]
}
run "reject_multiple_ssh_keys" {
  command = plan
  variables { ssh_public_key = "ssh-ed25519 AAAATest\nssh-ed25519 AAAATest" }
  expect_failures = [var.ssh_public_key]
}
run "accept_public_key_file_newline" {
  command = plan
  variables { ssh_public_key = "ssh-ed25519 AAAATest comment\n" }
  assert {
    condition     = oci_core_instance.main.metadata.ssh_authorized_keys == "ssh-ed25519 AAAATest comment"
    error_message = "Public key file must remain a trimmed Terraform string, not base64 or a list."
  }
}

run "valid_existing_regional_subnet" {
  command = plan
  variables {
    network_mode           = "existing"
    existing_vcn_id        = "test-vcn"
    existing_subnet_id     = "test-subnet"
    existing_network_ready = true
  }
  override_data {
    target = data.oci_core_subnet.existing[0]
    values = { compartment_id = "test-compartment", availability_domain = "", vcn_id = "test-vcn", cidr_block = "10.42.1.0/24", prohibit_public_ip_on_vnic = false }
  }
}

run "valid_existing_ad_subnet" {
  command = plan
  variables {
    network_mode           = "existing"
    existing_vcn_id        = "test-vcn"
    existing_subnet_id     = "test-subnet"
    existing_network_ready = true
  }
  override_data {
    target = data.oci_core_subnet.existing[0]
    values = { compartment_id = "test-compartment", availability_domain = "test-ad", vcn_id = "test-vcn", cidr_block = "10.42.1.0/24", prohibit_public_ip_on_vnic = false }
  }
}

run "reject_stale_subnet_ad" {
  command = plan
  variables {
    network_mode           = "existing"
    existing_vcn_id        = "test-vcn"
    existing_subnet_id     = "test-subnet"
    existing_network_ready = true
  }
  override_data {
    target = data.oci_core_subnet.existing[0]
    values = { compartment_id = "test-compartment", availability_domain = "old-region-ad", vcn_id = "test-vcn", cidr_block = "10.42.1.0/24", prohibit_public_ip_on_vnic = false }
  }
  expect_failures = [data.oci_core_subnet.existing]
}

run "reject_subnet_compartment" {
  command = plan
  variables {
    network_mode           = "existing"
    existing_vcn_id        = "test-vcn"
    existing_subnet_id     = "test-subnet"
    existing_network_ready = true
  }
  override_data {
    target = data.oci_core_subnet.existing[0]
    values = { compartment_id = "other-compartment", availability_domain = "", vcn_id = "test-vcn", cidr_block = "10.42.1.0/24", prohibit_public_ip_on_vnic = false }
  }
  expect_failures = [data.oci_core_subnet.existing]
}

run "reject_vcn_compartment" {
  command = plan
  variables {
    network_mode           = "existing"
    existing_vcn_id        = "test-vcn"
    existing_subnet_id     = "test-subnet"
    existing_network_ready = true
  }
  override_data {
    target = data.oci_core_subnet.existing[0]
    values = { compartment_id = "test-compartment", availability_domain = "", vcn_id = "test-vcn", cidr_block = "10.42.1.0/24", prohibit_public_ip_on_vnic = false }
  }
  override_data {
    target = data.oci_core_vcn.existing[0]
    values = { compartment_id = "other-compartment" }
  }
  expect_failures = [data.oci_core_vcn.existing]
}
