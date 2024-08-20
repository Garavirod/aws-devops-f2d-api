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
  container_definitions    = jsonencode([])

  volume {
    // In django is useful for sharing or serving static data between proxy and app
    name = "static" // Location on the running server that has files; Allow share data between running containers
  }

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64" //important to keep in mind, because this is base on the architecture the docker images are build for.
  }
}
