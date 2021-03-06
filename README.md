# Ansible playbooks

A collection of roles and standard playbooks for deploying a common deployment / front application stack. These are mostly for HHVM + PHP and Node + Ghost infrastructures.

_I use a common username for all management processes on my servers, you can configure it globally in each playbook or play — it's the `{{ user }}` var. I would recommend to use a global variable by defining `user` in `<INVENTORY_FILE_LOCATION>/group_vars/all` like that :_


> NB : the default inventory file location is `/etc/ansible/hosts`, and `/usr/local/etc/ansible/hosts` on Mac OS X

```yaml
---
# Your user
user: "myUser"
```

If you use an ELK (Elastic Search - Logstash - Kibana) monitoring stack, you can also indicate it here :

```yaml
---
# Your ELK monitoring Server
monitoring_server: "kibana.myHost.com"
```

And if you plan to deploy for MX servers, you can add :

```yaml
---
# The MX domain
mx_domain: "mydomain.com"
```


> NB : Your inventory file should have the four groups `[front-servers]`, `[monitoring-servers]`, `[mx-servers]` and `[deploy-servers]`.


## Roles available

  - #### base

    - Ensures that the server has at least some basics tools like `sudo` and `python-apt` for Ansible to run correctly. 
    - Updates and upgrades `apt`, adds a backports repository for Debian.
    - Grants the `user` a no-password `sudo` and install base packages like `curl`, and the like.

  - #### backup

    - Ensures a /home/{{user}}/backup folder is present for backups
    - Creates a DB + files backup script
    - Creates a cron task for daily backups and ensures that there is a backup user with correct permissions on the DB if needed

  - #### terminal

    Changes the `.bash_profile` and `.vimrc` for ones with colors and aliases.

  - #### maria_db

    Ensures that `maria_db` is the lastest and that the service is runnning correctly. Adds a consistent `/root/.my.cnf` file for logging in.

  - #### git

    Ensures `git` is here, and writes a reasonable `gitconfig` file.

  - #### nginx

    Ensures that `nginx` is the lastest and that the service is runnning correctly. Also uploads a secured configuration for `nginx`.

  - #### brad 

    Instantiates a standard [brad](https://github.com/tchapi/brad) configuration on the deployment server. _Brad is a very simple and straightforward companion for deployment written in pure bash 4 (see more [here](https://github.com/tchapi/brad))._

  - #### hhvm

    - Ensures that `hhvm` is installed.
    - Copies a standard `supervisor` configuration for running `hhvm` as a server that respawns automatically.

  - #### mongo

    Ensures that `mongo-10gen` is the lastest and that the service is runnning correctly. 

  - #### node

    Ensures that `node`, `npm` and some other tools are installed correctly. 

  - #### php-cli

    Installs the `php5` command line interface (for running in shell, or running Symfony 2 tasks when deploying).

  - #### rsa_pub

    Copies over your ssh key to the servers.

  - #### ruby

    Installs `ruby` and CSS tools : `sass`, `compass` and `lessc`.

  - #### supervisor

    Ensures `supervisor` is present and at the latest, and performs various fixes for standard installs.

  - #### logstash

    Ensures logstash is up and running, and parses logs from Nginx, as well as `messages` and `syslog`.

  - #### elasticsearch

    Ensures elasticsearch is at the latest version.

  - #### kibana

    Downloads the latest release of Kibana and adds the correct nginx conf for it, adding an `htpasswd` configuration file.
    Also adds general dashboard for logstash.

  - #### upgrade

    Standard role that performs a full upgrade (see the upgrade playbook below).

  - #### mlmmj 

    Installs postfix along with mlmmj using the configured MX domain. For more info on Mlmmj see [this blog post](http://www.foobarflies.io/a-simple-web-interface-for-mlmmj/)

## Playbooks

#### base & deploy

Ensures that all servers have the correct basis for management, common administrative tasks and standard packages, that they are up to date, and then applies the webserver play to webservers (front-servers) and the deploy play to deployment-servers.

The playbook is rather straightforward.

> Before deploying a new server, you must create a new user `{{ user }}`` (_as root_) and copy your ssh keys :

    useradd -s /bin/bash {{user}} && mkdir /home/{{user}} && chown {{user}}:{{user}} /home/{{user}}
    passwd tchap
    mkdir /home/tchap/.ssh && vi authorized_keys
    cd /root/.shh && vi authorized_keys
    vi /etc/hostname # change hostname 
    /etc/init.d/hostname.sh start

This done, when deploying a new server :

    ansible-playbook -v -l myNewServer playbooks/base.yml
    # Then
    ansible-playbook -l myNewServer playbooks/deploy.yml --ask-vault-pass

#### dist-upgrade

    ansible-playbook playbooks/dist-upgrade.yml

Performs a full upgrade on all hosts, basically boiling down to :

    sudo apt-get update
    sudo apt-get upgrade
    sudo apt-get dist-upgrade

#### mlmmj

Just plays the mlmmj role alone :

    ansible-playbook playbooks/mlmmj.yml

#### Reminder

If you want to execute a single shell command :

    # Gets the speed of each cpu 
    ansible all -m shell -a "cat /proc/cpuinfo | grep MHz"

## Licence

These roles and playbooks are released under the MIT licence. Enjoy !!
