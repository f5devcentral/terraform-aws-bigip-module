variable "prefix" {
  description = "Prefix for resources created by this module"
  type        = string
  default     = "tf-aws-bigip"
}

variable "f5_ami_search_name" {
  description = "BIG-IP AMI name to search for"
  type        = string
  default     = "F5 Networks BIGIP-14.* PAYG - Best 200Mbps*"
}

variable "f5_instance_count" {
  description = "Number of BIG-IPs to deploy"
  type        = number
  default     = 1
}

variable "application_endpoint_count" {
  description = "number of public application addresses to assign"
  type        = number
  default     = 1
}

variable "ec2_instance_type" {
  description = "AWS EC2 instance type"
  type        = string
  default     = "m5.large"
}

variable "ec2_key_name" {
  description = "AWS EC2 Key name for SSH access"
  type        = string
  default = "tf-demo-key"
}

variable "mgmt_eip" {
  description = "Enable an Elastic IP address on the management interface"
  type        = bool
  default     = true
}
variable "aws_secretmanager_secret_id" {
  description = "AWS Secret Manager Secret ID that stores the BIG-IP password"
  type        = string
}

variable mgmt_subnet_id {
  description = "The subnet id of the virtual network where the virtual machines will reside."
  type = list(object({
    subnet_id = string
    public_ip = bool
  }))
}

variable external_subnet_id {
  description = "The subnet id of the virtual network where the virtual machines will reside."
  type = list(object({
    subnet_id = string
    public_ip = bool
  }))
  default = [{ "subnet_id" = null, "public_ip" = null }]
}

variable internal_subnet_id {
  description = "The subnet id of the virtual network where the virtual machines will reside."
  type = list(object({
    subnet_id = string
    public_ip = bool
  }))
  default = [{ "subnet_id" = null, "public_ip" = null }]
}


variable mgmt_securitygroup_id {
  description = "The Network Security Group ids for management network "
  type        = list(string)
}

variable external_securitygroup_id {
  description = "The Network Security Group ids for external network "
  type        = list(string)
  default     = []
}

variable internal_securitygroup_id {
  description = "The Network Security Group ids for internal network "
  type        = list(string)
  default     = []
}
