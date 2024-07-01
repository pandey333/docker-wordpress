# Dockerized WordPress with Persistent Storage

A WordPress application with a MySQL database, ensuring persistent storage for the '/wp-content' directory.

## Prerequisites

- Docker installed on your machine
- Docker Compose installed on your machine

## Getting Started

### Clone the Repository

`git clone https://github.com/pandey333/docker-wordpress.git`
`cd docker-wordpress`

    Run compose file and can check the wordpress page at your local machine if we are running this in local or we can use ec2 and aws services as explained in below sections.

# AWS Environment Setup for WordPress Deployment
    1: Setting Up an EC2 Instance for Docker Containers
    2: Setting Up an RDS Instance for MySQL
    3: Setting Up an S3 Bucket for WordPress Uploads
    4: Setting Up an IAM Role with Necessary Permissions
    5: Connecting WordPress to RDS and S3

1. **EC2 Instance**:
   - Amazon Linux 2 instance configured to run Docker containers.
   - Located in a public subnet for internet access.

2. **RDS Instance**:
   - MySQL database engine hosted in Amazon RDS.
   - Located in a private subnet for enhanced security.

3. **S3 Bucket**:
   - Used to store WordPress media uploads.
   - Configured with proper access permissions.

4. **IAM Role**:
   - Provides necessary permissions to the EC2 instance to interact with S3 and RDS securely.
   

### Step 1: Setting Up an EC2 Instance for Docker Containers

#### Launch an EC2 Instance

**Navigate to the EC2 Dashboard**:
   - Click on "Launch Instance".
   - Choose "Amazon Linux 2 AMI".
   - Select an instance type.
   - Configure instance details (VPC, subnet, security group).
   - Add storage as needed.
   - Add tags for identification (optional).
   - Configure security group to allow inbound traffic on ports 80 (HTTP), 443 (HTTPS), and 22 (SSH) and outbound for all.
   - Launch the instance and select your SSH key pair.

**Connect to your EC2 Instance**

`ssh -i "my-key-pair.pem" ec2-user@your-ec2-public-dns`

#### Install Docker and Docker Compose in ec2.
     
```sudo yum update -y```
```sudo amazon-linux-extras install docker```
```sudo service docker start```
```sudo usermod -a -G docker ec2-user```

```sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose```
```sudo chmod +x /usr/local/bin/docker-compose```
```docker-compose --version```

### Step 2: Setting Up an RDS Instance for MySQL

**Launch RDS**:

   - Click on "Create database".
   - Choose "MySQL" as the engine option.
   - Select the appropriate version.
   - Configure DB instance class (choose a suitable instance type).
   - Set instance details (DB instance identifier, master username, password).
   - Configure advanced settings (VPC, subnet group, security group). We will attach the sg that is atttached to ec2 for inbound in rd to accept the traffic from that cofigured ec2. 
   - Enable backups and maintenance as per requirements.
   - Launch the instance.
   - Note the RDS Endpoint, will need this endpoint to connect WordPress to the RDS instance.

### Step 3: Setting Up an S3 Bucket for WordPress Uploads

   - Create a Bucket with unique name.
   - Select the region same as ec2.
   - Configure options (versioning, logging).
   - Set permissions (block all public access, manage bucket policy).

**Configure Bucket Policy:**

Bucket policy to allow public read access for WordPress uploads.

```yaml
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::your-bucket-name/*"
    }
  ]
}
```

### Step 4: Setting Up an IAM Role with Necessary Permissions

   - Create a Role:
   - Click on "Roles" -> "Create role".
   - Choose "AWS service" -> "EC2".
   - Attach policies:
         AmazonS3FullAccess
         AmazonRDSFullAccess
   - Review and create the role

**Attach IAM Role to EC2 Instance:**

    - Attach the created role to the created ec2 instance.

### Step 5: Connecting WordPress to RDS and S3

**Create a docker-compose.yml file:**


```yaml
version: '3.8'

services:
  wordpress:
    image: wordpress:latest
    restart: always
    ports:
      - 80:80
    environment:
      WORDPRESS_DB_HOST: your-rds-endpoint
      WORDPRESS_DB_USER: your-db-user
      WORDPRESS_DB_PASSWORD: your-db-password
      WORDPRESS_DB_NAME: your-db-name
      WORDPRESS_TABLE_PREFIX: wp_
      WORDPRESS_DEBUG: 'false'
      UPLOAD_MAX_FILESIZE: 64M
      PHP_MAX_INPUT_VARS: 1000
      PHP_MAX_EXECUTION_TIME: 300
    volumes:
      - wordpress:/var/www/html/wp-content
      - ./uploads.ini:/usr/local/etc/php/conf.d/uploads.ini

  mysql:
    image: mysql:5.7
    restart: always
    environment:
      MYSQL_DATABASE: your-db-name
      MYSQL_USER: your-db-user
      MYSQL_PASSWORD: your-db-password
      MYSQL_ROOT_PASSWORD: your-root-password
    volumes:
      - db:/var/lib/mysql

volumes:
  wordpress:
  db:
```

