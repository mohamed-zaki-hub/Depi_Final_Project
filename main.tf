provider "aws" {
    region = "us-east-1"
}

variable avail-zone {}
variable vpc-cidr-block {}
variable subnet-cidr-block {}
variable instance-type {}
variable public-key-loc {}


resource "aws_vpc" "app-vpc"{
    cidr_block = var.vpc-cidr-block
    tags = {
        Name = "app-vpc"
    }
}
resource "aws_subnet" "app-subnet" {
    vpc_id = aws_vpc.app-vpc.id
    cidr_block = var.subnet-cidr-block
    availability_zone = var.avail-zone
    tags = {
        Name = "app-subnet"
    }
}

resource "aws_internet_gateway" "app-igateway" {
    vpc_id = aws_vpc.app-vpc.id
    tags = {
        Name = "app-igateway"
    }
}
resource "aws_default_route_table" "main-app-rtb" {
    default_route_table_id = aws_vpc.app-vpc.default_route_table_id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.app-igateway.id
    }
    tags = {
        Name = "app-main-rtb"
    }
}

resource "aws_security_group" "app-sec-group"{
    name   = "app-sec-group"
    vpc_id = aws_vpc.app-vpc.id
    # to make ssh from
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = []
    } 
    tags = {
        Name = "app-sg"
    }   
}

data "aws_ami" "ubuntu-image" {

    most_recent = true
    owners      = ["099720109477"] # Canonical's AWS Account ID
    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    }
    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }
}

resource "aws_key_pair" "app-key" {
    key_name = "app-key"
    public_key = file(var.public-key-loc)
}

resource "aws_instance" "jenkins-master" {
    ami = data.aws_ami.ubuntu-image.id
    instance_type = var.instance-type
    subnet_id = aws_subnet.app-subnet.id
    vpc_security_group_ids = [aws_security_group.app-sec-group.id]
    associate_public_ip_address = true
    key_name = aws_key_pair.app-key.key_name
    availability_zone = var.avail-zone
    tags = {
        Name = "jenkins-master"
    }
}

resource "aws_instance" "jenkins-agent" {
    ami = data.aws_ami.ubuntu-image.id
    instance_type = var.instance-type
    subnet_id = aws_subnet.app-subnet.id
    vpc_security_group_ids = [aws_security_group.app-sec-group.id]
    associate_public_ip_address = true
    key_name = aws_key_pair.app-key.key_name
    availability_zone = var.avail-zone
    tags = {
        Name = "jenkins-agent"
    }
}
resource "aws_instance" "sonarqube" {
    ami = data.aws_ami.ubuntu-image.id
    instance_type = "t3.medium"
    subnet_id = aws_subnet.app-subnet.id
    vpc_security_group_ids = [aws_security_group.app-sec-group.id]
    associate_public_ip_address = true
    key_name = aws_key_pair.app-key.key_name
    availability_zone = var.avail-zone
    tags = {
        Name = "sonarqube"
    }
}
output "jenkins_master_public_ip" {
  value = aws_instance.jenkins-master.public_ip
}

output "jenkins_agent_public_ip" {
  value = aws_instance.jenkins-agent.public_ip
}

