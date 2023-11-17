### Provider definition

provider "aws" {
  region = "${var.aws_region}"
}

### Module Main

###Recupère les infos du repo en fonction des tags
module "discovery" {
  source              = "github.com/Lowess/terraform-aws-discovery"
  aws_region          = var.aws_region
  vpc_name            = "${var.vpc_name}"
  ec2_ami_names       = ["*Web-V2*"]
  }

### Affichage du contenu du module
output "discovery" {
  value = module.discovery
}