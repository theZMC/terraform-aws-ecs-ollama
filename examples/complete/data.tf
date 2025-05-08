data "http" "my_ip" {
  url = "http://ifconfig.me"
  request_headers = {
    "User-Agent" = "curl"
  }
}

data "aws_availability_zones" "available" {}
