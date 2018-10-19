resource "oci_core_instance" "vm" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ads.availability_domains[var.availability_domain - 1],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "vm-series"
  shape               = "${var.instance_shape}"

  create_vnic_details {
    subnet_id        = "${oci_core_subnet.mgmt_subnet.id}"
    display_name     = "vm"
    assign_public_ip = true
    hostname_label   = "vm"
  }

  source_details {
    source_type = "image"
    source_id   = "${var.vm_image_ocid[var.region]}"

    //for PIC image: source_id   = "${var.vm_image_ocid}"

    # Apply this to set the size of the boot volume that's created for this instance.
    # Otherwise, the default boot volume size of the image is used.
    # This should only be specified when source_type is set to "image".
    #boot_volume_size_in_gbs = "60"
  }

  # Apply the following flag only if you wish to preserve the attached boot volume upon destroying this instance
  # Setting this and destroying the instance will result in a boot volume that should be managed outside of this config.
  # When changing this value, make sure to run 'terraform apply' so that it takes effect before the resource is destroyed.
  #preserve_boot_volume = true


  //required for metadata setup via cloud-init
  //   metadata {
  //     ssh_authorized_keys = "${var.ssh_public_key}"
  //     user_data           = "${base64encode(file(var.BootStrapFile))}"
  //   }

  timeouts {
    create = "60m"
  }
}

resource "oci_core_vnic_attachment" "vnic_attach_untrust" {
  instance_id  = "${oci_core_instance.vm.id}"
  display_name = "vnic_untrust"

  create_vnic_details {
    subnet_id              = "${oci_core_subnet.untrust_subnet.id}"
    display_name           = "vnic_untrust"
    assign_public_ip       = true
    skip_source_dest_check = false
    private_ip             = "${var.untrust_private_ip_primary}"
  }
}

resource "oci_core_private_ip" "untrust_private_ip" {
  #Get Primary VNIC id
  vnic_id = "${element(oci_core_vnic_attachment.vnic_attach_untrust.*.vnic_id, 0)}"

  #Optional	
  display_name   = "untrust_ip"
  hostname_label = "untrust"
  ip_address     = "${var.untrust_floating_private_ip}"
}

resource "oci_core_public_ip" "untrust_public_ip" {
  #Required
  compartment_id = "${var.compartment_ocid}"
  lifetime       = "${var.untrust_public_ip_lifetime}"

  #Optional    
  display_name  = "vm-untrust"
  private_ip_id = "${oci_core_private_ip.untrust_private_ip.id}"
}

resource "oci_core_vnic_attachment" "vnic_attach_trust" {
  instance_id  = "${oci_core_instance.vm.id}"
  display_name = "vnic_trust"

  create_vnic_details {
    subnet_id              = "${oci_core_subnet.trust_subnet.id}"
    display_name           = "vnic_trust"
    assign_public_ip       = false
    skip_source_dest_check = true
    private_ip             = "${var.trust_private_ip_primary}"
  }
}

resource "oci_core_private_ip" "trust_private_ip" {
  #Get Primary VNIC id
  vnic_id = "${element(oci_core_vnic_attachment.vnic_attach_trust.*.vnic_id, 0)}"

  #Optional	
  display_name   = "trust_ip"
  hostname_label = "trust"
  ip_address     = "${var.trust_floating_private_ip}"
}
