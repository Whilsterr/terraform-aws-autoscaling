### Load balancer, relié security group + subnets
### Internal à false car accès internet
### enable_deletion_protection à false si besoin de destroy
resource "aws_lb" "front_end" {
  name               = "alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.discovery.public_subnets

  enable_deletion_protection = false
}

###Target group sur le port 8080 (Port nginx des instances)
resource "aws_lb_target_group" "alb_target_group" {
  name     = "alb-target-group"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = module.discovery.vpc_id
}

resource "aws_lb_target_group" "alb_target_group_2" {
  name     = "alb-target-group-2"
  port     = 19999
  protocol = "HTTP"
  vpc_id   = module.discovery.vpc_id
}

###Listener, relié au load_balancer, écoute sur le port 80
###Forward le traffic vers le target group
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.front_end.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }
}

resource "aws_lb_listener" "front_end_2" {
  load_balancer_arn = aws_lb.front_end.arn
  port              = "81"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group_2.arn
  }
}

### Security Group
resource "aws_security_group" "alb_sg" {
  name = "alb-sg"
  vpc_id = module.discovery.vpc_id
  
}

### Security Group Rules
### Autoriser le traffic entrant sur le port 80 pour le listener
resource "aws_security_group_rule" "alb-ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.alb_sg.id}"
  
}

resource "aws_security_group_rule" "alb-ingress-2" {
  type              = "ingress"
  from_port         = 81
  to_port           = 81
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.alb_sg.id}"
  
}

### Security Group Rules
resource "aws_security_group_rule" "alb-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.alb_sg.id}"
  
}