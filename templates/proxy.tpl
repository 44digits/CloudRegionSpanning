#cloud-config

packages:
-   nginx

write_files:
-   content: |
        server {
                listen 80;
                listen [::]:80;

                location / {
                        proxy_buffering off;
                        proxy_pass http://${server_privateip};
                        include proxy_params;
                }
        }
    path: /etc/nginx/sites-available/default
    permissions: '0644'
