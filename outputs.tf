# BIG-IP Management Public IP Addresses
output mgmt_public_ips {
  description = "List of BIG-IP public IP addresses for the management interfaces"
  value       = aws_eip.mgmt[*].public_ip
}

# BIG-IP Management Public DNS
output mgmt_public_dns {
  description = "List of BIG-IP public DNS records for the management interfaces"
  value       = aws_eip.mgmt[*].public_dns
}

# BIG-IP Management Port
output mgmt_port {
  description = "HTTPS Port used for the BIG-IP management interface"
  value       = local.total_nics > 1 ? "443" : "8443"
}

output mgmt_addresses {
  description = "List of BIG-IP management addresses"
  value       = aws_network_interface.mgmt[*].private_ips
}

output f5_username {
  value = var.f5_username
}

output bigip_password {
  description = <<-EOT
 "Password for bigip user ( if dynamic_password is choosen it will be random generated password or if azure_keyvault is choosen it will be key vault secret name )
  EOT
  value       = var.aws_secretmanager_auth ? data.aws_secretsmanager_secret_version.current[0].secret_string : random_string.dynamic_password.result
}

output bigip_privateips {
  value = concat(aws_network_interface.public.*.private_ips, aws_network_interface.external_private.*.private_ips, aws_network_interface.private.*.private_ips)
}

output bigip_publicips {
  value = concat(aws_eip.ext-pub.*.public_ip)
}

output bigip_nic_ids {
  value = concat(aws_network_interface.public.*.id, aws_network_interface.external_private.*.id, aws_network_interface.private.*.id)
  //value = local.bigip_nics_map
}

output onboard_do {
  value      = local.total_nics > 1 ? (local.total_nics == 2 ? data.template_file.clustermemberDO2[0].rendered : data.template_file.clustermemberDO3[0].rendered) : data.template_file.clustermemberDO1[0].rendered
  depends_on = [data.template_file.clustermemberDO1[0], data.template_file.clustermemberDO2[0], data.template_file.clustermemberDO3[0]]
}
