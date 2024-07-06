# AWS EC2 NAT Gateway

Private subnets play a crucial role in your VPC — they protect, isolate, and maintain confidentiality. When designing your network, consider using private subnets.

1. **Security:** Private subnets keep sensitive resources (such as databases, application servers, and backend services) away from prying eyes.
2. **No Direct Internet Access:** Instances within private subnets lack public IP addresses. If these instances need internet access (for updates, patches, or cat videos), they route through a NAT Gateway or NAT Instance. This also allows you to predict the IP address for all external requests.
3. **Cost Optimization:** By placing non-public resources in private subnets, you avoid unnecessary data transfer costs. 

## Cost Considerations

NAT Gateways are an essential part of private subnets, but they can be expensive and the [pricing is confusing](https://aws.amazon.com/vpc/pricing/). Let’s explore the costs:

Note: EC2 prices below do not assume reserved instances, savings plans, or negotiated rates. These are the minimal savings you can anticipate.

### Hourly

AWS charges $0.045 per hour for NAT Gateways, roughly equivalent to a typical `.medium` EC2 instance. However, an EC2 NAT Gateway is a [lightweight system](https://docs.aws.amazon.com/vpc/latest/userguide/work-with-nat-instances.html#create-nat-ami). Even if you run one for each availability zone (AZ), you’ll still save money compared to AWS NAT Gateways.

|               |  $/Hour | $/Month | Base |
|---------------|--------:|--------:|-----:|
| **AWS NG**    | $0.0450 |  $32.40 |    - |
| **t3.micro**  | $0.0104 |   $7.49 |  33% |
| **t3a.micro** | $0.0094 |   $6.77 |  21% |
| **t4g.micro** | $0.0084 |   $6.05 |  19% |
| **t3.nano**   | $0.0052 |   $3.74 |  12% |
| **t3a.nano**  | $0.0047 |   $3.38 |  10% |
| **t4g.nano**  | $0.0042 |   $3.02 |   9% |

### Data

AWS charges a hefty $0.045 per gigabyte (GB) for data processing, excluding standard Data Transfer rates. While S3 data transfer is exempt when using an endpoint within your VPC, other data types still incur processing fees. Whether it’s region-to-region, inter-region, internet outbound, or internet inbound, you’ll pay for data processing.

Consider your balance between data in and out. For routine tasks like a `yum update`, paying 4.5¢ per GB seems excessive. Similarly, exporting data to a client shouldn’t cost you 13.5¢ per GB (4.5¢ + 9¢ standard data charge).

|      GB | - | AWS NAT In | AWS NAT Out | - | EC2 In |   EC2 Out |
|--------:|---|-----------:|------------:|---|-------:|----------:|
|       1 |   |      $0.05 |       $0.14 |   |  $0.00 |     $0.09 |
|      10 |   |      $0.45 |       $1.35 |   |  $0.00 |     $0.90 |
|     100 |   |      $4.50 |      $13.50 |   |  $0.00 |     $9.00 |
|   1,000 |   |     $45.00 |     $135.00 |   |  $0.00 |    $90.00 |
|  10,000 |   |    $450.00 |   $1,350.00 |   |  $0.00 |   $900.00 |
|  25,000 |   |  $1,125.00 |   $3,375.00 |   |  $0.00 | $2,250.00 |
|  50,000 |   |  $2,250.00 |   $6,750.00 |   |  $0.00 | $4,500.00 |
| 100,000 |   |  $4,500.00 |  $13,500.00 |   |  $0.00 | $9,000.00 |

### Overall Assessment

While AWS Data Processing charges are high, the tradeoffs are worth considering. For a detailed comparison, refer to [AWS’s official documentation](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-comparison.html).

## Running your own

```sh
git clone https://github.com/MikeGarde/aws-nat-gateway.git
```

You'll need - [Packer](https://www.packer.io/) - [Terraform](https://www.terraform.io/) - [Taskfile](https://taskfile.dev/) - [dotenv-cli](https://www.npmjs.com/package/@mikegarde/dotenv-cli)

```shell
# First time, initiate it all
task init

# Or do packer & terraform on their own
packer init ami/nat-gateway.pkr.hcl
terraform init terraform/scratch/
```

### AMI (packer)

Build the AMI, you'll need an existing VPC to create your initial AMI. Review `packer-build` in `Taskfile.yaml`

```sh
task packer-build
```

### VPC (terraform)

Whichever option you choose you'll need to have already created your EC2 NAT Gateway AMI. Next utilize the terraform files in [./terraform/scratch/](./terraform/scratch/) as inspiration or apply the setup to your account.

#### Automatic

Check out the manual section below to see what this is doing.

```shell
# Automatically setup your .tfvars file
task dotenv-setup
# Run terraform actions
task terraform:plan
task terraform:apply
```

#### Manual

1. `cd terraform/scratch` 
2. `cp .tfvars.example .tfvars` and make appropriate edits
3. You'll need to whitelist EC2 Connect for your region, see `Taskfile.yaml` for guidance. Or see [Work with ip-ranges.json](https://docs.aws.amazon.com/vpc/latest/userguide/aws-ip-work-with.html).
4. `terraform plan -var-file=".tfvars"`
5. `terraform apply -var-file=".tfvars"`

## TODO

 - [ ] Terraform plan for 1 EC2 NAT Gateway per AZ
 - [ ] CLI/CDK based tool for analyzing current VPC and creating a modification plan
 - [ ] Lambda functions to replace troubled instances and move them between AZ's
 - [ ] [Steampipe](https://steampipe.io/) compliance dashboard
 - [ ] Add [Teleport](https://goteleport.com/) for access
