#cloud-config

users:
-   name: testuser
    groups: users, testuser
    shell: /bin/bash
write_files:
-   encoding: b64
    content: ${networktest_file}
    path: /usr/local/bin/networktest
    permissions: '0755'
-   content: |
        #!/bin/bash
        declare _SERVERIP=${server_publicip}
        declare _PROXYIP=${proxy_publicip}

        /usr/local/bin/networktest 10 http://$_SERVERIP/sample.file http://$_PROXYIP/sample.file
    owner: testuser:testuser
    path: /home/testuser/networktest-run
    permissions: '0777'

