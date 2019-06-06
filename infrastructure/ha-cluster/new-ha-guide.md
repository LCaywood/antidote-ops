Steps:

1. Run terraform apply. Make sure that in the TCP load balancer configuration, only the first group is enabled.

2. Execute the ansible playbook to bootstrap the cluster

    virtualenv venv/ && source venv/bin/activate && pip install -r requirements.txt
    ansible-playbook -i inventory/gce.py newha-prepinstances.yml

3. Copy the join command from the output to join the other two nodes to the cluster
4. Modify the terraform code to join the other two groups to the LB and re-run apply
5. Ensure that k8s-ha.networkreliability.engineering points to one of the control instances public IPs, or some other publicly accessible method like an HTTP LB
6. Run playbook against packet servers if it wasn't already
7. SSH to packet servers and join them to cluster using a regular join command - not the control plane command you used before.





# TODOs

- [ ] Spin up HA cluster again, but on the internet. Solidify automation.
- [ ] Spin up automated packet+fastly/cloudflare infra that joins to ha cluster
- [ ] Automate observer setup