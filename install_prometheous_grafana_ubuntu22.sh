!/bin/bash

#Creating prometheus system users & directory
sudo apt update -y
sudo useradd --no-create-home --shell /bin/false prometheus
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus
sudo chown prometheus:prometheus /var/lib/prometheus

#Downloading prometheus binary file, using version 2.46
cd /tmp/
echo 'Downloading prometheus binary file'
wget https://github.com/prometheus/prometheus/releases/download/v2.46.0/prometheus-2.46.0.linux-amd64.tar.gz
tar -xvf prometheus-2.46.0.linux-amd64.tar.gz
#Moving config file & setting the owner of the prometheus user
cd prometheus-2.46.0.linux-amd64
sudo mv console* /etc/prometheus
sudo mv prometheus.yml /etc/prometheus
sudo chown -R prometheus:prometheus /etc/prometheus
#Moving binaries and setting the owner
sudo mv prometheus /usr/local/bin/
sudo chown prometheus:prometheus /usr/local/bin/prometheus

#Prometheus configuration file
sudo nano /etc/prometheus/prometheus.yml

#Creating prometheus systemd file
#sudo nano /etc/systemd/system/prometheus.service
cat << EOF >> etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target" 
EOF

sudo systemctl daemon-reload

#Start, Enable, Status prometheus service
sudo systemctl start prometheus
sudo systemctl enable prometheus
#sudo systemctl status prometheus

#check firewall port to access via browser
echo 'Open Ports 9090, 9100 & 3000'
sudo ufw allow 9090/tcp
sudo ufw allow 9100/tcp
sudo ufw allow 3000/tcp

#DOWNLOAD NODE EXPORTER

cd /tmp
echo 'Downloading node exporter'
wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
sudo tar xvfz node_exporter-*.*-amd64.tar.gz
#move binary file to /usr/local/bin location
sudo mv node_exporter-*.*-amd64/node_exporter /usr/local/bin/
#create node_exporter user to run the node exporter service
sudo useradd -rs /bin/false node_exporter

#Dreating node exporter systemd service
#sudo nano /etc/systemd/system/node_exporter.service
cat << EOF >> /etc/systemd/system/node_exporter.service
[Unit]

Description=Node Exporter

After=network.target

[Service]

User=node_exporter

Group=node_exporter

Type=simple

ExecStart=/usr/local/bin/node_exporter

[Install]

WantedBy=multi-user.target
EOF

#start and enable node_exporter service
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter
sudo systemctl status node_exporter

#Configure the Node Exporter as Prmometheus target
#sudo nano /etc/prometheus/prometheus.yml
cat << EOF >> /etc/prometheus/prometheus.yml
- job_name: 'Node_Exporter'
    scrape_interval: 5s
    static_configs:
      - targets: ['<Server_IP_of_Node_Exporter_Machine>:9100']
EOF
#restart prometheus service
sudo systemctl restart prometheus
#Hit the URL in your web browser to check weather our target is successfully scraped by Prometheus or not

#INSTALLING GRAFANA

#add Grafana GPG key 
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
#add the Grafana repository to your APT sources
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main" -y
sudo apt update -y
#install grafana
sudo apt install grafana -y
sudo systemctl start grafana-server
#verify grafana is running
sudo systemctl status grafana-server
sudo systemctl enable grafana-server

echo 'Remember to configure
-> Prometheus as Grafana DataSource
-> Grafana Dashboard to Monitor Linux Server'