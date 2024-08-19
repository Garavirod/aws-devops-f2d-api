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

// Task definition role
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
// Cluster definition
resource "aws_ecs_cluster" "main" {
  name = "${local.prefix}-cluster"
}
