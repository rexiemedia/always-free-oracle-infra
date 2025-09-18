# always-free-oracle-infra

## Project Infrastructure Setup
This project defines an infrastructure setup on **Oracle Cloud Infrastructure (OCI)** using **Terraform** to provision a Virtual Cloud Network (VCN), subnets, security lists, and virtual machine instances. Additionally, it includes an **Ansible configuration** for automating the deployment and configuration of services on the provisioned VMs.

---

## Overview
The infrastructure consists of:

- A VCN with public and private subnets.  
- Four virtual machine instances (VMs) with a mix of public and private subnet placements.  
- Security configurations to allow specific traffic (e.g., SSH, HTTP, HTTPS, ICMP).  
- A NAT Gateway for private subnet internet access.  
- Ansible playbooks to configure services like **Nginx, Wireguard, Tomcat, Wazuh, Elasticsearch, and Nexus**.  

Each VM is configured with **1 vCPU and 4GB of RAM** using the `VM.Standard.A1.Flex` shape, and a **swap file** is created to enhance performance.

---

## Infrastructure Details (Terraform)

### Networking
- **VCN:** CIDR block `10.0.0.0/16`
- **Subnets:**
  - **Public Subnet:** CIDR `10.0.1.0/24`, allows public IPs, routes traffic through an Internet Gateway.
  - **Private Subnet:** CIDR `10.0.2.0/24`, no public IPs, outbound traffic via NAT Gateway.
- **Internet Gateway:** Enables internet access for the public subnet.  
- **NAT Gateway:** Allows private subnet VMs to access the internet.  
- **Route Tables:**
  - Public RT → Internet Gateway  
  - Private RT → NAT Gateway  
- **Security Lists:**
  - Public SL → SSH (22) from home IP, ICMP (type 8, code 0) from home IP, HTTP/HTTPS (80/443) from any, unrestricted egress.  
  - Private SL → Full traffic within VCN `10.0.0.0/16`, unrestricted egress.  

### Virtual Machines
- **Configuration:**
  - 4 VMs (`vm1, vm2, vm3, vm4`) using `VM.Standard.A1.Flex`.  
  - 1 vCPU, 4GB RAM each.  
  - `vm3` in **public subnet** with public IP, others in **private subnet** (no public IPs).  
  - OS image: `var.os_image_ocid` with 50GB boot volume.  
  - 2GB swap file configured via cloud-init.  
  - SSH enabled with `var.ssh_public_key`.  

### Terraform Variables
- `compartment_ocid`: The OCI compartment ID.  
- `home_ip`: IP allowed for SSH and ICMP access.  
- `os_image_ocid`: The OCID of the OS image.  
- `ssh_public_key`: SSH public key for VM access.  

---

## Ansible Setup
The `infra-setup` directory contains Ansible playbooks and related files to configure the VMs with various services.

### Directory Structure
