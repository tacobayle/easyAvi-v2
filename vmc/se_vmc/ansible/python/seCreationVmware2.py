import requests, json, os, yaml, sys, time, random, string, ipaddress, socket
from avi.sdk.avi_api import ApiSession
from ipaddress import IPv4Network
from ipaddress import IPv4Interface

class aviSession:
  def __init__(self, fqdn, username, password, tenant):
    self.fqdn = fqdn
    self.username = username
    self.password = password
    self.tenant = tenant

  def debug(self):
    print("controller is {0}, username is {1}, password is {2}, tenant is {3}".format(self.fqdn, self.username, self.password, self.tenant))

  def getObject(self, objectUrl, objectTenant, objectParams):
    api = ApiSession.get_session(self.fqdn, self.username, self.password, self.tenant)
    result = api.get(objectUrl, tenant=objectTenant, params=objectParams)
    return result.json()

  def putObject(self, objectUrl, objectTenant, objectData):
    api = ApiSession.get_session(self.fqdn, self.username, self.password, self.tenant)
    result = api.put(objectUrl, tenant=objectTenant, data=objectData)
    return result.json()

if __name__ == '__main__':
  avi_credentials = yaml.load(sys.argv[1])
  seg = yaml.load(sys.argv[2])
  cloud_no_access_vcenter_uuid = sys.argv[3]
  vcenter = yaml.load(sys.argv[4])
  vsphere_username = sys.argv[5]
  vsphere_password = sys.argv[6]
  vsphere_server = sys.argv[7]
  seg_folder = 'Avi-SE-' + seg['name']
  cl_name = sys.argv[8]
  deployment_id = sys.argv[9]
#   tenant = "admin"
  vsphere_url="https://" + vsphere_username + ":" + vsphere_password + "@" + vsphere_server
  defineClass = aviSession(avi_credentials['controller'], avi_credentials['username'], avi_credentials['password'], avi_credentials['tenant'])
  cluster_uuid = defineClass.getObject('cluster', 'admin', '')['uuid']
  if seg['numberOfSe'] == 0:
    print('no SE to create')
    exit()
  # SE folder creation - don't check if it fails in case of existing folder
  os.system('''export GOVC_DATACENTER={0}
               export GOVC_URL={1}
               export GOVC_INSECURE=true
               govc folder.create /{0}/vm/\'{2}\''''.format(vcenter['dc'], vsphere_url, seg_folder))
  # Get network PortgroupKey if dhcp is false for a data network - exit if it fails
  if any(network['dhcp'] == False for network in seg['data_networks']):
    networks = []
    for item in seg['data_networks']:
      if item['dhcp'] == False:
        network = {}
        govc_result = os.system('''export GOVC_DATACENTER={0}
                                   export GOVC_URL={1}
                                   export GOVC_INSECURE=true
                                   govc ls -json /{0}/network/{2} | tee network.json >/dev/null'''.format(vcenter['dc'], vsphere_url, item['name']))
        if govc_result != 0:
#           os.system('export GOVC_DATACENTER={0}; export GOVC_URL={1}; export GOVC_INSECURE=true; govc library.rm {2}'.format(vcenter['dc'], vsphere_url, cl_name))
          print('Error when browsing the data network to retrieve the PortgroupKey')
          sys.exit(1)
        with open('network.json', 'r') as stream:
          network_info = json.load(stream)
        network['name'] = item['name']
        network['PortgroupKey'] = network_info['elements'][0]['Object']['Summary']['Network']['Value']
        network['ips'] = item['ips']
        network['defaultGateway'] = item['defaultGateway']
        try:
          network['OpaqueNetworkId'] = network_info['elements'][0]['Object']['Summary']['OpaqueNetworkId']
        except:
          pass
        networks.append(network)
#   print(networks)
#   # Create a content library and import the SE ova - exit if it fails
#   govc_result = os.system('export GOVC_DATACENTER={0}; export GOVC_URL={1}; export GOVC_DATASTORE={2} ; export GOVC_INSECURE=true; govc library.create {3} ; govc library.import {3} {4}'.format(vcenter['dc'], vsphere_url, vcenter['datastore'], cl_name, ova_path))
#   if govc_result != 0:
# #     os.system('export GOVC_DATACENTER={0}; export GOVC_URL={1}; export GOVC_INSECURE=true; govc library.rm {2}'.format(vcenter['dc'], vsphere_url, cl_name))
#     print('Error when creating content library or importing item in the content library')
#     exit()
  # Spin up SE from Content library
  seCount = 0
  for se in range (1, seg['numberOfSe'] + 1):
    params = {"cloud_uuid": cloud_no_access_vcenter_uuid}
    auth_details = defineClass.getObject('securetoken-generate', avi_credentials['tenant'], params)
    govc_result = os.system('export GOVC_DATACENTER={0}; export GOVC_URL={1}; export GOVC_INSECURE=true; govc find -json / -type m | tee vm_inventory.json'.format(vcenter['dc'], vsphere_url))
    if govc_result != 0:
