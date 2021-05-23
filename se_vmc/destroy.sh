#!/bin/bash
#
if [ -f "data.json" ]; then
  credsFile="data.json"
else
  credsFile="se_vmc.json"
fi
export GOVC_DATACENTER=$(cat se_vmc.json | jq -r .no_access_vcenter.vcenter.dc)
export GOVC_URL=$(cat $credsFile | jq -r .vmc_vsphere_username):$(cat $credsFile | jq -r .vmc_vsphere_password)@$(cat $credsFile | jq -r .vmc_vsphere_server)
export GOVC_INSECURE=true
export GOVC_DATASTORE=$(cat se_vmc.json | jq -r .no_access_vcenter.vcenter.datastore)
echo ""
echo "++++++++++++++++++++++++++++++++"
echo "Checking for vCenter Connectivity..."
govc find / -type m > /dev/null 2>&1
status=$?
if [[ $status -ne 0 ]]
then
  echo "ERROR: vCenter connectivity issue - please check that you have Internet connectivity and please check that vCenter API endpoint is reachable from this EasyAvi appliance"
  exit 1
fi
#
# Cleaning vCenter
#
echo ""
echo "++++++++++++++++++++++++++++++++"
echo "destroying SE Content Libraries..."
govc library.rm Easy-Avi-CL-SE-NoAccess > /dev/null 2>&1 || true
if [ -f "data.json" ]; then
  echo ""
  echo "TF refresh..."
  terraform refresh -var-file=se_vmc.json -var-file=data.json -no-color
  echo ""
  echo "TF destroy..."
  terraform destroy -auto-approve -var-file=se_vmc.json -var-file=data.json -no-color
else
  echo ""
  echo "TF refresh..."
  terraform refresh -var-file=se_vmc.json -no-color
  echo ""
  echo "TF destroy..."
  terraform destroy -auto-approve -var-file=se_vmc.json -no-color
fi