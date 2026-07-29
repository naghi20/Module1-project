# ADVICE: Change the ID token to match your existing active EC2 server ID from AWS console
#import {
  to = aws_instance.elk_server
  id = "i-0eb7cba4221ec302a"
}
#resource "aws_instance" "elk_server" {
  # This block placeholder forces state synchronization when you execute 'terraform plan'
  ami           = "ami-02b64aa047cb5edf5"
  instance_type = "m7i-flex.large"
}
# Explicit Firewall Group for your pre-constructed logging engine
#resource "aws_security_group" "elk_sg" {
  name        = "production-elk-sg"
  description = "Accept ingress logs metrics from the new production VPC subnet"
  vpc_id      = module.vpc.vpc_id
  ingress {
    description     = "Logstash collection endpoint"
    from_port       = 5044
    to_port         = 5044
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }
  ingress {
    description = "Kibana dashboard administrative tracking interface access"
    from_port   = 5601
    to_port     = 5601
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Lock down to your office IP address in production
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}