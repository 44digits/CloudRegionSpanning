locals {
  common_tags = {
    Project = var.project
    Date    = formatdate("YYYY MMM DD", timestamp())
  }
  name_prefix = var.project
}

