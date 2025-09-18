provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = "../oci_api_key.pem"  # <-- Use the relative path here
  region           = var.region
}