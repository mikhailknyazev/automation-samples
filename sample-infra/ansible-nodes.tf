resource "aws_instance" "ansible-nodes" {
  ami             = var.aws_ami_id
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.ec2loginkey.key_name
  count           = 3
  security_groups = ["sample-mvp-sg"]
  user_data       = file("user-data-ansible-nodes.sh")
  tags = {
    Name = "ansible-node-${count.index + 1}"
  }
}
