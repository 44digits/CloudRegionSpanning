#cloud-config

packages:
-   nginx

write_files:
-   content: |
        <HTML>
        <BODY>
        <H1>Testing Server</H1>
        </BODY>
        </HTML>
    path: /var/html/index.html
    permissions: '0644'

runcmd:
-   dd if=/dev/urandom of=/var/www/html/sample.file bs=10M count=1
