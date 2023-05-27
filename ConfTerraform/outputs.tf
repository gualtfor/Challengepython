output "vpc_cidr" {
  value = module.vpc.vpc_cidr_block
}

output "rendered_policy" {
  value = data.aws_iam_policy_document.ConfLambda.json
}