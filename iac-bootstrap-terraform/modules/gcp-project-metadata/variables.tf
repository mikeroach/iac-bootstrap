variable "project" {
  type        = string
  description = "Google Cloud Platform project for which to define metadata"
}

variable "metadata" {
  type        = map(string)
  description = "Key/values to set as exclusive metadata for the managed project"
}