#       os.system('export GOVC_DATACENTER={0}; export GOVC_URL={1}; export GOVC_INSECURE=true; govc library.rm {2}'.format(vcenter['dc'], vsphere_url, cl_name))
      print('Error when retrieving inventory names of VM')
      sys.exit(1)
    with open('vm_inventory.json', 'r') as vm_json:
      vm_inventory = json.load(vm_json)
    while True:
        countVm = 0
        se_name = 'EasyAvi-se-' + ''.join(random.choice(string.ascii_lowercase) for _ in range(5))
        duplicate = False
        for item in vm_inventory:
          if se_name == item.split('/')[-1]:
            duplicate = True
            #print('duplicate')
          countVm += 1
        if duplicate == False and countVm == len(vm_inventory):
          #print('No duplicate')
          break
    properties = {
                  'IPAllocationPolicy': 'dhcpPolicy',
                  'IPProtocol': 'IPv4',
                  'MarkAsTemplate': False,
                  'PowerOn': False,
                  'InjectOvfEnv': False,
                  'WaitForIP': False,
                  'Name': se_name
                 }
    if seg['management_network']['dhcp'] == True:
      properties['PropertyMapping'] = [
                                        {
                                          'Key': 'AVICNTRL',
                                          'Value': avi_credentials['controller']
                                        },
                                        {
                                          'Key': 'AVISETYPE',
                                          'Value': 'NETWORK_ADMIN'
                                        },
                                        {
                                          'Key': 'AVICNTRL_AUTHTOKEN',
                                          'Value': auth_details['auth_token']
                                        },
                                        {
                                          'Key': 'AVICNTRL_CLUSTERUUID',
                                          'Value': cluster_uuid
                                        },
                                        {
                                          'Key': 'avi.mgmt-ip.SE',
                                          'Value': ''
                                        },
                                        {
                                          'Key': 'avi.mgmt-mask.SE',
                                          'Value': ''
                                        },
                                        {
                                          'Key': 'avi.default-gw.SE',
                                          'Value': ''
                                        },
                                        {
                                          'Key': 'avi.DNS.SE',
                                          'Value': ''
                                        },
                                        {
                                          'Key': 'avi.sysadmin-public-key.SE',
                                          'Value': ''
                                        }
                                      ]
    if seg['management_network']['dhcp'] == False:
      try:
        ipaddress.ip_address(avi_credentials['controller'])
        avi_controller_ip = avi_credentials['controller']
      except:
        avi_controller_ip = socket.gethostbyname(avi_credentials['controller'])
      properties['PropertyMapping'] = [
                                        {
                                          'Key': 'AVICNTRL',
                                          'Value': avi_controller_ip
                                        },
                                        {
                                          'Key': 'AVISETYPE',
                                          'Value': 'NETWORK_ADMIN'
                                        },
                                        {
                                          'Key': 'AVICNTRL_AUTHTOKEN',
                                          'Value': auth_details['auth_token']
                                        },
                                        {
                                          'Key': 'AVICNTRL_CLUSTERUUID',
                                          'Value': cluster_uuid
                                        },
                                        {
                                          'Key': 'avi.mgmt-ip.SE',
                                          'Value': str(seg['management_network']['ips'][seCount])
#                                           str(seg['management_network']['ips'][seCount])
                                        },
                                        {
                                          'Key': 'avi.mgmt-mask.SE',
                                          'Value': str(IPv4Network(IPv4Interface(seg['management_network']['defaultGateway']).network).netmask)
                                        },
                                        {
                                          'Key': 'avi.default-gw.SE',
                                          'Value': str(seg['management_network']['defaultGateway'].split('/')[0])
                                        },
                                        {
                                          'Key': 'avi.DNS.SE',
                                          'Value': 'SERVERS:8.8.8.8,8.8.4.4'
                                        },
                                        {
                                          'Key': 'avi.sysadmin-public-key.SE',
                                          'Value': ''
                                        }
                                      ]
    NetworkMapping = []
    NetworkMapping.append({'Name': 'Management', 'Network': seg['management_network']['name']})
