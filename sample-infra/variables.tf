
variable "aws_profile" {
  default = "automation-samples"
}

variable "aws_region" {
  default = "ap-southeast-2"
}

variable "aws_ami_id" {
  # Amazon Linux 2 AMI (HVM) - Kernel 5.10, SSD Volume Type
  default = "ami-0d6294dcaac5546e4"
}

variable "ssh_pair_private_key" {
  default = "~/.ssh/automation-samples"
}

variable "ssh_pair_public_key" {
  default = "~/.ssh/automation-samples.pub"
}
