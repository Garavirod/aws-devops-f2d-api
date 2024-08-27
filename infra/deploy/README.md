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
