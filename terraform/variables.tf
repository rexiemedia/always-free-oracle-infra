variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "compartment_ocid" {}
variable "region" {}
variable "ssh_public_key" {
  description = "The SSH public key content."
  type        = string
}
variable "os_image_ocid" {}
variable "home_ip" {
  description = "Your home public IP address (without /32)"
  type        = string
}
