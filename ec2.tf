locals {
  vpc_id           = "vpc-35800f5e"
  subnet_id        = "subnet-331cf14e"
  ssh_user         = "ubuntu"
  key_name         = "devops"
  private_key_path = "~/Downloads/devops.pem"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
          }
                    }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-2"
  access_key = ""
  secret_key = ""

}

resource "aws_security_group" "http_ssh" {
  name        = "allow_http_ssh"
  description = "Allow HTTP_SSH inbound traffic"
  vpc_id      = local.vpc_id

  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]

#    ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

 ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
}

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_http"
  }
}


#resource "aws_network_interface_sg_attachment" "sg_attachment" {
#  security_group_id    = "${aws_security_group.http_ssh.id}"
#  network_interface_id = "eni-03b1ce99c64b17828"
#}




resource "aws_instance" "ter" {
  ami                         = "ami-08962a4068733a2b6"
  instance_type               = "t2.micro"
  subnet_id                   = local.subnet_id
  associate_public_ip_address = true
  security_groups         = [aws_security_group.http_ssh.id]
  key_name                    = local.key_name
  
  provisioner "remote-exec" {
    inline = ["echo 'Wait until ssh is deady'"]


    connection  {
      type         = "ssh"
      user         = local.ssh_user
      private_key  = file(local.private_key_path)
      host         = aws_instance.ter.public_ip
#     command      = "ansible-playbook playbook.yml -i inventory"
    }

  }  
   provisioner "local-exec" {
     command = "ansible-playbook -i ${aws_instance.ter.public_ip}, --private-key ${local.private_key_path} playbook.yml "
   }
}

output "ter_ip"{
  value = aws_instance.ter.public_ip
}
