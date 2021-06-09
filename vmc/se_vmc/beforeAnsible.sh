#!/bin/bash
#
#
#
if [ -f "data.json" ]; then
  credsFile="data.json"
else
  credsFile="se_vmc.json"
fi
#
#
#
export GOVC_DATACENTER=$(cat se_vmc.json | jq -r .no_access_vcenter.vcenter.dc)
export GOVC_URL=$(cat $credsFile | jq -r .vmc_vsphere_username):$(cat $credsFile | jq -r .vmc_vsphere_password)@$(cat $credsFile | jq -r .vmc_vsphere_server)
export GOVC_INSECURE=true
export GOVC_DATASTORE=$(cat se_vmc.json | jq -r .no_access_vcenter.vcenter.datastore)
#
#
#
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
#
#
IFS=$'\n'
echo ""
echo "++++++++++++++++++++++++++++++++"
echo "Checking for Tag conflict name..."
tag_status=0
for tag in $(govc tags.category.ls)
do
  if [[ $tag == $(cat se_vmc.json | jq -r .no_access_vcenter.EasyAviTagCategoryName) ]]
    then
      tag_status=1
  fi
done
if [[ $tag_status -eq 0 ]]
  then
    echo "Category tag does not exist - it will be created by TF"
    mv templates/vsphere_infrastructure.tf vsphere_infrastructure.tf
    mv templates/ansible_with_tag.tf ansible.tf
fi
if [[ $tag_status -eq 1 ]]
  then
    echo "Category tag exists"
    mv templates/ansible_without_tag.tf ansible.tf
fi
#
#
#
echo ""
echo "++++++++++++++++++++++++++++++++"
echo "Checking for Content Library conflict name..."
for cl in $(govc library.ls)
do
  if [[ $(basename $cl) == "Easy-Avi-CL-SE-NoAccess" ]]
  then
    echo "ERROR: There is a Content Library called $(basename $cl) which will conflict with this deployment - please remove it before trying another attempt"
    beforeTfError=1
  fi
done
#
#
#
echo ""
echo "++++++++++++++++++++++++++++++++"
echo "Checking for NSX Exclusion list..."
nsx_exclusion_list_status=$(python3 python/pyVMCCheckExclusionList.py $(cat $credsFile | jq -r .vmc_nsx_token) $(cat $credsFile | jq -r .vmc_org_id) $(cat $credsFile | jq -r .vmc_sddc_id) check-exclude-list $(cat $credsFile | jq -r .no_access_vcenter.EasyAviSeExclusionList))
if [ $(echo $nsx_exclusion_list_status | jq -r .exclusion_list) = false ]
then
  echo "NSX Exclusion list will be updated by TF"
  mv templates/nsxt.tf nsxt.tf
fi
#
#
#
echo ""
echo "++++++++++++++++++++++++++++++++"
echo "Checking for Avi API endpoint connectivity..."
count=1 ; until $(curl --output /dev/null --silent --head -k $(cat se_vmc.json | jq -r .no_access_vcenter.avi_endpoint)); do echo "Attempt $count: Waiting for Avi Controllers to be reachable..."; sleep 5 ; count=$((count+1)) ;  if [ "$count" = 120 ]; then echo "ERROR: Unable to connect to Avi Controller API" ; beforeTfError=1 ; fi ; done
#
#
#
if [[ $beforeTfError == 1 ]]
then
  exit 1
fi