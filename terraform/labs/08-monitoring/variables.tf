variable "region" {
  default = "us-east-1"
  type    = string
}

variable "prefix" {
  default = "lab08"
  type    = string
}

variable "alarm_email" {
  description = "Email address to receive CloudWatch alarm notifications"
  default     = ""
  type        = string
}