## Configure WordPress to Use S3

**Install and Configure WP Offload Media Plugin:**

- Install the "WP Offload Media Lite" plugin from the WordPress plugin repository.

- Configure the plugin with your S3 bucket credentials.


- Log in to Your WordPress Admin Dashboard:

- Navigate to your WordPress website's admin area. You can access it by appending /wp-admin to your domain (e.g., http://yourdomain.com/wp-admin).

- Navigate to Plugins:

- In the WordPress admin sidebar, click on "Plugins" -> "Add New".
Search for the Plugin:

- In the search bar, type "WP Offload Media Lite".

- Install the Plugin:

- Once you find the "WP Offload Media Lite" plugin in the search results, click on the "Install Now" button next to the plugin.
Activate the Plugin:

- After installation completes, click on the "Activate" button to activate the plugin on your WordPress site.

- Configure the Plugin:

- After activation, you may need to configure the plugin settings. This typically involves connecting the plugin to your AWS S3 bucket where you want to offload your media uploads. You will need to provide AWS credentials (Access Key ID and Secret Access Key) and specify the S3 bucket details.

### Verify S3 Uploads

- Once configured, upload a media file in wordpress. Verify that the file is uploaded to your AWS S3 bucket instead of the local server.

### Verify EC2 Instance Connectivity

```ssh -i "your-key-pair.pem" ec2-user@your-ec2-public-dns```


### Verify RDS Connectivity

```mysql -h your-rds-endpoint -u your-db-user -p```


### Verify WordPress Setup

- Open a web browser and navigate to your EC2 instance's public IP address or domain name.

### Configure GitHub Actions for CiCd with above created ec2

- Create .github/workflows/main.yml with the following content

```yaml
name: CI/CD Pipeline

on:
  push:
    branches:
      - main  

jobs:
  build:
    runs-on: ubuntu-latest  

    env:
      DOCKER_IMAGE: your-docker-image-name
      AWS_REGION: your-aws-region
      AWS_ACCOUNT_ID: your-aws-account-id
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      DB_HOST: ${{ secrets.DB_HOST }}
      DB_USER: ${{ secrets.DB_USER }}
      DB_PASSWORD: ${{ secrets.DB_PASSWORD }}

    steps:
      - name: Checkout repository
        uses: actions/checkout@v2  

      - name: Build Docker image
        run: |
          docker build -t $DOCKER_IMAGE .  # Build Docker image from Dockerfile
          docker tag $DOCKER_IMAGE:latest $DOCKER_IMAGE:${{ github.run_number }}  # Tag Docker image with build number

      - name: Test WordPress deployment
        run: |
          docker run -d -p 8080:80 --name wordpress $DOCKER_IMAGE:${{ github.run_number }}  # Run Docker container in detached mode
          sleep 10  # Wait for WordPress to start
          curl -f -s -o /dev/null http://localhost:8080  # Perform basic testing, e.g., checking if WordPress home page loads

      - name: Deploy to AWS EC2
        run: |
          aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
          aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
          aws configure set default.region $AWS_REGION
          docker tag $DOCKER_IMAGE:${{ github.run_number }} $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$DOCKER_IMAGE:${{ github.run_number }}
          docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$DOCKER_IMAGE:${{ github.run_number }}

          # SSH into EC2 instance and run Docker container (example command)
          ssh -o StrictHostKeyChecking=no ec2-user@$EC2_INSTANCE_IP 'docker pull $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$DOCKER_IMAGE:${{ github.run_number }}'

      - name: Clean up
        run: |
          docker stop wordpress  # Stop Docker container
          docker rm wordpress  # Remove Docker container
```

### How this cicd is working

- The pipeline is triggered by a push to the main branch of GitHub repository.

- Runs-on: The job runs on an ubuntu-latest virtual machine.

- Uses actions/checkout@v2 to fetch the latest code from your repository.

- Runs Docker commands to build the image using the Dockerfile.
Tags the Docker image with the build number for versioning.

- Runs the Docker container in detached mode. Waits for the WordPress application to start.

- Uses curl to check if the WordPress home page loads successfully.
Deploy to AWS EC2:

- Configures AWS CLI with the provided credentials and region.

- Tags and pushes the Docker image to AWS ECR (Elastic Container Registry).

- SSHs into the EC2 instance and runs the Docker container.
Clean Up:

- Stops and removes the local Docker container used for testing.