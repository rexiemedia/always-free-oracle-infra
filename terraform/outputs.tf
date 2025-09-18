output "vm1_private_ip" {
  value = oci_core_instance.vms["vm1"].private_ip
}
output "vm2_private_ip" {
  value = oci_core_instance.vms["vm2"].private_ip
}
output "vm3_public_ip" {
  value = oci_core_instance.vms["vm3"].public_ip
}
output "vm4_private_ip" {
  value = oci_core_instance.vms["vm4"].private_ip
}