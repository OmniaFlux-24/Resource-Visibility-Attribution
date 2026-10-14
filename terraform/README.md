\# RVA Infrastructure as Code (Terraform)



\## Prerequisites

\- Terraform >= 1.5.0

\- AWS CLI configured with appropriate credentials

\- S3 bucket for state storage: `rva-terraform-state`

\- DynamoDB table for state locking: `rva-terraform-locks`



\## Usage



\### Initialize

```bash

terraform init

