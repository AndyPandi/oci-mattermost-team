output "instance_id" {
  value = oci_core_instance.main.id
}
output "ssh_host" {
  value = var.public_ip_mode == "reserved_new" ? oci_core_public_ip.reserved[0].ip_address : (var.public_ip_mode == "none" ? oci_core_instance.main.private_ip : oci_core_instance.main.public_ip)
}
output "access_instructions" {
  value = "Wait for cloud-init and mattermost.service; SSH tunnel: ssh -N -L 8065:127.0.0.1:8065 opc@<ssh_host>, then http://localhost:8065. Apply success does not mean application ready. No-public-IP requires an existing VPN/bastion route."
}
output "selected_image_name" {
  value = try(local.image.display_name, null)
}
