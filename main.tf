// Configure the Google Cloud provider
provider "google" {
 credentials = file("service-key-epam-test-306514.json")
 project     = "epam-test-306514"
 region      = "us-east1"
}

//CREATE NON DEFAULT SEVICE ACCOUNT LOL

resource "google_service_account" "service_account" {
  account_id   = var.my_account
  display_name = "i_created_by_teraform_serviceaccount"
}


resource "google_compute_instance" "default" {
  name         = "epam-test-blablacar"
  machine_type = "f1-micro"
  zone         = "us-central1-c"

  tags = ["encrypted", "epam", "test"]

  boot_disk {
    
    disk_encryption_key_raw = var.encryption_key  
    
    initialize_params {
      image = "debian-cloud/debian-9"

      }
  }

  // Local SSD disk
  //scratch_disk {
    //interface = "SCSI"
  //}

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }


  metadata = {

     serial-port-enable     = false
     block-project-ssh-keys = true
  }
  
    
  allow_stopping_for_update = "true"
  metadata_startup_script = "echo hi > /test.txt"

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.service_account.email
    scopes = ["cloud-platform"]
  }
}

