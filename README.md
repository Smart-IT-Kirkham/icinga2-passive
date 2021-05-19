# Icinga2 Passive Check Script

Bash script to deliver a set passive checks to the Icinga2 external api interface.

## Permissions

Add a user into your `/etc/icinga2/conf.d/api-users.conf`

```text
object ApiUser "passive" {
  password = "SuperSecretKey"
  permissions = [ "actions/*" ]
}
```

We also only expose the required api path via the Nginx proxy with a snippet like this:

```nginx
    location ~* ^/v1/actions/process-check-result {
        proxy_pass https://healthcheck-container;

        # force timeouts if the backend dies
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;

        # set headers
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Host $remote_addr;
        proxy_set_header X-Forwarded-Port $server_port;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Server-Select $scheme;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Url-Scheme: $scheme;
        proxy_set_header Host $host;
        proxy_http_version 1.1;

        # by default, do not forward anything
        proxy_redirect off;
    }

    location ~* / {
        return 403;
    }
```

## Environment Variables

By using a .env you can provide the necessary variables to the bash script:

```shell
ICINGA_HOST=healthcheck.opusvl.com
ICINGA_PORT=443
ICINGA_USER=passive
ICINGA_PASSWORD=5e3486736d43883fc94410978cfd5018c35235f5013527ec8d318a66296c2736
```

## Icinga2 Config

This is a sample file for the configuration of incinga2. Place it in `/etc/icinga2/zones.d/[your zone]`

Notice how dummy is used so no checks happen locally and the addition of `enable_active_checks` to make it passive.

```text
object Host "[HOSTNAME]" {
    address = "[HOSTNAME]"
    check_command = "dummy"

    vars.no_ping = "true"
    vars.owner = "opusvl"
} 
    
object Service "check_disk" {
    host_name = "[HOSTNAME]"
    check_interval = 12h
    retry_interval = 1h

    enable_active_checks = false

    check_command = "dummy"
    vars.hostname = "[HOSTNAME]"
}

object Service "check_load" {
    host_name = "[HOSTNAME]"
    check_interval = 5m
    retry_interval = 15m

    enable_active_checks = false

    check_command = "dummy"
    vars.hostname = "[HOSTNAME]"
}

object Service "check_mem" {
    host_name = "[HOSTNAME]"
    check_interval = 5m
    retry_interval = 15m

    enable_active_checks = false

    check_command = "dummy"
    vars.hostname = "[HOSTNAME]"
}

object Service "check_procs" {
    host_name = "[HOSTNAME]"
    check_interval = 5m
    retry_interval = 15m

    enable_active_checks = false

    check_command = "dummy"
    vars.hostname = "[HOSTNAME]"
}
```
