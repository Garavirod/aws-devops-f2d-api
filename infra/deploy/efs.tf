##########################
# EFS for media storage. #
##########################

resource "aws_efs_file_system" "media" {
  encrypted = true // For encrypttation at rest
  tags = {
    Name = "${local.prefix}-media"
  }
}

resource "aws_security_group" "efs" {
  name   = "${local.prefix}-efs"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 2049 // standard port for EFS
    to_port   = 2049
    protocol  = "tcp"

    security_groups = [
      aws_security_group.ecs_service.id
    ]
  }
}

/* 

An EFS (Elastic File System) mount target is an endpoint that allows EC2 instances, ECS tasks, or other compute resources within a VPC (Virtual Private Cloud) to connect to and access an Amazon EFS file system. 
Each mount target is associated with a specific subnet in your VPC, enabling resources within that subnet to mount the EFS file system as a network file system (NFS).

we want our application to be designed so it could be in theory scaled up to be highly available,
we need to make sure that there is a mount target available in each of the subnets that our tasks arerunning on.

So when we run our ECS task, it could be running on subnet A, or it could be running on subnet B.
So we need to make sure that there is a mount target available in both of these subnets so that our
task has the correct connectivity to be able to connect to it.

This creates two EFS mount targets, each in a different private subnet within your VPC. 
This setup allows resources in both subnets to access the same EFS file system, ensuring high availability and controlled access via security groups.
 */
resource "aws_efs_mount_target" "media_a" {
  file_system_id  = aws_efs_file_system.media.id
  subnet_id       = aws_subnet.private_a.id
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_mount_target" "media_b" {
  file_system_id  = aws_efs_file_system.media.id
  subnet_id       = aws_subnet.private_b.id
  security_groups = [aws_security_group.efs.id]
}
