variable gke_master_ip {
  description = "The IP address of the GKE master or a semicolon separated string of multiple IPs"
}

variable gke_node_tag {
  description = "The network tag for the gke nodes"
}

variable region {
  default = "us-central1"
}

variable zone {
  default = "us-central1-f"
}

variable network {
  default = "default"
}

provider google {
  region = "${var.region}"
}

module "nat" {
  // source  = "github.com/GoogleCloudPlatform/terraform-google-nat-gateway"
  source     = "../../"
  region     = "${var.region}"
  zone       = "${var.zone}"
  tags       = ["${var.gke_node_tag}"]
  network    = "${var.network}"
  subnetwork = "${var.network}"
}

// Route so that traffic to the master goes through the default gateway.
// This fixes things like kubectl exec and logs
resource "google_compute_route" "gke-master-default-gw" {
  count            = "${var.gke_master_ip == "" ? 0 : length(split(";", var.gke_master_ip))}"
  name             = "${var.gke_node_tag}-master-default-gw-${count.index + 1}"
  dest_range       = "${element(split(";", replace(var.gke_master_ip, "/32", "")), count.index)}"
  network          = "${var.network}"
  next_hop_gateway = "default-internet-gateway"
  tags             = ["${var.gke_node_tag}"]
  priority         = 700
}

output "ip-nat-gateway" {
  value = "${module.nat.external_ip}"
}
