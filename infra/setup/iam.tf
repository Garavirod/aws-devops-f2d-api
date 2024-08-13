#######################################
# Create IAM user and policies for CD #
#######################################

resource "aws_iam_user" "cd" {
  name = "f2d-app-api-cd"
}

resource "aws_iam_access_key" "cd" {
  user = aws_iam_user.cd.name
}


########################################################
# Policy for terraform backend to s3 and Dynamo access #
########################################################

data "aws_iam_policy_document" "tf_backend" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.tf_state_bucket}"]
  }

  statement {
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:PutObject", "S3:DeleteObject"]
    resources = [
      "arn:aws:s3:::${var.tf_state_bucket}/tf-state-deploy/*",
      "arn:aws:s3:::${var.tf_state_bucket}/tf-state-deploy-env/*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    // First asterics for account and second one for region
    resources = ["arn:aws:dynamodb:*:*:table/${var.tf_state_lock_table}"]
  }
}

###################################
# Diff between data and resources #
###################################

/*
  something that is generated that can be used when you are 
  creating or manageing rsources.

  - resource-block: Used to create, manage, and modify infrastructure resources.

  - data block: Used to read information about existing infrastructure without making any changes to it.
  block is used to query or retrieve information about existing resources that are not managed by 
  your Terraform configuration. This is useful when you want to use information about resources 
  that were created outside of Terraform or when you want to reference resources that exist in a 
  different Terraform configuration.
*/

resource "aws_iam_policy" "tf_backend" {
  name        = "${aws_iam_user.cd.name}-tf-s3-dynamodb"
  description = "Allow user to use S3 and DynamoDB for TF backend resources"
  policy      = data.aws_iam_policy_document.tf_backend.json
}

resource "aws_iam_user_policy_attachment" "tf_backend" {
  user       = aws_iam_user.cd.name
  policy_arn = aws_iam_policy.tf_backend.arn
}
