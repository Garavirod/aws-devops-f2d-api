variable "st_state_bucket" {
  description = "Name of s3 bucket in AWS for storing TF state"
  default     = "devops-tf-state-f2d-project"
}

variable "tf_state_lock_table" {
  description = "Name of Dynamo table for storing TF lock"
  default     = "devops-tf-lock-f2d-project"
}

variable "project" {
  description = "Project name for tagging resources"
  default     = "aws-devops-f2f-api"
}

variable "contact" {
  description = "Contact name for taggin resources"
  default     = "me@example.com"
}
