# Certbot + Let's Encrypt DNS Validation for `checkit.tjrcade.com`

These instructions are for:

- `AlmaLinux 9`
- `Cloudflare` DNS
- `Nginx`
- A subdomain app at `checkit.tjrcade.com`

This setup uses Certbot with the `dns-01` challenge through the Cloudflare API. It does not require opening port `80` for Let's Encrypt validation.

## Important Notes

- Your existing Cloudflare `CNAME` for `checkit.tjrcade.com` can stay in place.
- Certbot will create and remove a temporary TXT record at `_acme-challenge.checkit.tjrcade.com`.
- The application `CNAME` record and the ACME TXT record are separate.
- If `checkit.tjrcade.com` is proxied by Cloudflare, that is fine.
- If you ever create validation-related `CNAME` records manually, keep those `DNS only`, not proxied.

## 1. Confirm the app DNS record exists in Cloudflare

Typical application record:

```text
Type: CNAME
Name: checkit
Target: your-app-hostname.example.net
Proxy status: Proxied or DNS only
```

This record handles application traffic. Certbot does not validate that record directly.

## 2. Install `snapd` on AlmaLinux 9

```bash
sudo dnf install epel-release
sudo dnf upgrade -y
sudo dnf install snapd -y
sudo systemctl enable --now snapd.socket
sudo ln -s /var/lib/snapd/snap /snap
sudo reboot
```

After reboot, reconnect to the server.

## 3. Install Certbot and the Cloudflare DNS plugin

```bash
sudo dnf remove certbot python3-certbot\* -y
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/local/bin/certbot
sudo snap set certbot trust-plugin-with-root=ok
sudo snap install certbot-dns-cloudflare
```

## 4. Create a Cloudflare API token

Create a Cloudflare API token with access limited to the `tjrcade.com` zone.

Recommended permission:

- `Zone:DNS:Edit`

Scope it only to the zone you need.

## 5. Save the Cloudflare API token on the server

Replace `YOUR_CLOUDFLARE_API_TOKEN` with the real token:

```bash
sudo mkdir -p /root/.secrets/certbot
sudo tee /root/.secrets/certbot/cloudflare.ini > /dev/null <<'EOF'
dns_cloudflare_api_token = YOUR_CLOUDFLARE_API_TOKEN
EOF
sudo chmod 600 /root/.secrets/certbot/cloudflare.ini
```

## 6. Request the certificate for `checkit.tjrcade.com`

```bash
sudo certbot certonly \
  --dns-cloudflare \
  --dns-cloudflare-credentials /root/.secrets/certbot/cloudflare.ini \
  --dns-cloudflare-propagation-seconds 60 \
  -d checkit.tjrcade.com
```

If your zone updates quickly, you can reduce the propagation delay later. `60` seconds is a safe starting point.

## 7. Confirm the certificate files exist

```bash
sudo ls -l /etc/letsencrypt/live/checkit.tjrcade.com/
```

You should have:

- `/etc/letsencrypt/live/checkit.tjrcade.com/fullchain.pem`
- `/etc/letsencrypt/live/checkit.tjrcade.com/privkey.pem`

## 8. Install and enable Nginx

If Nginx is not already installed:

```bash
sudo dnf install nginx -y
sudo systemctl enable --now nginx
```

## 9. Create the Nginx config

Replace `127.0.0.1:3000` with your real application upstream if needed.

```bash
sudo tee /etc/nginx/conf.d/checkit.tjrcade.com.conf > /dev/null <<'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name checkit.tjrcade.com;

    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name checkit.tjrcade.com;

    ssl_certificate /etc/letsencrypt/live/checkit.tjrcade.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/checkit.tjrcade.com/privkey.pem;

    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;

    add_header X-Frame-Options SAMEORIGIN;
    add_header X-Content-Type-Options nosniff;
    add_header Referrer-Policy strict-origin-when-cross-origin;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF
```

## 10. Test and reload Nginx

```bash
sudo nginx -t
sudo systemctl reload nginx
```

## 11. Open firewall ports if needed

If `firewalld` is enabled:

```bash
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

## 12. Test automatic renewal

```bash
sudo certbot renew --dry-run
```

If this succeeds, renewal is correctly configured.

## Optional: Advanced `_acme-challenge` CNAME Delegation

You do not need this for the normal Cloudflare plugin setup.

This is only for advanced cases where you want `_acme-challenge.checkit.tjrcade.com` delegated to a different DNS zone:

```text
_acme-challenge.checkit.tjrcade.com  CNAME  _acme-challenge.checkit.validation.example.com
```

If you use this pattern, Let's Encrypt will follow the CNAME for `dns-01` validation, but your Certbot automation must be set up to update the target zone correctly.

## Summary

- App hostname: `checkit.tjrcade.com`
- Validation method: `dns-01`
- DNS provider: `Cloudflare`
- Web server: `Nginx`
- Certificate files:
  - `/etc/letsencrypt/live/checkit.tjrcade.com/fullchain.pem`
  - `/etc/letsencrypt/live/checkit.tjrcade.com/privkey.pem`

## References

- Certbot instructions: <https://certbot.eff.org/instructions?os=snap&tab=wildcard&ws=other>
- Cloudflare Certbot plugin docs: <https://certbot-dns-cloudflare.readthedocs.io/en/stable/>
- Let's Encrypt challenge types: <https://letsencrypt.org/docs/challenge-types/>
- Snapd on AlmaLinux: <https://snapcraft.io/docs/tutorials/install-the-daemon/almalinux-os/>
- Cloudflare proxy status: <https://developers.cloudflare.com/dns/proxy-status/>
