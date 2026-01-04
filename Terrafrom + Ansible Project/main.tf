provider "aws" {
 region = "us-east-1"
}

resource "aws_instance" "ec2_instance" {
 count = var.number_of_instances
 ami = var.ami_id
 subnet_id = var.subnet_id
 instance_type = var.instance_type
 key_name = var.ami_key_pair_name
 security_groups = ["sg-033fae84011d5727d"]
 tags = {
 Name = "${var.instance_name}-${count.index + 1}" # Unique name for each instance
 }
}

resource "null_resource" "configure_ssh" {
 count = var.number_of_instances
 connection {
 type = "ssh"
 host = aws_instance.ec2_instance[count.index].public_ip
 user = "ubuntu"
 private_key = file("/home/ubuntu/terraform/Jenkins-Project.pem")
 }
 provisioner "file" {
 source = "/home/ubuntu/.ssh/id_ed25519.pub"
 destination = "/home/ubuntu/id_ed25519.pub"
 }
 provisioner "remote-exec" {
 inline = [
 "mkdir -p ~/.ssh",
 "cat /home/ubuntu/id_ed25519.pub >> ~/.ssh/authorized_keys",
 "chmod 700 ~/.ssh",
 "chmod 600 ~/.ssh/authorized_keys"
 ]
 }
}

resource "null_resource" "disable_strict_host_key_checking" {
 count = var.number_of_instances
 connection {
 type = "ssh"
 host = aws_instance.ec2_instance[count.index].public_ip
 user = "ubuntu"
 private_key = file("/home/ubuntu/terraform/Jenkins-Project.pem")
 }
 provisioner "remote-exec" {
 inline = [
 "echo 'Host *' >> ~/.ssh/config",
 "echo ' StrictHostKeyChecking no' >> ~/.ssh/config",
 "echo ' UserKnownHostsFile=/dev/null' >> ~/.ssh/config",
 "echo ' LogLevel ERROR' >> ~/.ssh/config"
 ]
 }
 depends_on = [aws_instance.ec2_instance]
}

output "vm_info" {
 value = { for idx, instance in aws_instance.ec2_instance : "${instance.tags.Name}" =>
instance.public_ip }
}
