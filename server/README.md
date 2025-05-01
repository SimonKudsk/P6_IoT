# Serverside docker setup for P6 project
This docker-compose setup contains the necessary server-side services for our P6 project. This guide will explain how to configure this setup.

## Preparation of domain
For the domain, there are two options, depending on whether you are using it for production with access to the public internet, or for your local machine.

### Local setup
When wanting to use this setup locally, you should configure domain names for easy access.

First, enter the command `sudo nano /etc/hosts`. Here, you can configure local "domains" on your computer. Assuming you want the domain to be 'p6.test', add the following lines to the bottom of the file:

```
127.0.0.1 influxdb.p6.test  
127.0.0.1 grafana.p6.test  
127.0.0.1 nodered.p6.test
127.0.0.1 mosquitto.p6.test
```

With this, you should be able to easily access the project.

### Public internet setup
To configure the project for access via public internet, use cloudflare tunnels. Create an account, redirect your domain nameservers to cloudflare, and sign up for the zero trust dashboard - the free plan is all we need.

Install cloudflared on your computer, and sign in with 'cloudflared login'.

This will generate a file `cert.pem` in your home directory. Copy this to the `/config/cloudlared/` folder.

After this, execute the command `cloudflared tunnel create <name>`. This will create an argo tunnel, which you can connect to the domain with. Executing this command will create the file `<tunnel-uuid>.json` in your home directory. Copy this to the `/config/cloudlared/` folder, and rename it to `credentials.json`. Save the UUID for later, as we need it for the .env file.

Once this is completed, ensure that you configure the correct subdomains for '<tunnel-uuid>.cfargotunnel.com' in the cloudflare dashboard with CNAME. You cannot use a wildcard; register each subdomain!

## Permissions
For the applications to work as intended, the folder './data' needs to permission 33:33. To achieve this, use the command `sudo chown -R 33:33 ./data`. This will set the owner and group of the folder to 'www-data', which is the user that runs the applications.

## Certificates
As the services depend on using HTTPS, we need to a certificate to run the services. For local development, we can use self-signed certificates. For production, we can use the certificates provided by cloudflare.

### Create self-signed certificates
To create self-signed certificates, use the following command:

```openssl req -x509 -days 365 -out certificate.crt -keyout certificate.key -newkey rsa:2048 -nodes -sha256 -subj '/CN=p6.test' -extensions EXT -config <( printf "[dn]\nCN=p6.test\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:p6.test,DNS:*.p6.test\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")```

In the above command, replace 'p6.test' with the domain you configured earlier. This will create two files: `certificate.crt` and `certificate.key`. Move these files to the `/config/nginx/certs/` folder. If you encounter issues entering the sites in your browser, ensure that you trust the certificate. This can be done by opening the certificate in your browser and trusting it.

## Configuration of .env
To configure this project properly, create a duplicate of the `.env_example` file and call it .env

### Environment
For the compose profile, there are two options:

- prod
- dev

'prod' is only for production, when cloudflared is needed to connect the setup to the public internet, via a tunnel. When this is not the case, use dev, which will omit cloudflared.

To configure the environment, set the `COMPOSE_PROFILE` variable to either 'prod' or 'dev'.

### InfluxDB
For InfluxDB, the following variables are needed:

- INFLUXDB_DB
- INFLUXDB_ADMIN_USER
- INFLUXDB_ADMIN_PASSWORD
- INFLUXDB_ORG
- INFLUXDB_ADMIN_TOKEN

### Grafana
For Grafana, the following variable is needed:

- GF_SECURITY_ADMIN_PASSWORD

### Domains
For the domains, the following variables are needed:

- INFLUXDB_HOST
- GRAFANA_HOST
- NODERED_HOST

Here, the domains should be set to the domain names you configured earlier.

### Cloudflared
For cloudflared, the following variables are needed:

- TUNNEL_ID
- WILDCARD_DOMAIN

The `TUNNEL_ID` is the UUID of the tunnel you created earlier.  For `WILDCARD_DOMAIN`, use the domain previously chosen. This has to be set as a wildcard; e.g. if you chose 'p6.test', set this to '*.p6.test'.