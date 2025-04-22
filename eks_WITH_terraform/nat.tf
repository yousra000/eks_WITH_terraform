resource "aws_eip" "nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.vpc-igw]
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public-us-east-1a.id
  
    
  tags = {
    Name = "k8s-nat"
  }

  depends_on = [aws_internet_gateway.vpc-igw]
}