#################
# Load balancer #
#################

resource "aws_security_group" "lb" {
  description = "Configure access for the Application Load Balancer"
  name        = "${local.prefix}-alb-access"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "tcp"
    from_port   = 8000
    to_port     = 8000
    cidr_blocks = ["0.0.0.0/0"]
  }
}

/* 
  GLB: Security
  NLB: layer 4 tcp level load balancer that acepts request and froward at the network, doeatnt have contaxt thatt the app is forward for
  ALB: Layer 7, http request and can have context about http requests, forward http to https
 */
resource "aws_lb" "api" {
  name               = "${local.prefix}-lb"
  load_balancer_type = "application" // for ALB
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  security_groups    = [aws_security_group.lb.id]
}

/* Distribute request from alb to various resources through target group
  this way, scalling is mange cause you can distribute load to one to thousndas resources.
 */

resource "aws_lb_target_group" "api" {
  name        = "${local.prefix}-api"
  protocol    = "HTTP" // receives https and forwards to http in private network (does not matter 'cause app cannot be accesible via public internet)
  vpc_id      = aws_vpc.main.id
  target_type = "ip" // forward request to the internal ip address of the runing tasks.
  port        = 8000 // port where application is running on

  health_check {
    path = "/api/health-check/"
  }
}

/* 
When you receive a request on port 80   forward it to tg (group resources)
 */
resource "aws_lb_listener" "api" {
  load_balancer_arn = aws_lb.api.arn // incoming requests (listeners) outcomming target group
  port              = 80
  protocol          = "HTTP" // use https when you have a certificate

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}
