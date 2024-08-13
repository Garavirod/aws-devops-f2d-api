#############################################
# Create ECR repo for storing Docker images #
#############################################


resource "aws_ecr_repository" "app" {
  name                 = "f2d-app-api-app"
  image_tag_mutability = "MUTABLE" // put the same tag name with multiple versions dn alway use the latest version
  force_delete         = true      // Prevent deletion on terraform destroy
  image_scanning_configuration {
    scan_on_push = false // Getting errors and security vulnerabilities: Update for real
  }
}
resource "aws_ecr_repository" "proxy" {
  name                 = "f2d-app-api-proxy"
  image_tag_mutability = "MUTABLE" // put the same tag name with multiple versions dn alway use the latest version
  force_delete         = true      // Prevent deletion on terraform destroy
  image_scanning_configuration {
    scan_on_push = false // Getting errors and security vulnerabilities: Update for real
  }
}
