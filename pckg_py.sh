#!/bin/bash
#add check of which OS is it.
#according to this choose installation for python-pip

#yum install -y python-pip

apt-get -y install python-pip

sudo -E apt-get install libcurl4-openssl-dev
#apt-get install python-dev

cd $HOME/integration_test/src/dist/requests-2.3.0/
sudo -E python setup.py install
echo "------------------------------------------------\n\n"

cd $HOME/integration_test/src/dist/robotframework-2.8.5/
sudo -E python setup.py install
echo "------------------------------------------------\n\n"

cd $HOME/integration_test/src/dist/elasticsearch-py/
sudo -E python setup.py install
echo "------------------------------------------------\n\n"
cd $HOME/integration_test/src/dist/kafka-python/
sudo -E python setup.py install

echo "------------------------------------------------\n\n"
cd $HOME/integration_test/src/dist/influxdb-2.4.0/
sudo -E python setup.py install
echo "------------------------------------------------\n\n"
cd $HOME/integration_test/src/dist/PyYAML-3.11/
sudo -E python setup.py install
echo "------------------------------------------------\n\n"
cd $HOME/integration_test/src/dist/webpy/
sudo -E python setup.py install
echo "------------------------------------------------\n\n"
cd $HOME/integration_test/src/dist/Robotframework-Database-Library/
sudo -E python setup.py install
echo "------------------------------------------------\n\n"
sudo -E pip install PyMySQL
echo "------------------------------------------------\n\n"
cd $HOME/integration_test/src/dist/
tar -xvf redis-2.10.3.tar.gz
cd redis-2.10.3/
sudo -E python setup.py install
echo "------------------------------------------------\n\n"
cd $HOME/integration_test/src/dist/
tar -xvf robotframework-sshlibrary-2.1.1.tar.gz
cd robotframework-sshlibrary-2.1.1/
sudo -E python setup.py install
echo "------------------------------------------------\n\n"

#pip install pycurl
#using pip freeze define that all the packages were installed successfully
