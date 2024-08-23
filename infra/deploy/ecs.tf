##########################################
# ECS Cluster for running app on Fargate #
##########################################

/* 
    ECS Task needs permissions for assuming a role (Task role).
    So, task role needs a policy for assumimg a role and such role needs to have permissions for performing jobs.
    The role in question needs to have the necessary permissions to help the task perfom certain aws jobs.
    The permission needs to be defined into a policy and this policy needs to be attached to the task role.
 */

resource "aws_iam_policy" "task_execution_role_policy" {
  name        = "${local.prefix}-task-exec-role-policy"
  path        = "/"
  description = "Allow ECS to retrieve images and add to logs."
  policy      = file("./templates/ecs/task-execution-role-policy.json")
}

resource "aws_iam_role" "task_execution_role" {
  name               = "${local.prefix}-task-execution-role"
  assume_role_policy = file("./templates/ecs/task-assume-role-policy.json")
}

resource "aws_iam_role_policy_attachment" "task_execution_role" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = aws_iam_policy.task_execution_role_policy.arn
}

// Task role
resource "aws_iam_role" "app_task" {
  name               = "${local.prefix}-app-task"
  assume_role_policy = file("./templates/ecs/task-assume-role-policy.json")
}

/* 
A task role is the role that's given to the actual task that's running
in Fargate after it's been launched.

So this is what's going to allow us to connect into the task that's 
running in Fargate in order to perform management commands like 
creating super users or debugging issues.
*/

resource "aws_iam_policy" "task_ssm_policy" {
  name        = "${local.prefix}-task-ssm-role-policy"
  path        = "/"
  description = "Policy to allow System Manager to execute in container"
  policy      = file("./templates/ecs/task-ssm-policy.json")
}

resource "aws_iam_role_policy_attachment" "task_ssm_policy" {
  role       = aws_iam_role.app_task.name
  policy_arn = aws_iam_policy.task_ssm_policy.arn
}


// Cloudwatch log group definition
/* 
Allows to view all the logs for task that is runing
Allows to track changes
Allows to know who is makeing requests to the app
Allows to view execption messages or error for debbuging
*/
resource "aws_cloudwatch_log_group" "ecs_task_logs" {
  name = "${local.prefix}-api"
}

// Cluster definition
resource "aws_ecs_cluster" "main" {
  name = "${local.prefix}-cluster"
}

// Task Definition

resource "aws_ecs_task_definition" "api" {
  family                   = "${local.prefix}-api" // Every task lacunh creates a new version that belog to the task family (task name)
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  task_role_arn            = aws_iam_role.app_task.arn
  container_definitions = jsonencode([
    {
      name              = "api"
      image             = var.ecr_app_image
      essential         = true
      memoryReservation = 256
      user              = "django-user"
      environment = [
        {
          name  = "DJANGO_SECRET_KEY"
          value = var.django_secret_key
        },
        {
          name  = "DB_HOST"
          value = aws_db_instance.main.address
        },
        {
          name  = "DB_NAME"
          value = aws_db_instance.main.db_name
        },
        {
          name  = "DB_USER"
          value = aws_db_instance.main.username
        },
        {
          name  = "DB_PASS"
          value = aws_db_instance.main.password
        },
        {
          name  = "ALLOWED_HOSTS"
          value = "*" // CORS
        }
      ]
      mountPoints = [
        {
          readOnly      = false // 'cause the app needs to wwrite data into this location
          containerPath = "/vol/web/static"
          sourceVolume  = "static"
        }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_task_logs.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "api"
        }
      }
    },
    {
      name              = "proxy"
      image             = var.ecr_proxy_image
      essential         = true    // if something happens to container it will try and restart the task
      memoryReservation = 256     // must not exceed of task definition memory
      user              = "nginx" // reverse proxy user to access necessary permissions whathever to do into container
      portMappings = [
        {
          containerPort = 8000 // hook with the ALB and SG
          hostPort      = 8000
        }
      ]
      environment = [
        {
          name  = "APP_HOST"
          value = "127.0.0.1"
        }
      ]
      mountPoints = [ // volumes
        {
          readOnly      = true
          containerPath = "/vol/static"
          sourceVolume  = "static"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_task_logs.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "proxy"
        }
      }
    }
  ])

  volume {
    // In django is useful for sharing or serving static data between proxy and app
    name = "static" // Location on the running server that has files; Allow share data between running containers
  }

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64" //important to keep in mind, because this is base on the architecture the docker images are build for.
  }
}

/* 
  SG for managing the rules for the srvice which run the tasks
 */
resource "aws_security_group" "ecs_service" {
  description = "Access rules for the ECS service."
  name        = "${local.prefix}-ecs-service"
  vpc_id      = aws_vpc.main.id

  # Outbound access to endpoints
  egress { // This allow to access the endpoints in private subnet which are in port 443
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # RDS connectivity
  egress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    cidr_blocks = [
      aws_subnet.private_a.cidr_block,
      aws_subnet.private_b.cidr_block,
    ]
  }

  # HTTP inbound access
  ingress {
    from_port   = 8000 // same as proxy becasue it manage the requests; proxy -> app
    to_port     = 8000 // same as proxy
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] // public access
    security_groups = [
      aws_security_group.lb.id // Only accesible for ecs sg
    ]
  }
}

resource "aws_ecs_service" "api" {
  name                   = "${local.prefix}-api"
  cluster                = aws_ecs_cluster.main.name
  task_definition        = aws_ecs_task_definition.api.family
  desired_count          = 1 // Ability to process more request and to scale up the app, as many as the app needs to handle 
  launch_type            = "FARGATE"
  platform_version       = "1.4.0" // Fargate version
  enable_execute_command = true

  network_configuration {
    assign_public_ip = true

    subnets = [
      # aws_subnet.public_a.id, // private for real appp and public for testing 
      # aws_subnet.public_b.id
      aws_subnet.private_a.id, // resgister the servies in private subnets,, this way ecs task is protected.
      aws_subnet.private_b.id
    ]

    security_groups = [aws_security_group.ecs_service.id]
  }
  // load balcner will forward requests to a target group and tg will forward to proxy container runnning on 8000
  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "proxy"
    container_port   = 8000
  }
}
