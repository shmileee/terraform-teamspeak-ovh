# Backend
terraform {
  backend "swift" {
    container   = "test-terraform"
    region_name = "WAW"
  }
}
