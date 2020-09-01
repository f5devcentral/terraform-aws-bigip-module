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
  value       = length(var.external_subnet_id) > 0 ? "443" : "8443"
}

# Public Network Interface
output public_nic_ids {
  description = "List of BIG-IP public network interface ids"
  value       = aws_network_interface.public[*].id
}

output mgmt_addresses {
  description = "List of BIG-IP management addresses"
  value       = aws_network_interface.mgmt[*].private_ips
}

output public_addresses {
  description = "List of BIG-IP public addresses"
  value       = aws_network_interface.public[*].private_ips
}

output private_addresses {
  description = "List of BIG-IP private addresses"
  value       = aws_network_interface.private[*].private_ips
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
