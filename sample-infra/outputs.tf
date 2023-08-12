
output "ansible-engine" {
  value = aws_instance.ansible-engine.public_ip
}

output "ansible-node-1" {
  value = aws_instance.ansible-nodes[0].public_ip
}

output "ansible-node-2" {
  value = aws_instance.ansible-nodes[1].public_ip
}

output "ansible-node-3" {
  value = aws_instance.ansible-nodes[2].public_ip
}
