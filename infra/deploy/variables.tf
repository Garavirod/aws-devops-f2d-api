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

variable "db_username" {
  description = "Username for the recipe app api database"
  default     = "recipeapp"
}

variable "db_password" {
  description = "Passowrd for the Terraform databse"
}

variable "ecr_proxy_image" {
  description = "Path to the ECR repo with the proxy image"
}

variable "ecr_app_image" {
  description = "Path to the ECR repo with the API image"
}

variable "django_secret_key" {
  description = "Secret key for Django"
}

variable "dns_zone_name" {
  description = "Domain name"
  default     = "example-site.com"
}

variable "subdomain" {
  description = "Subdomain for each environment"
  type        = map(string)

  default = {
    prod    = "api" # api.example.com
    staging = "api.staging" # api.staging.example.com
    dev     = "api.dev"
  }
}

