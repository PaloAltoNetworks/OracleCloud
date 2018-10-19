# Gets a list of Availability Domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = "${var.tenancy_ocid}"
}

# Gets the boot volume attachments for each instance
data "oci_core_boot_volume_attachments" "block_attach" {
  depends_on          = ["oci_core_instance.vm"]
  availability_domain = "${oci_core_instance.vm.0.availability_domain}"
  compartment_id      = "${var.compartment_ocid}"
  instance_id         = "${oci_core_instance.vm.id}"
}
