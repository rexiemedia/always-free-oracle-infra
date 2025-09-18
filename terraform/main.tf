data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid
}

# -----------------------
# Networking
# -----------------------
resource "oci_core_vcn" "vcn" {
  cidr_block      = "10.0.0.0/16"
  compartment_id = var.compartment_ocid
  display_name    = "my-project-vcn"
}

resource "oci_core_internet_gateway" "ig" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name    = "my-project-ig"
}

# Added NAT Gateway for private subnet internet access
resource "oci_core_nat_gateway" "nat_gateway" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "my-project-nat-gateway"
}

resource "oci_core_route_table" "public_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name    = "public-rt"
  route_rules {
    network_entity_id = oci_core_internet_gateway.ig.id
    destination       = "0.0.0.0/0"
  }
}

resource "oci_core_route_table" "private_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name    = "private-rt"
  # Added rule to send outbound traffic through the NAT Gateway
  route_rules {
    network_entity_id = oci_core_nat_gateway.nat_gateway.id
    destination       = "0.0.0.0/0"
  }
}

resource "oci_core_security_list" "public_sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name    = "public-sl"
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
  ingress_security_rules {
    protocol = "6"
    source   = "${var.home_ip}/32"
    tcp_options {
      min = 22
      max = 22
    }
  }
  ingress_security_rules {
    protocol = "1"
    source   = "${var.home_ip}/32"
    icmp_options {
      type = 8
      code = 0
    }
  }
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 80
      max = 80
    }
  }
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 443
      max = 443
    }
  }
}

resource "oci_core_security_list" "private_sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name    = "private-sl"
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
  ingress_security_rules {
    protocol = "all"
    source   = "10.0.0.0/16"
  }
}

resource "oci_core_subnet" "public_subnet" {
  cidr_block      = "10.0.1.0/24"
  compartment_id    = var.compartment_ocid
  vcn_id          = oci_core_vcn.vcn.id
  display_name    = "public-subnet"
  route_table_id    = oci_core_route_table.public_rt.id
  security_list_ids  = [oci_core_security_list.public_sl.id]
}

resource "oci_core_subnet" "private_subnet" {
  cidr_block                 = "10.0.2.0/24"
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.vcn.id
  display_name               = "private-subnet"
  route_table_id             = oci_core_route_table.private_rt.id
  security_list_ids          = [oci_core_security_list.private_sl.id]
  prohibit_public_ip_on_vnic = true
}

# -----------------------
# VM Definitions
# -----------------------
locals {
  vms = {
    vm1 = { assign_public_ip = false, subnet_name = "private-subnet" }
    vm2 = { assign_public_ip = false, subnet_name = "private-subnet" }
    vm3 = { assign_public_ip = true, subnet_name = "public-subnet" }
    vm4 = { assign_public_ip = false, subnet_name = "private-subnet" }
  }
}

resource "oci_core_instance" "vms" {
  for_each          = local.vms
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id    = var.compartment_ocid
  shape             = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = 1
    memory_in_gbs = 4
  }
  
  # Use source_details directly on the instance resource
  source_details {
    source_id   = var.os_image_ocid
    source_type = "image"
    boot_volume_size_in_gbs = 50
  }

  display_name = each.key

  create_vnic_details {
    subnet_id        = each.value.assign_public_ip ? oci_core_subnet.public_subnet.id : oci_core_subnet.private_subnet.id
    assign_public_ip = each.value.assign_public_ip
  }
  
  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(<<EOF
#cloud-config
runcmd:
- fallocate -l 2G /swapfile
- chmod 600 /swapfile
- mkswap /swapfile
- swapon /swapfile
- echo '/swapfile none swap sw 0 0' >> /etc/fstab'
EOF
    )
  }
}