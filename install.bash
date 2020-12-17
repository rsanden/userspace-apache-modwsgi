#!/bin/bash

set -e

MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$MYDIR"

source "$MYDIR/config"

mkdir -p "$LOGDIR"
mkdir -p "$PREFIX/src"

###########################################################
# APR 1.7.0
###########################################################
cd "$PREFIX/src"
wget 'https://downloads.apache.org/apr/apr-1.7.0.tar.bz2'
tar -xf apr-1.7.0.tar.bz2
cd apr-1.7.0
./configure --prefix="$PREFIX"
make -j4
make install

###########################################################
# APR-Util 1.6.1
###########################################################
cd "$PREFIX/src"
wget 'https://downloads.apache.org/apr/apr-util-1.6.1.tar.bz2'
tar -xf apr-util-1.6.1.tar.bz2
cd apr-util-1.6.1
./configure --prefix="$PREFIX" --with-apr="$PREFIX"
make -j4
make install

###########################################################
# Apache 2.4.46
###########################################################
cd "$PREFIX/src"
wget 'https://downloads.apache.org/httpd/httpd-2.4.46.tar.bz2'
tar -xf httpd-2.4.46.tar.bz2
cd httpd-2.4.46
./configure --prefix="$PREFIX" --enable-mpms-shared=all --enable-mods-shared=all --with-apr="$PREFIX" --with-apr-util="$PREFIX"
make -j4
make install

###########################################################
# mod_wsgi 4.7.1
###################################################
cd "$PREFIX/src"
wget 'https://files.pythonhosted.org/packages/74/98/812e68f5a1d51e9fe760c26fa2aef32147262a5985c4317329b6580e1ea9/mod_wsgi-4.7.1.tar.gz'
tar -xf mod_wsgi-4.7.1.tar.gz
cd mod_wsgi-4.7.1
./configure --with-apxs="$PREFIX/bin/apxs" --with-python="$(which $PYTHON)"
make -j4
make install

#--- Do Substitutions ---
mkdir -p "$PREFIX/src"
cp -r "$MYDIR/templates" "$PREFIX/src"
cd "$PREFIX/src/templates"
source substitutions.bash

#--- Initial Config ---
mkdir -p "$PREFIX/var/run"

mkdir -p "$LOGDIR"
ln -s "$LOGDIR" "$PREFIX/log"

mv -f "$PREFIX/src/templates/httpd.conf.template" "$PREFIX/conf/httpd.conf"

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
sleep 3
"$MYDIR/start"
EOF

chmod 755 start stop restart

#--- Create "hello world" myapp.wsgi file ---
mkdir -p "$APPDIR1"
cp "$PREFIX/src/templates/wsgi.py" "$APPDIR1"

#--- Create venv (python version must match mod_wsgi) ---
cd "$PREFIX"
$PYTHON -m venv env
source env/bin/activate
pip install --upgrade pip
pip install wheel
deactivate

#--- Remove temporary files ---
rm -r "$PREFIX/src"

#--- Create cron entry ---
line="\n# $STACKNAME stack\n*/10 * * * * $PREFIX/bin/start"
(crontab -l 2>/dev/null || true; echo -e "$line" ) | crontab -

#--- Start the application ---
$PREFIX/bin/start
