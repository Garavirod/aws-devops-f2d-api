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


/* 
  Access point

  An EFS Access Point is a managed entry point to an Amazon Elastic File System (EFS) file system. 
  It simplifies the process of providing applications with a specific entry point into an EFS file system, 
  with defined access permissions, user identity, and directory structure.

  So an access point is a way that you can split up the locations inside your EFS file system and give
  different access to different things.

  If you had a setup where you had multiple different apps and you wanted to share the same EFS file system,
  but you wanted to split up the file system so that the data is separated into separate locations and
  only certain components of your application or certain tasks can access certain parts of the file system.

  Uses cases: 

  - Multi-tenant Environments: In scenarios where multiple applications or users need isolated access to 
  specific directories within the same EFS file system, Access Points provide a way to enforce directory isolation and user permissions.

  - Scoped Access: By defining a specific root directory for the Access Point, you can ensure that applications are restricted to a specific 
  portion of the file system, enhancing security and reducing the risk of accidental access to unintended directories.

  - Containerized Workloads: When using EFS with containers (e.g., in Amazon ECS or Kubernetes), Access Points allow each container to 
    access a specific directory within the EFS file system, with its own user identity and permissions, simplifying access control in complex environments.
 */
resource "aws_efs_access_point" "media" {
  file_system_id = aws_efs_file_system.media.id
  root_directory {
    path = "/api/media"
    creation_info {
      owner_gid   = 101 // Permission of who can access to in terms of Linux ID (specified in Dockerfile ARG=UID 101)
      owner_uid   = 101
      permissions = "755" // chmod calculator
    }
  }
}
