# Userspace Apache + modwsgi installer

A userspace Apache + mod\_wsgi installer

Installation is performed as follows:

    vim config
    ./install.bash

The "`vim config`" step is to set the following options in the **`config`** file:

  - **`STACKNAME`**: The name of this Apache+modwsgi stack, which will have associated log files in `$HOME/logs`
  - **`PREFIX`**: The install location where the Apache+modwsgi will be installed
  - **`PORT`**: The port associated with the application created via the Control Panel
  - **`DOMAIN1`**: The domain name that the Apache+modwsgi stack will serve. *(you can add more later in `httpd.conf`)*
  - **`APPDIR1`**: The path to the website files that the Apache+modwsgi stack will serve *(you can add more later with virtualhosts)*
  - **`PYTHON`**: The python version against which to build the mod\_python Apache module.

After installation, the following are done for you:

  - `start`, `stop`, and `restart` scripts are created in the `$PREFIX/bin` directory
  - The `start` script is run to start the instance
  - A cronjob is created to start the instance once every 20 minutes if it's not running

Dependencies:
  - PCRE development files (CentOS: *pcre-devel*, Ubuntu: *libpcre3-dev*)
  - Python development files (CentOS: *python-devel*, Ubuntu: *python-dev* or *python3-dev*)
