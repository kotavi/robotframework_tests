#!/bin/bash
#yum install -y python-pip
#apt-get -y install python-pip

#sudo  apt-get install libcurl4-openssl-dev
#yum install libcurl-devel
#sudo apt-get install build-essential autoconf libtool pkg-config python-opengl python-imaging python-pyrex python-pyside.qtopengl idle-python2.7 qt4-dev-tools qt4-designer libqtgui4 libqtcore4 libqt4-xml libqt4-test libqt4-script libqt4-network libqt4-dbus python-qt4 python-qt4-gl libgle3 python-dev

cd $HOME/integration_test/src/dist/requests-2.3.0/
sudo  python setup.py install

cd $HOME/integration_test/src/dist/robotframework-2.8.5/
sudo  python setup.py install

cd $HOME/integration_test/src/dist/PyYAML-3.11/
sudo  python setup.py install

pip install pycurl

#cd $HOME/venv/integration_test/src/dist/webpy/
#sudo  python setup.py install

#cd $HOME/venv/integration_test/src/dist/Robotframework-Database-Library/
#sudo  python setup.py install

#sudo  pip install PyMySQL

#cd $HOME/venv/integration_test/src/dist/
#tar -xvf redis-2.10.3.tar.gz
#cd redis-2.10.3/
#sudo  python setup.py install

#cd $HOME/venv/integration_test/src/dist/
#tar -xvf robotframework-sshlibrary-2.1.1.tar.gz
#cd robotframework-sshlibrary-2.1.1/
#sudo  python setup.py install

#using pip freeze define that all the packages were installed successfully

#cd $HOME/venv/integration_test/src/dist/elasticsearch-py/
#sudo  python setup.py install

#cd $HOME/venv/integration_test/src/dist/kafka-python/
#sudo  python setup.py install

#cd $HOME/venv/integration_test/src/dist/
#cd influxdb-2.4.0/
#sudo  python setup.py install