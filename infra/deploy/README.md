# DNS Configuration explanation

### dns.tf file configuration

1. **Subdomain Selection**:
   * **Not all three subdomains are created simultaneously.** Instead, the subdomain is selected based on the environment you're deploying to (e.g., `prod`, `staging`, `dev`). Only one subdomain is created and used per deployment.
   * Example: If you deploy to the `prod` environment, the subdomain `api.example.com` is created.
2. **DNS Record Creation**:
   * A DNS record is created in AWS Route 53 for the selected subdomain. This record maps the subdomain (e.g., `api.example.com`) to the DNS name of the Application Load Balancer (ALB).
   * Example: The DNS record `api.example.com` is a CNAME pointing to the ALB DNS name (e.g., `alb-123456.us-east-1.elb.amazonaws.com`).
3. **SSL/TLS Certificate Request**:
   * An SSL/TLS certificate is requested from AWS Certificate Manager (ACM) for the specific subdomain (e.g., `api.example.com`). This ensures that the connection between the user and the ALB is secure (HTTPS).
4. **DNS Validation Records Creation**:
   * AWS ACM requires DNS validation to prove that you own the domain (`example.com`) and the specific subdomain (`api.example.com`). The required DNS validation records are automatically created in Route 53.
   * Example: A DNS validation record might be something like `_1234567890abcdef.example.com` pointing to a specific validation value.
5. **Certificate Validation**:
   * Once the DNS validation records are in place, ACM validates the certificate request. Upon successful validation, the certificate becomes active and is associated with the subdomain.
   * Example: The certificate for `api.example.com` is now valid and can be used to serve HTTPS traffic.

### Visual Examples (Conceptual, Not Generated Images)

Let's break it down with conceptual examples:

#### Example 1: Deploying to Production Environment (`prod`)

1. **Subdomain**: The selected subdomain is `api`.
2. **DNS Record**: A DNS CNAME record is created:
   * **Record**: `api.example.com`
   * **Points to**: `alb-123456.us-east-1.elb.amazonaws.com` (ALB DNS name)
3. **SSL/TLS Certificate Request**:
   * **Domain**: `api.example.com`
4. **DNS Validation Record**:
   * **Record**: `_1234567890abcdef.example.com`
   * **Points to**: `abcde12345.acm-validations.aws`
5. **Certificate Validation**: ACM verifies the DNS record, and the certificate for `api.example.com` becomes active.

#### Example 2: Deploying to Development Environment (`dev`)

1. **Subdomain**: The selected subdomain is `api.dev`.
2. **DNS Record**: A DNS CNAME record is created:
   * **Record**: `api.dev.example.com`
   * **Points to**: `alb-123456.us-east-1.elb.amazonaws.com` (ALB DNS name)
3. **SSL/TLS Certificate Request**:
   * **Domain**: `api.dev.example.com`
4. **DNS Validation Record**:
   * **Record**: `_67890abcdef12345.example.com`
   * **Points to**: `fghij67890.acm-validations.aws`
5. **Certificate Validation**: ACM verifies the DNS record, and the certificate for `api.dev.example.com` becomes active.

### Summary

* **Only one subdomain** is used per environment, not all three at once.
* The **DNS record** maps the subdomain to the ALB.
* An **SSL/TLS certificate** is requested and validated via DNS.
* **DNS validation records** are automatically created for validation.
* The certificate is validated and associated with the subdomain, allowing it to handle secure (HTTPS) traffic.

# EFS Explanation

## efs.tf file

### Mount Target

The provided Terraform code creates two EFS mount targets, one in each of two private subnets (`private_a` and `private_b`). These mount targets allow resources in these subnets to access the EFS file system.

* **`file_system_id`**: References the ID of the EFS file system that you want to make available in the subnet. This is defined elsewhere as `aws_efs_file_system.media.id`.
* **`subnet_id`**: Specifies the ID of the subnet (`private_a`) where this mount target will be created.
* **`security_groups`**: Associates the mount target with a security group (`efs`), which controls the traffic to and from the mount target.

Use cases: 

