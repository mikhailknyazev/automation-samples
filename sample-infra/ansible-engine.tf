
locals {
  connection = {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(pathexpand(var.ssh_pair_private_key))
  }
}

resource "aws_instance" "ansible-engine" {
  ami           = var.aws_ami_id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.ec2loginkey.key_name
  security_groups = ["sample-mvp-sg", "sample-mvp-webhooks-sg"]
  user_data       = file("user-data-ansible-engine-with-eda.sh")

  // Copy the "get-automation-sample-playbooks.sh" script to the remote machine
  provisioner "file" {
    source      = "files-for-upload/get-automation-sample-playbooks.sh"
    destination = "/home/ec2-user/get-automation-sample-playbooks.sh"
    connection {
      type        = local.connection["type"]
      user        = local.connection["user"]
      private_key = local.connection["private_key"]
      host        = self.public_ip
    }
  }

  // Copy the "openshift-prepare.sh" script to the remote machine
  provisioner "file" {
    source      = "files-for-upload/openshift-prepare.sh"
    destination = "/home/ec2-user/openshift-prepare.sh"
    connection {
      type        = local.connection["type"]
      user        = local.connection["user"]
      private_key = local.connection["private_key"]
      host        = self.public_ip
    }
  }

  // Copy the "webhook-prepare.sh" script to the remote machine
  provisioner "file" {
    source      = "files-for-upload/webhook-prepare.sh"
    destination = "/home/ec2-user/webhook-prepare.sh"
    connection {
      type        = local.connection["type"]
      user        = local.connection["user"]
      private_key = local.connection["private_key"]
      host        = self.public_ip
    }
  }

  # Create the initial ansible.cfg on the remote machine
  provisioner "file" {
    source      = "files-for-upload/ansible.cfg"
    destination = "/home/ec2-user/ansible.cfg"
    connection {
      type        = local.connection["type"]
      user        = local.connection["user"]
      private_key = local.connection["private_key"]
      host        = self.public_ip
    }
  }

  # Create the initial inventory.yaml on the remote machine
  provisioner "file" {
    content = templatefile("${path.module}/files-for-upload/inventory.tpl.yaml", {
      ansible-engine-host = aws_instance.ansible-engine.private_dns
      node1-host = aws_instance.ansible-nodes[0].private_dns
      node2-host = aws_instance.ansible-nodes[1].private_dns
      node3-host = aws_instance.ansible-nodes[2].private_dns
      // Note: The HA Proxy gets eventually deployed onto the "node3".
      //       We pass its public IP here for when we deploy the remote
      //       Health Checker targeting the HA Proxy.
      haproxy-public-ip = aws_instance.ansible-nodes[2].public_ip
    })
    destination = "/home/ec2-user/inventory.yaml"
    connection {
      type        = local.connection["type"]
      user        = local.connection["user"]
      private_key = local.connection["private_key"]
      host        = self.public_ip
    }
  }

  # Copy the "configure-datacentre.yaml" playbook to the remote machine
  provisioner "file" {
    source      = "files-for-upload/configure-datacentre.yaml"
    destination = "/home/ec2-user/configure-datacentre.yaml"
    connection {
      type        = local.connection["type"]
      user        = local.connection["user"]
      private_key = local.connection["private_key"]
      host        = self.public_ip
    }
  }

  # Execute the "configure-datacentre.yaml" when timely
  provisioner "remote-exec" {
    script = "wait-and-run-configure-datacentre.sh"
    connection {
      type        = local.connection["type"]
      user        = local.connection["user"]
      private_key = local.connection["private_key"]
      host        = self.public_ip
    }
  }

  tags = {
    Name = "ansible-engine"
  }

}