#     count = 1
    for count_network, item in enumerate(seg['data_networks'], start=1):
      NetworkMapping.append({'Name': 'Data Network ' + str(count_network), 'Network': item['name']})
    for i in range(len(seg['data_networks']) + 1, 10):
      NetworkMapping.append({'Name': 'Data Network ' + str(i), 'Network': ''})
#       print(i)
    properties['NetworkMapping'] = NetworkMapping
#     print(properties)
    with open('properties.json', 'w') as f:
      json.dump(properties, f)
    govc_result = os.system('''export GOVC_DATACENTER={0}
                               export GOVC_URL={1}
                               export GOVC_GOVC_DATASTORE={2}
                               export GOVC_INSECURE=true
                               export GOVC_RESOURCE_POOL={3}
                               govc library.deploy -folder=/{0}/vm/\'{4}\' -options=./properties.json /{5}/se \'{6}\'
                               govc vm.change -vm \'{6}\' -c {7} -m {8}; govc vm.disk.change -vm \'{6}\' -size {9}G
                               govc vm.power -on \'{6}\'
                               govc tags.attach {10} /{0}/vm/\'{4}\'/\'{6}\'
                               sleep 180
                               govc vm.ip \'{6}\' | tee ip.txt'''.format(vcenter['dc'], vsphere_url, vcenter['datastore'], vcenter['resource_pool'], seg_folder, cl_name, se_name, seg['vcpus_per_se'], seg['memory_per_se'], seg['disk_per_se'], deployment_id))
    if govc_result != 0:
    #       os.system('export GOVC_DATACENTER={0}; export GOVC_URL={1}; export GOVC_INSECURE=true; govc library.rm {2}'.format(vcenter['dc'], vsphere_url, cl_name))
      print('Error when creating the SE')
      sys.exit(1)
    for network_data_index in range(len(seg['data_networks']) + 1, 10):
      print('dsconnecting ethernet-{0}'.format(network_data_index))
      govc_result = os.system('''export GOVC_DATACENTER={0}
                                 export GOVC_URL={1}
                                 export GOVC_GOVC_DATASTORE={2}
                                 export GOVC_INSECURE=true
                                 export GOVC_RESOURCE_POOL={3}
                                 govc device.disconnect -vm \'{4}\' ethernet-{5}'''.format(vcenter['dc'], vsphere_url, vcenter['datastore'], vcenter['resource_pool'], se_name, network_data_index))
    # govc device.disconnect -vm \'{6}\' ethernet-2 need do disconnect in regards to the amount of data_networks
      if govc_result != 0:
    #       os.system('export GOVC_DATACENTER={0}; export GOVC_URL={1}; export GOVC_INSECURE=true; govc library.rm {2}'.format(vcenter['dc'], vsphere_url, cl_name))
        print('Error when disconnecting ethernet-{0}'.format(network_data_index))
        sys.exit(1)
    with open('ip.txt', 'r') as file:
      ip = file.read().replace('\n', '')
#     print(ip)
#     params = {'name': ip}
# #     time.sleep(60)
#     se_connected = ''
#     count = 0
#     while defineClass.getObject('serviceengine', params)['count'] == 0:
#       time.sleep(5)
#       count += 1
#       if count == 40:
#         print('timeout for SE to be seen after deployment')
# #         os.system('export GOVC_DATACENTER={0}; export GOVC_URL={1}; export GOVC_INSECURE=true; govc library.rm {2}'.format(vcenter['dc'], vsphere_url, cl_name))
#         exit()
#     count = 0
#     while defineClass.getObject('serviceengine', params)['results'][0]['se_connected'] != True:
#       time.sleep(5)
#       count += 1
#       if count == 40:
#         print('timeout for SE to be connected after deployment')
# #         os.system('export GOVC_DATACENTER={0}; export GOVC_URL={1}; export GOVC_INSECURE=true; govc library.rm {2}'.format(vcenter['dc'], vsphere_url, cl_name))
#         exit()
    #
    # seg update name update and IP update if needed.
    #
    if seg['name'] != 'Default-Group' or any(network['dhcp'] == False for network in seg['data_networks']):
      params = {'name': ip}
      count = 0
      while defineClass.getObject('serviceengine', avi_credentials['tenant'], params)['count'] == 0:
        time.sleep(5)
        count += 1
        if count == 40:
          print('timeout for SE to be seen after deployment')
          sys.exit(1)
      count = 0
      while defineClass.getObject('serviceengine', avi_credentials['tenant'], params)['results'][0]['se_connected'] != True:
        time.sleep(5)
        count += 1
        if count == 40:
          print('timeout for SE to be connected after deployment')
          sys.exit(1)
      params = {'name': ip}
      se_data = defineClass.getObject('serviceengine', avi_credentials['tenant'], params)['results'][0]
      se_data['name'] = se_name
      params = {'name': seg['name'], 'cloud_uuid': cloud_no_access_vcenter_uuid}
      seg_uuid = defineClass.getObject('serviceenginegroup', avi_credentials['tenant'], params)['results'][0]['uuid']
      se_data['se_group_ref'] = '/api/serviceenginegroup/' + seg_uuid
      # end of to be tested
    # discover VM device if DHCP is false for data networks
    if any(network['dhcp'] == False for network in seg['data_networks']):
      govc_result = os.system('''export GOVC_DATACENTER={0}
                                 export GOVC_URL={1}
                                 export GOVC_INSECURE=true
                                 govc ls -json \'/{0}/vm/{2}/{3}\' | tee vm_devices.json >/dev/null'''.format(vcenter['dc'], vsphere_url, seg_folder, se_name))
      if govc_result != 0:
