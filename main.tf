locals {
  bigip_map = {
    "mgmt_subnet_id"            = var.mgmt_subnet_id
    "mgmt_securitygroup_id"     = var.mgmt_securitygroup_id
    "external_subnet_id"        = var.external_subnet_id
    "external_securitygroup_id" = var.external_securitygroup_id
    "internal_subnet_id"        = var.internal_subnet_id
    "internal_securitygroup_id" = var.internal_securitygroup_id
  }
  mgmt_public_subnet_id = [
    for subnet in local.bigip_map["mgmt_subnet_id"] :
    subnet["subnet_id"]
    if subnet["public_ip"] == true
  ]
  mgmt_public_index = [
    for index, subnet in local.bigip_map["mgmt_subnet_id"] :
    index
    if subnet["public_ip"] == true
  ]
  mgmt_public_security_id = [
    for i in local.mgmt_public_index : local.bigip_map["mgmt_securitygroup_id"][i]
  ]
  mgmt_private_subnet_id = [
    for subnet in local.bigip_map["mgmt_subnet_id"] :
    subnet["subnet_id"]
    if subnet["public_ip"] == false
  ]
  mgmt_private_index = [
    for index, subnet in local.bigip_map["mgmt_subnet_id"] :
    index
    if subnet["public_ip"] == false
  ]
  mgmt_private_security_id = [
    for i in local.external_private_index : local.bigip_map["mgmt_securitygroup_id"][i]
  ]
  external_public_subnet_id = [
    for subnet in local.bigip_map["external_subnet_id"] :
    subnet["subnet_id"]
    if subnet["public_ip"] == true
  ]
  external_public_index = [
    for index, subnet in local.bigip_map["external_subnet_id"] :
    index
    if subnet["public_ip"] == true
  ]
  external_public_security_id = [
    for i in local.external_public_index : local.bigip_map["external_securitygroup_id"][i]
  ]
  external_private_subnet_id = [
    for subnet in local.bigip_map["external_subnet_id"] :
    subnet["subnet_id"]
    if subnet["public_ip"] == false
  ]
  external_private_index = [
    for index, subnet in local.bigip_map["external_subnet_id"] :
    index
    if subnet["public_ip"] == false
  ]
  external_private_security_id = [
    for i in local.external_private_index : local.bigip_map["external_securitygroup_id"][i]
  ]
  internal_public_subnet_id = [
    for subnet in local.bigip_map["internal_subnet_id"] :
    subnet["subnet_id"]
    if subnet["public_ip"] == true
  ]
  internal_public_index = [
    for index, subnet in local.bigip_map["internal_subnet_id"] :
    index
    if subnet["public_ip"] == true
  ]
  internal_public_security_id = [
    for i in local.internal_public_index : local.bigip_map["internal_securitygroup_id"][i]
  ]
  internal_private_subnet_id = [
    for subnet in local.bigip_map["internal_subnet_id"] :
    subnet["subnet_id"]
    if subnet["public_ip"] == false
  ]
  internal_private_index = [
    for index, subnet in local.bigip_map["internal_subnet_id"] :
    index
    if subnet["public_ip"] == false
  ]
  internal_private_security_id = [
    for i in local.internal_private_index : local.bigip_map["internal_securitygroup_id"][i]
  ]
  total_nics       = length(concat(local.mgmt_public_subnet_id, local.mgmt_private_subnet_id, local.external_public_subnet_id, local.external_private_subnet_id, local.internal_public_subnet_id, local.internal_private_subnet_id))
  vlan_list        = concat(local.external_public_subnet_id, local.external_private_subnet_id, local.internal_public_subnet_id, local.internal_private_subnet_id)
  selfip_list_temp = concat(aws_network_interface.public.*.private_ips, aws_network_interface.private.*.private_ips)
  selfip_list      = flatten(local.selfip_list_temp)
  //azurerm_network_interface.external_public_nic.*.private_ip_address, azurerm_network_interface.internal_nic.*.private_ip_address)
  instance_prefix = format("%s-%s", var.prefix, random_id.module_id.hex)

}

#
# Create a random id
#
resource "random_id" "module_id" {
  byte_length = 2
}

#
# Create random password for BIG-IP
#
resource random_string dynamic_password {
  length      = 16
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
  special     = false
}

#
# Ensure Secret exists
#
data "aws_secretsmanager_secret" "password" {
  count = var.aws_secretmanager_auth ? 1 : 0
  name  = var.aws_secretmanager_secret_id
}

data "aws_secretsmanager_secret_version" "current" {
  count     = var.aws_secretmanager_auth ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.password[count.index].id
  //depends_on =[data.aws_secretsmanager_secret.password]
}
#
# Find BIG-IP AMI
#
data "aws_ami" "f5_ami" {
  most_recent = true
  owners      = ["679593333241"]

  filter {
    name   = "name"
    values = ["${var.f5_ami_search_name}"]
  }
}

#
# Create Management Network Interfaces
#
resource "aws_network_interface" "mgmt" {
  count           = length(local.bigip_map["mgmt_subnet_id"])
  subnet_id       = local.bigip_map["mgmt_subnet_id"][count.index]["subnet_id"]
  security_groups = var.mgmt_securitygroup_id
}

