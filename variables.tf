
variable test_vcp_cidr {
    type    = string
    default = "10.0.0.0/16"
}

variable test_subnets {
    type    = list(string)
    default = ["10.0.1.0/24"]
}

variable test_subnet_names {
    type    = list(string)
    default = ["subnet1"]
}

variable test_subnets_public_ips {
    type    = list(bool)
    default = [false] 
}