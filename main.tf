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
}
#
# Ensure Secret exists
#
data "aws_secretsmanager_secret" "password" {
  name = var.aws_secretmanager_secret_id
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
# Create Public Network Interfaces
#
resource "aws_network_interface" "public" {
  count             = length(local.external_public_subnet_id)
  subnet_id         = local.external_public_subnet_id[count.index]
  security_groups   = var.external_securitygroup_id
  private_ips_count = var.application_endpoint_count
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
  count                = var.f5_instance_count
  instance_type        = var.ec2_instance_type
  ami                  = data.aws_ami.f5_ami.id

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
  depends_on = [aws_eip.mgmt]

  tags = {
    Name = format("%s-%d", var.prefix, count.index)
  }
}


