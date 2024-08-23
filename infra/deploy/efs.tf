##########################
# EFS for media storage. #
##########################

resource "aws_efs_file_system" "media" {
  encrypted = true // For encrypttation at rest
  tags = {
    Name = "${local.prefix}-media"
  }
}
