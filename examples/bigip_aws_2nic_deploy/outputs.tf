# BIG-IP Management Public IP Addresses
output "mgmtPublicIP" {
  value = module.bigip.*.mgmtPublicIP
}

# BIG-IP Management Public DNS Address
output "mgmtPublicDNS" {
  value = module.bigip.*.mgmtPublicDNS
}

# BIG-IP Management Port
output "mgmtPort" {
  value = module.bigip.*.mgmtPort
}

# BIG-IP Username
output "f5_username" {
  value = module.bigip.*.f5_username
}

# BIG-IP Password
output "bigip_password" {
  value = module.bigip.*.bigip_password
}

output "mgmtPublicURL" {
  description = "mgmtPublicURL"
  value       = length(flatten(module.bigip.*.mgmtPublicDNS)) > 0 ? [for i in range(var.instance_count) : format("https://%s:%s", module.bigip[i].mgmtPublicDNS[0], module.bigip[i].mgmtPort)] : tolist([])
}

# VPC ID used for BIG-IP Deploy
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_addresses" {
  description = "List of BIG-IP private addresses"
  value       = module.bigip.*.private_addresses
}

output "public_addresses" {
  description = "List of BIG-IP public addresses"
  value       = module.bigip.*.public_addresses
}

output "bigip_instance_ids" {
  value = module.bigip.*.bigip_instance_ids
}

output "external_private_primary_private_ip" {
  description = "List of BIG-IP private addresses"
  value       = [for i in range(length(module.bigip.*.private_addresses)) : module.bigip.*.private_addresses[i]["external_private"]["private_ip"]]
}

output "external_public_primary_private_ip" {
  description = "List of BIG-IP private addresses"
  value       = flatten([for i in range(length(module.bigip.*.private_addresses)) : module.bigip.*.private_addresses[i]["public_private"]["private_ip"]])
}

output "external_public_primary_private_ips" {
  description = "List of BIG-IP private addresses"
  value       = flatten([for i in range(length(module.bigip.*.private_addresses)) : module.bigip.*.private_addresses[i]["public_private"]["private_ips"]])
}

output "external_public_secondary_private_ips" {
  description = "List of BIG-IP private addresses"
  value = [
    for ip in flatten([for i in range(length(module.bigip.*.private_addresses)) : module.bigip.*.private_addresses[i]["public_private"]["private_ips"]]) :
    ip if ip != flatten([for i in range(length(module.bigip.*.private_addresses)) : module.bigip.*.private_addresses[i]["public_private"]["private_ips"]])[0]
  ]
}

// output tls_privatekey {
//   value = tls_private_key.example.private_key_pem
// }
