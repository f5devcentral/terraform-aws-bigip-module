# BIG-IP Management Public IP Addresses
output bigip_mgmt_ips {
  value = module.bigip.*.mgmt_public_ips
}

# BIG-IP Management Public DNS Address
output bigip_mgmt_dns {
  value = module.bigip.*.mgmt_public_dns
}

# BIG-IP Management Port
output bigip_mgmt_port {
  value = module.bigip.*.mgmt_port
}

# BIG-IP Username
output bigip_username {
  value = module.bigip.*.f5_username
}

# BIG-IP Password
output bigip_password {
  value = module.bigip.*.bigip_password
}

# VPC ID used for BIG-IP Deploy
output vpc_id {
  value = module.vpc.vpc_id
}

output bigip_privateips {
  value = module.bigip.*.bigip_privateips
}

output bigip_publicips {
  value = module.bigip.*.bigip_publicips
}

/*
# BIG-IP Password Secret name
output "aws_secretmanager_secret_name" {
  value = aws_secretsmanager_secret.bigip.name
}

# BIG-IP Password Secret name
output "tls_rsa_private_key" {
  value = tls_private_key.example.private_key_pem
}
*/