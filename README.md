# Docker
docker images, build files, and scripts

Each sub-directory contains the files required to build, start, and maintain an image.

The helper script 'auto.sh' should be used for most actions.  

## Install
To install on a new machine, use the following command:
```
./auto.sh install
```

# Images
Each image is built using the following command
```
sudo docker build -t {image_name} .
```
This command will use the 'dockerfile' as input and build the image by either using a local image or pulling down the base from github.

To build/update/run a specific docker image, simply run the build.sh script and pass in the name of the sub-directory to build.
```
./auto.sh build dns
./auto.sh build dhcp
```

## DNS
The DNS zone configuration is updated each time the container is started.

To update the DNS zone files, follow these instructions EXACTLY:
* edit dns/zonefiles/db.reeps.local
* increment the generation id before anything else
* check that you incremented the generation id
* make your changes
* submit to git
* on dns vm, perform a git pull
* use docker to stop and then start the dns container

```
docker stop dns
docker start dns
```

manual install steps
```
cd dns
sudo docker build -t auto_dns .
sudo docker run --name dns -v `pwd`/zonefiles:/data/bind -p 53:53/udp -p 53:53 auto_dns
sudo cp docker_dns.conf /etc/init/
```

## DHCP
The DNS configuration files are updated each time the container is started.

To update the DHCP config files, follow these instructions:
* edit dhcp/config/dhcpd.conf
* save the file and submit to git
* on dhcp vm, perform a git pull
* use docker to stop and then start the dhdp container

## LDAP
LDAP is configured live using various ldap-utils commands.  In order to access the IPC interface for validating the server configuration, you must access the docker container directly since it is isolated from the host OS.

Assuming the ldap container is running, open a shell prompt in the container.
```
docker exec -it ldap bash
```

Then execute local commands to validate the config using the IPC interface (ldapi).
```
ldapsearch -Q -Y EXTERNAL -LLL -H ldapi:/// -b cn=config dn
```

To validate your connectivity to the ldap server use the following command:
```
ldapsearch -x -LLL -H ldap://10.4.166.2 -b dc=reeps,dc=local dn
```

The results should look similar to:
```
# ldapsearch -x -LLL -H ldap://10.4.166.2 -b dc=reeps,dc=local dn
dn: dc=reeps,dc=local

dn: cn=admin,dc=reeps,dc=local
```

### Add Content to LDAP DB
Create files with .ldif extension and add using the ldapadd utility:
```
# ldapadd -x -D cn=admin,dc=reeps,dc=local -H ldap://10.4.166.2 -W -f add_nodes_groups.ldif
Enter LDAP Password:
adding new entry "ou=People,dc=reeps,dc=local"

adding new entry "ou=Groups,dc=reeps,dc=local"

adding new entry "cn=Automation,ou=Groups,dc=reeps,dc=local"

adding new entry "cn=Clinical,ou=Groups,dc=reeps,dc=local"
```
