#cloud-config

write_files:
-   encoding: b64
    content: ${networktest_file}
    owner: root:root
    path: /usr/local/bin/networktest
    permissions: '0755'
-   content: |
        #!/bin/bash
        declare _SERVERIP=${server_publicip}
        declare _PROXYIP=${proxy_publicip}

        /usr/local/bin/networktest http://$_SERVERIP/sample.file http://$_PROXYIP/sample.file
    owner: ec2-user:ec2-user
    path: /home/ec2-user/networktest-run
    permissions: '0644'

