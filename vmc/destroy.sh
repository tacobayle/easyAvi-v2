#!/bin/bash
if [ -f "data.json" ]; then
  credsFile="data.json"
fi
if [ -f "se_vmc/se_vmc.json" ]; then
  credsFile="se_vmc/se_vmc.json"
fi
if [ -f "sddc.json" ]; then
  credsFile="sddc.json"
fi
if [ -f "se_vmc/se_vmc.json" ]; then
  jsonFile="se_vmc/se_vmc.json"
fi
if [ -f "sddc.json" ]; then
  jsonFile="sddc.json"
fi
export GOVC_DATACENTER=$(cat $jsonFile | jq -r .no_access_vcenter.vcenter.dc)
export GOVC_URL=$(cat $credsFile | jq -r .vmc_vsphere_username):$(cat $credsFile | jq -r .vmc_vsphere_password)@$(cat $credsFile | jq -r .vmc_vsphere_server)
export GOVC_INSECURE=true
export GOVC_DATASTORE=$(cat $jsonFile | jq -r .no_access_vcenter.vcenter.datastore)
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
govc library.rm $(cat $jsonFile | jq -r .no_access_vcenter.cl_avi_name) > /dev/null 2>&1 || true
IFS=$'\n'
echo ""
echo "++++++++++++++++++++++++++++++++"
echo "destroying VM matching deployment tag and EasyAvi-se-* as a name..."
for vm in $(govc tags.attached.ls $(cat $jsonFile | jq -r .no_access_vcenter.deployment_id) | xargs govc ls -L)
do
  if [[ $(basename $vm) == EasyAvi-se-* ]]
  then
    echo "removing VM called $(basename $vm)"
    govc vm.destroy $(basename $vm)
  fi
done
#
# Cleaning vCenter tags (only for imported deployment)
#
if [ -f "se_vmc/se_vmc.json" ] && [ ! -f "sddc.json" ]
then
  echo ""
  echo "++++++++++++++++++++++++++++++++"
  echo "destroying tag..."
  govc tags.rm $(cat se_vmc/se_vmc.json | jq -r .no_access_vcenter.deployment_id) > /dev/null 2>&1 || true
  echo ""
  echo "++++++++++++++++++++++++++++++++"
  echo "destroying category tag..."
  govc govc tags.category.rm $(cat se_vmc/se_vmc.json | jq -r .no_access_vcenter.EasyAviTagCategoryName) > /dev/null 2>&1 || true
fi
#
# Removing NSX-T config
#
echo ""
echo "++++++++++++++++++++++++++++++++"
echo "removing CGW rules"
python3 python/pyVMCDestroy.py $(cat $credsFile | jq -r .vmc_nsx_token) $(cat $credsFile | jq -r .vmc_org_id) $(cat $credsFile | jq -r .vmc_sddc_id) remove-easyavi-rules easyavi_
echo ""
echo "++++++++++++++++++++++++++++++++"
echo "removing $(cat $jsonFile | jq -r .no_access_vcenter.EasyAviSeExclusionList) from exclusion list"
python3 python/pyVMCDestroy.py $(cat $credsFile | jq -r .vmc_nsx_token) $(cat $credsFile | jq -r .vmc_org_id) $(cat $credsFile | jq -r .vmc_sddc_id) remove-exclude-list $(cat $jsonFile | jq -r .no_access_vcenter.EasyAviSeExclusionList)
#echo ""
#echo "++++++++++++++++++++++++++++++++"
#echo "removing $(cat $jsonFile | jq -r .no_access_vcenter.EasyAviControllerExclusionList) from exclusion list"
#python3 python/pyVMCDestroy.py $(cat $credsFile | jq -r .vmc_nsx_token) $(cat $credsFile | jq -r .vmc_org_id) $(cat $credsFile | jq -r .vmc_sddc_id) remove-exclude-list $(cat $jsonFile | jq -r .no_access_vcenter.EasyAviControllerExclusionList)
#
# TF Refresh, destroy.
#
if [ -f "data.json" ]; then
  echo ""
  echo "TF refresh..."
  terraform refresh -var-file=$jsonFile -var-file=ip.json -var-file=data.json -var-file=EasyAviLocation.json -no-color
  echo ""
  echo "TF destroy..."
  terraform destroy -auto-approve -var-file=$jsonFile -var-file=ip.json -var-file=data.json -var-file=EasyAviLocation.json -no-color
fi
if [ -f "sddc.json" ]; then
  terraform state rm vsphere_content_library.library > /dev/null 2>&1 || true
  terraform state rm vsphere_content_library.avi > /dev/null 2>&1 || true
  terraform state rm vsphere_content_library_item.avi > /dev/null 2>&1 || true
  terraform state rm vsphere_content_library_item.ubuntu > /dev/null 2>&1 || true
  terraform state rm vsphere_content_library_item.ubuntu_backend[0] > /dev/null 2>&1 || true
  echo ""
  echo "TF refresh..."
  terraform refresh -var-file=$jsonFile -var-file=ip.json -var-file=EasyAviLocation.json -no-color
  echo ""
  echo "TF destroy..."
  terraform destroy -auto-approve -var-file=$jsonFile -var-file=ip.json -var-file=EasyAviLocation.json -no-color
fi
#echo ""
#echo "Removing easyavi.ran"
#rm easyavi.ran rm > /dev/null 2>&1 || true