### Launch Template (Template des instances qui seront crées dans le target group)
### Reliés à l'AMI, key_pair et security_group
resource "aws_launch_template" "foobar" {
  name_prefix   = "foobar"
  image_id      = "${module.discovery.images_id[0]}"
  instance_type = "t2.micro"
  key_name = "ops"
  vpc_security_group_ids = [aws_security_group.tf-sg-asg.id]
}

### Autoscaling group (Groupe regroupant les propriétés de l'autoscaling, min max)
### Combien de machines dans l'ASG, dans quels subnets (vpc_zone_identifier), 
### Reliés à un target group + launch_template
resource "aws_autoscaling_group" "bar" {
  max_size           = 2
  min_size           = 2
  vpc_zone_identifier = [module.discovery.public_subnets[0], module.discovery.public_subnets[1], module.discovery.public_subnets[2]]
  target_group_arns = [aws_lb_target_group.alb_target_group.arn, aws_lb_target_group.alb_target_group_2.arn]

  launch_template {
    id      = aws_launch_template.foobar.id
    version = "$Latest"
  }
}

### Security Group
resource "aws_security_group" "tf-sg-asg" {
    name        = "tf-sg-asg"
    description = "Load balancer security group"
    vpc_id = module.discovery.vpc_id
}

### Security Group Rules
### Autorise le traffic entrant vers 8080
resource "aws_security_group_rule" "sgr-asg-1" {
    type              = "ingress"
    from_port         = 8080
    to_port           = 8080
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = "${aws_security_group.tf-sg-asg.id}"
}

### Security Group Rules
resource "aws_security_group_rule" "sgr-asg-2" {
    type              = "egress"
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = "${aws_security_group.tf-sg-asg.id}"
}

resource "aws_security_group_rule" "sgr-asg-3" {
    type              = "ingress"
    from_port         = 19999
    to_port           = 19999
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = "${aws_security_group.tf-sg-asg.id}"
}

### 2 alarme (plus grand et plus petit) - 2 actions (augmente, descend)
### Policy d'autoscaling, Passe le nombre d'instance à 2
resource "aws_autoscaling_policy" "autoscaling_policy_up" {
  name                   = "autoscaling_policy-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.bar.name
}

### Alarme si le CPU charge dépasse ou égal à 80% 
### Relié a une autoscaling policy et autoscaling group
resource "aws_cloudwatch_metric_alarm" "alarmup" {
  alarm_name          = "alarm-cpu-up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 30

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.bar.name
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = [aws_autoscaling_policy.autoscaling_policy_up.arn]
}

### Policy d'autoscaling, Passe le nombre d'instance à 1
resource "aws_autoscaling_policy" "autoscaling_policy_down" {
  name                   = "autoscaling_policy-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.bar.name
}

### Alarme si le CPU charge passe en dessous ou égal de 40% 
### Relié a une autoscaling policy et autoscaling group
resource "aws_cloudwatch_metric_alarm" "alarmdown" {
  alarm_name          = "alarm-cpu-down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 5

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.bar.name
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = [aws_autoscaling_policy.autoscaling_policy_down.arn]
}