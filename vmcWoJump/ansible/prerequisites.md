```
mkdir -p /etc/ansible
echo '[defaults]' | tee /etc/ansible/ansible.cfg
echo 'host_key_checking = False' | tee -a /etc/ansible/ansible.cfg
echo 'host_key_auto_add = False' | tee -a /etc/ansible/ansible.cfg
echo 'deprecation_warnings = False' | tee -a /etc/ansible/ansible.cfg
chmod 600 /root/.ssh/id_rsa
```