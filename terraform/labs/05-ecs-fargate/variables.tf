variable "region" {
  default = "us-east-1"
  type    = string
}

variable "prefix" {
  default = "lab05"
  type    = string
}

variable "container_image" {
  description = "Image to run — defaults to public nginx. Replace with your ECR image after pushing."
  default     = "public.ecr.aws/nginx/nginx:latest"
  type        = string
}
