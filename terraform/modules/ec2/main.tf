resource "aws_security_group" "ec2-sg" {
  name        = "${var.service_name}-sg"
  description = "${var.service_name} security group"
  vpc_id      = "${var.vpc_id}"

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.project}-${var.vpc_prefix}-${var.service_name}-sg" }
}


resource "aws_instance" "ec2" {
  connection {
    # The default username for our AMI
    user = "ec2-user"
    agent = false
    type = "ssh"
    private_key = "${file(var.private_key_path)}"
    host = "${aws_instance.ec2.private_ip}"
    # The connection will use the local SSH agent for authentication.
  }
  associate_public_ip_address = false
  instance_type = "${var.aws_instance_type}"
  ami = "${var.ami_id}"
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.ec2-sg.id}", "${var.sg_id}"]
  subnet_id = "${var.subnet_id}"
  ebs_block_device {
    device_name = "/dev/sdb"
    volume_size = 50
    volume_type = "gp2"
    delete_on_termination = true
    encrypted = true
  }

  provisioner "remote-exec" {
    inline = [
      "${var.run_list}"

    ]
    connection {
     type = "ssh"
     host = "${aws_instance.ec2.private_ip}"
     user = "ec2-user"
     timeout = "7m"
     private_key = "${file(var.private_key_path)}"
     bastion_host    = "${var.bastion_ip}"
     bastion_user    = "${var.bastion_user}"
     bastion_private_key = "${file(var.private_key_path)}"

    }
  }
  tags = {
    Name = "${var.project}-${var.vpc_prefix}-${var.service_name}"
  }
}


