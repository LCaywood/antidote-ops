rm -rf venv/ && virtualenv venv && source venv/bin/activate
pip install -r requirements.txt
rm -f provision-packet-cluster.retry

# You will need to export PACKET_API_TOKEN for this to work
ansible-playbook -i inventory/packet_net.py provision-packet-cluster.yml

