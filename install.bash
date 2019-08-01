#!/bin/bash

set -e

MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$MYDIR"

source "$MYDIR/config"
APP1=$(basename $APPDIR1)

mkdir -p "$PREFIX/src"

###########################################################
# APR 1.7.0
###########################################################
cd "$PREFIX/src"
wget 'http://apache.communilink.net/apr/apr-1.7.0.tar.bz2'
tar -xf apr-1.7.0.tar.bz2
cd apr-1.7.0
./configure --prefix="$PREFIX"
make -j4
make install

###########################################################
# APR-Util 1.6.1
###########################################################
cd "$PREFIX/src"
wget 'http://apache.communilink.net/apr/apr-util-1.6.1.tar.bz2'
tar -xf apr-util-1.6.1.tar.bz2
cd apr-util-1.6.1
./configure --prefix="$PREFIX" --with-apr="$PREFIX"
make -j4
make install

###########################################################
# Apache 2.4.37
###########################################################
cd "$PREFIX/src"
wget 'http://apache.communilink.net/httpd/httpd-2.4.39.tar.bz2'
tar -xf httpd-2.4.39.tar.bz2
cd httpd-2.4.39
./configure --prefix="$PREFIX" --enable-mpms-shared=all --enable-mods-shared=all --with-apr="$PREFIX" --with-apr-util="$PREFIX"
make -j4
make install

###########################################################
# mod_wsgi 4.6.5
###################################################
cd "$PREFIX/src"
wget 'https://files.pythonhosted.org/packages/26/03/a3ed5abc2e66c82c40b0735c2f819c898d136879b00be4f5537126b6a4a4/mod_wsgi-4.6.7.tar.gz'
tar -xf mod_wsgi-4.6.7.tar.gz
cd mod_wsgi-4.6.7
./configure --with-apxs="$PREFIX/bin/apxs" --with-python="$(which $PYTHON)"
make -j4
make install

#--- Do Substitutions ---
mkdir -p "$PREFIX/src"
cp -r "$MYDIR/templates" "$PREFIX/src"
cd "$PREFIX/src/templates"
source substitutions.bash

#--- Initial Config ---
mkdir -p "$HOME/logs/$APP1"
mkdir -p "$PREFIX/var/run"
mv "$PREFIX/conf/httpd.conf" "$PREFIX/conf/httpd.conf.original"
cp "$PREFIX/src/templates/httpd.conf.template" "$PREFIX/conf/httpd.conf"

#--- Create start/stop/restart scripts ---
cd "$PREFIX/bin"

cat << "EOF" > start
#!/bin/bash
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
"$MYDIR/apachectl" start
EOF

cat << "EOF" > stop
#!/bin/bash
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
"$MYDIR/apachectl" stop
EOF

cat << "EOF" > restart
#!/bin/bash
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
"$MYDIR/stop"
sleep 1
"$MYDIR/start"
EOF

chmod 755 start stop restart

#--- Create "hello world" myapp.wsgi file ---
mkdir -p "$APPDIR1"
cp "$PREFIX/src/templates/myapp.wsgi" "$APPDIR1"

#--- Remove temporary files ---
rm -r "$PREFIX/src"

#--- Create cron entry ---
line="\n# $STACKNAME stack\n*/20 * * * * $PREFIX/bin/start"
(crontab -l 2>/dev/null; echo -e "$line" ) | crontab -

#--- Start the application ---
$PREFIX/bin/start