#
# add an elastic IP to the BIG-IP management interface
#
resource "aws_eip" "mgmt" {
  count             = var.mgmt_eip ? length(var.external_subnet_id) : 0
  network_interface = aws_network_interface.mgmt[count.index].id
  vpc               = true
}

#
# Create Public External Network Interfaces
#
resource "aws_network_interface" "public" {
  count           = length(local.external_public_subnet_id)
  subnet_id       = local.external_public_subnet_id[count.index]
  security_groups = var.external_securitygroup_id
  //private_ips_count = var.application_endpoint_count
}

#
# Create Private External Network Interfaces
#
resource "aws_network_interface" "external_private" {
  count           = length(local.external_private_subnet_id)
  subnet_id       = local.external_private_subnet_id[count.index]
  security_groups = var.external_securitygroup_id
  //private_ips_count = var.application_endpoint_count
}

#
# Create Private Network Interfaces
#
resource "aws_network_interface" "private" {
  count           = length(local.internal_private_subnet_id)
  subnet_id       = local.internal_private_subnet_id[count.index]
  security_groups = var.internal_securitygroup_id
}


# Deploy BIG-IP
#
resource "aws_instance" "f5_bigip" {
  # determine the number of BIG-IPs to deploy
  count         = var.f5_instance_count
  instance_type = var.ec2_instance_type
  ami           = data.aws_ami.f5_ami.id
  key_name      = var.ec2_key_name

  root_block_device {
    delete_on_termination = true
  }

  # set the mgmt interface
  dynamic "network_interface" {
    for_each = toset([aws_network_interface.mgmt[count.index].id])

    content {
      network_interface_id = network_interface.value
      device_index         = 0
    }
  }

  # set the public interface only if an interface is defined
  dynamic "network_interface" {
    for_each = length(aws_network_interface.public) > count.index ? toset([aws_network_interface.public[count.index].id]) : toset([])

    content {
      network_interface_id = network_interface.value
      device_index         = 1
    }
  }

  # set the private interface only if an interface is defined
  dynamic "network_interface" {
    for_each = length(aws_network_interface.private) > count.index ? toset([aws_network_interface.private[count.index].id]) : toset([])

    content {
      network_interface_id = network_interface.value
      device_index         = 2
    }
  }

  # build user_data file from template
  user_data = var.custom_user_data != null ? var.custom_user_data : templatefile(
    "${path.module}/f5_onboard.tmpl",
    {
      DO_URL         = var.DO_URL,
      AS3_URL        = var.AS3_URL,
      TS_URL         = var.TS_URL,
      CFE_URL        = var.CFE_URL,
      FAST_URL       = var.fastPackageUrl
      libs_dir       = var.libs_dir,
      onboard_log    = var.onboard_log,
      bigip_username = var.f5_username
      bigip_password = var.aws_secretmanager_auth ? data.aws_secretsmanager_secret_version.current[0].secret_string : random_string.dynamic_password.result
    }
  )
  depends_on = [aws_eip.mgmt, aws_network_interface.public, aws_network_interface.private]

  tags = {
    Name = format("%s-%d", local.instance_prefix, count.index)
  }
}

data template_file clustermemberDO1 {
  count    = local.total_nics == 1 ? 1 : 0
  template = "${file("${path.module}/onboard_do_1nic.tpl")}"
  vars = {
    hostname      = aws_eip.mgmt[0].public_dns
    name_servers  = join(",", formatlist("\"%s\"", ["168.63.129.16"]))
    search_domain = "f5.com"
    ntp_servers   = join(",", formatlist("\"%s\"", ["0.pool.ntp.org", "1.pool.ntp.org", "2.pool.ntp.org"]))
  }
}

data template_file clustermemberDO2 {
  count    = local.total_nics == 2 ? 1 : 0
  template = file("${path.module}/onboard_do_2nic.tpl")
  vars = {
    hostname      = aws_eip.mgmt[0].public_dns
    name_servers  = join(",", formatlist("\"%s\"", ["168.63.129.16"]))
    search_domain = "f5.com"
    ntp_servers   = join(",", formatlist("\"%s\"", ["0.pool.ntp.org", "1.pool.ntp.org", "2.pool.ntp.org"]))
    vlan-name     = element(split("/", local.vlan_list[0]), length(split("/", local.vlan_list[0])) - 1)
    self-ip       = local.selfip_list[0]
  }
  depends_on = [aws_network_interface.public, aws_network_interface.private]
}

data template_file clustermemberDO3 {
  count    = local.total_nics == 3 ? 1 : 0
  template = file("${path.module}/onboard_do_3nic.tpl")
  vars = {
    hostname      = aws_eip.mgmt[0].public_dns
    name_servers  = join(",", formatlist("\"%s\"", ["168.63.129.16"]))
    search_domain = "f5.com"
    ntp_servers   = join(",", formatlist("\"%s\"", ["0.pool.ntp.org", "1.pool.ntp.org", "2.pool.ntp.org"]))
    vlan-name1    = element(split("/", local.vlan_list[0]), length(split("/", local.vlan_list[0])) - 1)
    self-ip1      = local.selfip_list[0]
    vlan-name2    = element(split("/", local.vlan_list[1]), length(split("/", local.vlan_list[1])) - 1)
    self-ip2      = local.selfip_list[1]
  }
  depends_on = [aws_network_interface.public, aws_network_interface.private]
}
