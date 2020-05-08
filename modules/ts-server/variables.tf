variable "name" {
  description = "Name of teamspeak instance"
}

variable "ssh_public_key" {
  description = "The path of the ssh public key that will be used"
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_private_key" {
  description = "The path of the ssh private key that will be used"
  default     = "~/.ssh/id_rsa"
}

variable "flavor_name" {
  description = "Flavor name of nodes."
  default     = "s1-2"
}

variable "instances_count" {
  description = "Number of teamspeak instances per region"
  default     = 1
}

variable "ssh_user" {
  description = "SSH username"
}

variable "region" {
  description = "OpenStack region"
}

