variable "prefix" {
  description = "Prefix for resources in AWS"
  default     = "f2d"
}

variable "project" {
  description = "Project name for tagging resources"
  default     = "recipe-app-api"
}

variable "contact" {
  description = "Contact email for tagging resources"
  default     = "example@mail.com"
}