#         os.system('export GOVC_DATACENTER={0}; export GOVC_URL={1}; export GOVC_INSECURE=true; govc library.rm {2}'.format(vcenter['dc'], vsphere_url, cl_name))
        print('Error when discovering SE Hardware')
        sys.exit(1)
      with open('vm_devices.json', 'r') as stream:
        vm_devices = json.load(stream)
      # link mac address to Network
      for item in vm_devices['elements'][0]['Object']['Config']['Hardware']['Device']:
        for count in range(1, 11):
          if item['DeviceInfo']['Label'] == 'Network adapter ' + str(count):
#             index_networks = 0
            for index_networks, network in enumerate(networks):
              try:
                if item['Backing']['OpaqueNetworkId'] == network['OpaqueNetworkId'] and item['Connectable']['Connected'] == True:
                  networks[index_networks]['MacAddress'] = item['MacAddress']
              except:
                pass
              try:
                if item['Backing']['Port']['PortgroupKey'] == network['PortgroupKey'] and item['Connectable']['Connected'] == True:
                  networks[index_networks]['MacAddress'] = item['MacAddress']
              except:
                pass
#                 index_networks += 1
      # update se nic data
      for count_vnic, vnic in enumerate(se_data['data_vnics'], start=0):
        for network in networks:
          if vnic['mac_address'] == network['MacAddress']:
#             print([{'ctrl_alloc': False, 'ip': {'ip_addr': {'addr': network['ips'][seCount].split('/')[0], 'type': 'V4'}, 'mask': network['ips'][seCount].split('/')[1]}, 'mode': 'STATIC'}])
#             print([{'ctrl_alloc': False, 'ip': {'ip_addr': {'addr': str(IPv4Network(IPv4Interface(network['defaultGateway']).network)[int(network['ips'][seCount])]), 'type': 'V4'}, 'mask': network['defaultGateway'].split('/')[1]}, 'mode': 'STATIC'}])
            se_data['data_vnics'][count_vnic]['vnic_networks'] = [{'ctrl_alloc': False, 'ip': {'ip_addr': {'addr': str(network['ips'][seCount]), 'type': 'V4'}, 'mask': network['defaultGateway'].split('/')[1]}, 'mode': 'STATIC'}]
            se_data['data_vnics'][count_vnic]['dhcp_enabled'] = False
    if any(network['dhcp'] == False for network in seg['data_networks']) or seg['name'] != 'Default-Group':
      update_se = defineClass.putObject('serviceengine/' + se_data['uuid'], avi_credentials['tenant'], se_data)
      time.sleep(60)
    se_connected = ''
    count = 0
    params = {'name': ip}
    while defineClass.getObject('serviceengine', avi_credentials['tenant'], params)['count'] == 0:
      time.sleep(5)
      count += 1
      if count == 40:
        print('timeout for SE to be seen after seg update')
#         os.system('export GOVC_DATACENTER={0}; export GOVC_URL={1}; export GOVC_INSECURE=true; govc library.rm {2}'.format(vcenter['dc'], vsphere_url, cl_name))
        sys.exit(1)
    count = 0
    while defineClass.getObject('serviceengine', avi_credentials['tenant'], params)['results'][0]['se_connected'] != True:
      time.sleep(5)
      count += 1
      if count == 40:
        print('timeout for SE to be connected after seg update')
#         os.system('export GOVC_DATACENTER={0}; export GOVC_URL={1}; export GOVC_INSECURE=true; govc library.rm {2}'.format(vcenter['dc'], vsphere_url, cl_name))
        sys.exit(1)
    seCount += 1