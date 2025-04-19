resource "aws_subnet" "private-us-east-1a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "192.168.0.0/19"
  availability_zone = "us-east-1a"

  tags = {
    Name                              = "private-us-east-1a"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/demo"      = "owned"
  }
}

resource "aws_subnet" "private-us-east-1b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "192.168.32.0/19"
  availability_zone = "us-east-1b"

  tags = {
    Name                              = "private-us-east-1b"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/demo"      = "owned"
  }
}

resource "aws_subnet" "private-us-east-1c" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "192.168.64.0/19"  # Next available block after 1a (0-31) and 1b (32-63)
  availability_zone = "us-east-1c"

  tags = {
    Name                              = "private-us-east-1c"
    "kubernetes.io/role/internal-elb" = "1"       # Required for internal load balancers
    "kubernetes.io/cluster/demo"      = "owned"   # Required for EKS to manage the subnet
  }
}


resource "aws_subnet" "public-us-east-1a" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "192.168.96.0/20"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name                         = "public-us-east-1a"
    "kubernetes.io/role/elb"     = "1" 
    "kubernetes.io/cluster/demo" = "owned"
  }
}


resource "aws_subnet" "public-us-east-1b" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "192.168.112.0/20"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name                         = "public-us-east-1b"
    "kubernetes.io/role/elb"     = "1" 
    "kubernetes.io/cluster/demo" = "owned"
  }
}

resource "aws_subnet" "public-us-east-1c" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "192.168.128.0/20"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = true

  tags = {
    Name                         = "public-us-east-1c"
    "kubernetes.io/role/elb"     = "1" 
    "kubernetes.io/cluster/demo" = "owned"
  }
}