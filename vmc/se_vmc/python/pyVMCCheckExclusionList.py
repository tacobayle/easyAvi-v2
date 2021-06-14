#!/usr/bin/env python3

import requests                         # need this for Get/Post/Delete
import configparser                     # parsing config file
import time
import sys
import json
from prettytable import PrettyTable

#config = configparser.ConfigParser()
#config.read("./config.ini")
strProdURL      = 'https://vmc.vmware.com'
strCSPProdURL   = 'https://console.cloud.vmware.com'
Refresh_Token   = sys.argv[1]
ORG_ID          = sys.argv[2]
SDDC_ID         = sys.argv[3]

class data():
    sddc_name       = ""
    sddc_status     = ""
    sddc_region     = ""
    sddc_cluster    = ""
    sddc_hosts      = 0
    sddc_type       = ""

def getAccessToken(myKey):
    """ Gets the Access Token using the Refresh Token """
    params = {'refresh_token': myKey}
    headers = {'Content-Type': 'application/json'}
    response = requests.post('https://console.cloud.vmware.com/csp/gateway/am/api/auth/api-tokens/authorize', params=params, headers=headers)
    jsonResponse = response.json()
    access_token = jsonResponse['access_token']
    return access_token

def getNSXTproxy(org_id, sddc_id, sessiontoken):
    """ Gets the Reverse Proxy URL """
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = "{}/vmc/api/orgs/{}/sddcs/{}".format(strProdURL, org_id, sddc_id)
    response = requests.get(myURL, headers=myHeader)
    json_response = response.json()
    proxy_url = json_response['resource_config']['nsx_api_public_endpoint_url']
    return proxy_url

def getSDDCGroups(proxy_url,sessiontoken,gw):
    """ Gets the SDDC Groups. Use 'mgw' or 'cgw' as the parameter """
    myHeader = {'csp-auth-token': sessiontoken}
    proxy_url_short = proxy_url.rstrip("sks-nsxt-manager")
    myURL = proxy_url_short + "policy/api/v1/infra/domains/" + gw + "/groups"
    response = requests.get(myURL, headers=myHeader)
    json_response = response.json()
    sddc_group = json_response['results']
    return sddc_group

def getSDDCDFWExcludList (proxy_url, sessiontoken):
    myHeader = {'csp-auth-token': sessiontoken}
    myURL = (proxy_url + "/policy/api/v1/infra/settings/firewall/security/exclude-list")
    response = requests.get(myURL, headers=myHeader)
    json_response = response.json()
    sddc_DFWExcludeMember = json_response['members']
    return sddc_DFWExcludeMember

# --------------------------------------------
# ---------------- Main ----------------------
# --------------------------------------------

if len(sys.argv) > 1:
    intent_name = sys.argv[4].lower()
else:
    intent_name = ""

session_token = getAccessToken(Refresh_Token)
proxy = getNSXTproxy(ORG_ID, SDDC_ID, session_token)

if intent_name == "check-exclude-list":
    cgw_groups = getSDDCGroups(proxy, session_token, "cgw")
    group_easyavi_path = ""
    for group in cgw_groups:
      if group['display_name'] == sys.argv[5]:
        group_easyavi_path = group['path']
    member_list = getSDDCDFWExcludList(proxy,session_token)
    for item in member_list:
      if item == group_easyavi_path:
        print("{\"exclusion_list\": true}")
        break
    else:
      print("{\"exclusion_list\": false}")
    