* **High Availability**: By creating mount targets in multiple subnets (which usually reside in different Availability Zones), you ensure that your EFS file system is highly available and resilient to failures in a single zone.
* **Subnet Accessibility**: The mount targets make the EFS file system accessible to resources within the specified subnets. These resources can then mount the EFS file system and use it to store and retrieve data as if it were a local file system.
* **Controlled Access**: The association with specific security groups (`aws_security_group.efs.id`) allows you to control which resources can connect to the EFS file system and what traffic is allowed.

### Summary:

The Terraform code creates two EFS mount targets, each in a different private subnet within your VPC. This setup allows resources in both subnets to access the same EFS file system, ensuring high availability and controlled access via security groups.

```
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

```

## Access point


An **EFS Access Point** is a managed entry point to an Amazon Elastic File System (EFS) file system. It simplifies the process of providing applications with a specific entry point into an EFS file system, with defined access permissions, user identity, and directory structure.

**Key Features:**

1. **Identity Overriding:** Access Points allow you to override the user identity (UID and GID) used for file operations, which is useful when multiple applications or users need to access the file system with different permissions.
2. **Root Directory:** You can define a specific directory in the file system as the root directory for the Access Point. This ensures that applications using the Access Point only see and operate within that directory.
3. **Permissions Control:** Access Points can enforce specific permissions, making it easier to manage access for different users or applications without altering the file system's overall structure.

### What is AWS EFS Access Point Used For?

**Use Cases:**

1. **Multi-tenant Environments:** In scenarios where multiple applications or users need isolated access to specific directories within the same EFS file system, Access Points provide a way to enforce directory isolation and user permissions.
2. **Simplified Identity Management:** Access Points are useful when you want to control the identity under which applications or users interact with the file system, especially when the applications themselves don't manage user identities directly.
3. **Scoped Access:** By defining a specific root directory for the Access Point, you can ensure that applications are restricted to a specific portion of the file system, enhancing security and reducing the risk of accidental access to unintended directories.
4. **Containerized Workloads:** When using EFS with containers (e.g., in Amazon ECS or Kubernetes), Access Points allow each container to access a specific directory within the EFS file system, with its own user identity and permissions, simplifying access control in complex environments.

**Summary:**

An AWS EFS Access Point is a feature that provides a simplified and managed entry point to an EFS file system, with customizable user identity, permissions, and directory access. It is particularly useful in multi-tenant environments, for containers, and for managing permissions and access more granularly within an EFS file system.

## Volume


This Terraform snippet defines a volume in an ECS task definition that uses an Amazon EFS (Elastic File System) volume. Here's a breakdown of what each part of the code does:

### `volume` Block

The `volume` block defines a volume that will be used by the containers in the ECS task. The name of the volume is `"efs-media"`.

### `efs_volume_configuration` Block

This block specifies that the volume is backed by an Amazon EFS file system. The configuration for the EFS volume is defined here.

#### `file_system_id`

* **`file_system_id = aws_efs_file_system.media.id`**: This specifies the ID of the EFS file system to use. The ID is retrieved from the `aws_efs_file_system.media` resource, which represents the EFS file system.

#### `transit_encryption`

* **`transit_encryption = "ENABLED"`**: This enables encryption for data in transit between the ECS task and the EFS file system. This ensures that all communication is encrypted while moving between the ECS container and EFS.

#### `authorization_config`

This block contains settings related to access and authorization for the EFS volume.

##### `access_point_id`

* **`access_point_id = aws_efs_access_point.media.id`**: This specifies the EFS Access Point to be used. An Access Point provides a way to scope access to a specific directory in the file system with specific permissions, making it easier to manage file access.

##### `iam`

* **`iam = "DISABLED"`**: This specifies whether the IAM role for the ECS task should be used to authorize access to the EFS file system. When `"DISABLED"`, the task does not use IAM authorization; instead, it relies on the access point for authorization.

```
volume {
    name = "efs-media"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.media.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.media.id
        iam = "DISABLED"
      }
    }
  }
```

### Summary

* The snippet sets up an EFS volume named `"efs-media"` for an ECS task.
* The volume is encrypted in transit.
* It uses a specific EFS Access Point to control access and does not use IAM authorization for this access.
* This setup allows containers in the ECS task to securely store and retrieve data from the specified EFS file system, scoped to the permissions and directory defined by the access point.
