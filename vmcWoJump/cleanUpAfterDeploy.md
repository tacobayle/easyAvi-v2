```
terraform destroy -var-file=sddc.json -var-file=ip.json -var-file=EasyAviLocation.json -target=vmc_public_ip.public_ip_controller_admin -target=nsxt_policy_nat_rule.dnat_controller_admin -auto-approve
```