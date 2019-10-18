/* This submodule (if you want to call it that) manages project metadata for our
GCP Projects. I use it to set the default compute region/zones and enable OS Login,
since unfortunately the Project Factory module doesn't seem to natively support
doing so. In retrospect, I probably could have just repeated these resource
declarations in main.tf - especially with how I pass the metadata uniquely for
each project. */

resource "google_compute_project_metadata" "project_metadata" {
  project  = var.project
  metadata = var.metadata
}