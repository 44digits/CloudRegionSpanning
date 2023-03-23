#cloud-config

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
    path: /tmp/networktest-run
    permissions: '0777'

