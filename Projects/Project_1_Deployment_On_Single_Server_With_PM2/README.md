# Deployment on a single server with PM2 (Setup a Dev/Test environment)

This project demonstrates how can we setup a Linux server on the cloud and deploy React and NodeJS application using PM2.

## Tech Stack
1. Front-end: ReactJS
2. Back-end: NodeJS (NestJS)
3. Database: MySQL and Redis

## Deployment Architecture

We are going to use cloud infrastructure in this tutorial. Below is the deployment architecture we will create to deploy our application.

![Alt text](<./Docs/Deployment Architecture PM2.png>)

### Tools and Services used for deployment

#### `Terraform`
We will use Terraform to create our deployment infrastructure in AWS.

#### `Ansible`
We will use Ansible to configure our web application server and also deploy our React and NodeJS applications for the first time.

#### `AWS EC2`
We will use AWS EC2 instance (Ubuntu) to deploy our application web server and controller server.

#### `AWS RDS`
We will host our database on AWS RDS for MySQL.

#### `Docker`
We will host Redis database as a Docker containers on the AWS EC2 instance.

#### `PM2`
We can also run our applications using PM2. PM2 is a popular process manager tool.

#### `Nginx`
We will expose our applications using reverse proxy on the Nginx.

#### `Certbot`
We will create SSL certificates for our applications using Certbot.

## Setup Infrastructure


#### Prerequisites
<ul>
<li>Install AWS CLI</li>
<li>Install Terraform CLI</li>
</ul>

In this section, we will setup the deployment infrastructure on AWS using Terraform.

Let's start. First of all, we need to generate SSH keys to connect our EC2 instances.

### Generate key pairs and import in AWS to connect newly created servers
<br>

**Step 1 - Generate SSH key pair**

Generate an SSH key pairs in your local machine if you don't already have one. You can use tools like `ssh-keygen` to generate an SSH key pair.

```
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

This command generates an RSA key pair with a key size of 4096 bits. Replace "your_email@example.com" with your own email address.

**Step 2 - Import key pairs in AWS**

Upload the public key to AWS. In the AWS Management Console, go to the EC2 service, select "Key Pairs" in the navigation panel, and click "Import Key Pair". Provide a name for the key pair `my-new-pk` and paste the contents of the public key file (`id_rsa.pub` by default) into the "Public Key Contents" field.

<i>Please make sure to use `my-new-pk` name for the key pair. If you want to use different name, then you have to update `key_name` field in `./Infrastructure/terraform/aws/ec2.tf` file.</i>

### Create the deployment infrastructure on AWS with Terraform


You can find the Terraform scripts in `./Infrastructure/terraform/aws/`. This scripts will create the deployment infrastructure on AWS. 

Please follow below commands to execute the Terraform script:

First, navigate to `./Infrastructure/terraform/aws/` folder and initialize the Terraform.

```
terraform init
```

Next, create a plan to review the deployment changes.

```
terraform plan
```

Finally, if everything looks good, apply changes and create the deployment infrastructure on AWS.

```
terraform apply
```

After the successful execution of the script, Terraform will print instance id, public IP and private IP addresses of the newly created EC2 instances and instance id and public endpoint of the MySQL RDS.

Terraform will create below resources on AWS:
1. `semaphore-vpc` - A virtual private cloud in which our Dev/Test environment will be deployed.
2. `semaphore-igw` - An internet gateway.
3. `semaphore-subnet-z1` and `semaphore-subnet-z2` - Two subnets, each in two different availability zones.
4. `semaphore-rt` - A route table.
5. `semaphore-route` - A route for internet gateway.
6. `semaphore-zone1-route-association` and `semaphore-zone2-route-association` - Route table mappings for both the subnets.
7. `ec2-instance-sg` - A security group for the EC2 instances.
8. `rds-instance-sg` - A security group for the RDS instance.
9. `rds-subnet-group` - A subnet group for RDS.
10. `controlplane-server` - This server will be used to manage and configure our deployment server. Terraform has already installed Ansible on this server.
11. `web-server` - This server will be used to deploy our applications.
12. `mysql-server` - An RDS instance for MySQL database.

Next, connect `controlplane-server` server using SSH from your local machine and double check that Ansible is installed correctly by executing below command:

```
ansible --version
```

Above commnad will return the installed version of Ansible, if it was installed correctly.

### Setup SSH to connect `web-server` server from `controlplane-server` server
<br>

**Step 1 - Create a key pair**

First, create a key pair on the `controlplane-server` server:

```
ssh-keygen
```

It will ask you some questions. Just press `Enter` to select default value.

Once the command is completed, it will generate private and public keys in `<your home directory>/.ssh` directory: `id_rsa` and `id_rsa.pub`.

**Step 2 - Copy public key to `web-server` server**

Now, we have to copy the public key to our `web-server` server, on which we are going to host our applications.

First, copy public key contents from `id_rsa.pub` file.

```
cat ~/.ssh/id_rsa.pub
```

Next, connect the `web-server` server and navigate to ssh directory.

```
cd ~/.ssh
```

Now, open `authorized_keys` file and copy the public key string in that file.

```
nano authorized_keys
```

If you are not a root user, then you have to assign permission to the folder.

```
chmod -R go= ~/.ssh
chown -R ubuntu:ubuntu ~/.ssh
```

**Step 3 - Test SSH connection**

We are all set! Let's test SSH connection using below command.

```
ssh username@app_server_address
```

### Configure Ansible inventory file on `controlplane-server` server
<br>

In our case, Terraform has already installed Ansible and updated the inventory file on the `controlplane-server` server. So, you don't need to follow steps 1-3, just follow step 4. But you can update inventory file manually by following steps 1-3.

**Step 1 - Update inventory file**

Open Ansible hosts file. This is a default Ansible inventory file.

```
sudo nano /etc/ansible/hosts
```

Next, add our web server's private ip address in this file as shown below.

```
[webservers]
web-server ansible_host=172.31.2.214 ansible_connection=ssh ansible_user=ubuntu
```

<br>

Here, I have defined a group named <b>webservers</b> and added our web server in that group. Make sure to change the IP address and user of the server.

**Step 3 - Verify the inventory file**

Execute below command to verify the inventory file configuration.

```ansible-inventory --list```

The output of above command must display the server information which we have configured in the previous step.

**Step 4 - Test the connection**

Finally, its time to check the connection with the server.

```
ansible web-server -m ping
```

Above command will ping the application server. Note, in the above command, `web-server` must match with the name we have defined in the inventory file. `ping` is an ansible module to ping the remote host.

If everyting is configured properly, it will generate an output similar to below

```
web-server | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

### Transfer Ansible files on `controlplane-server` server

Next, we have created an Ansible playbook to configure our web server. We will transfer `./Infrastructure/ansible/` folder on the `controlplane-server` server using below command.

```
scp -i C:\Users\<your-users-folder>\.ssh\aws -r ..\..\ansible\ ubuntu@<public_ip_address>:/home/ubuntu
```

Here, you have to replace the name of the SSH private key `aws` with your name (mostly id_rsa) in -i option of `spc` command.

### Setup newly created server using Ansible
<br>

Now, SSH in to `controlplane-server` server and navigate to `/home/<your_user_name>/ansible/` folder. There will be a playbook file `playbook.yaml`. This playbook will do following things:
<ol>
<li>Install and configure NodeJS 18</li>
<li>Install and configure Nginx</li>
<li>Install PM2</li>
<li>Install Docker Engine</li>
<li>Install certbot to generate SSL certificates</li>
<li>Install and configure Firewall</li>
<li>Deploy Redis container</li>
<li>Clone the project repositories</li>
<li>Create processes for react application in PM2</li>
<li>Create processes for nest applications in PM2</li>
</ol>

Now, before executing the playbook, you have to change the values of the Ansible variables in `variables.yaml` file. Mainly, you have to change `rds_host`, `nestapi_url` and `host_site_name`. All other variables are optional. You will get `rds_host` from Terraform's output variables.

<i>Note: I have hosted my applications on the domain https://semaphore-technologies.com in this tutorial. If you want to access your website with just IP address then you have to modify `nestapi_url` and `host_site_name` parameters and replace them with your IP address.</i>

Once you update the variables according to your needs, execute below command to run the playbook.

```
ansible-playbook playbook.yaml
```

It will take couple of minutes to finish the execution of the playbook. Once its completed, SSH into `web-server` and verify that the processes of both the applications using below command.

```
pm2 ls
```
<i>Note: Use sudo if your user do not have permissions.</i>

Now, if you check with your public ip address, the react application will be accessible. Next, you can configure any domain so that it will point to `web-server` and SSL certificate using certbot. This steps are optional.

<i>Note: I have hosted my applications on the domain https://semaphore-technologies.com in this tutorial. So, I have configured my Nginx config file accordingly. If you want to access your website with just IP address then you have to modify line number 10 in `/home/<your_user_name>/ansible/templates/nginx.template` file, just replace domain name with `localhost`. :relaxed:</i>


### Configure SSL certificate with certbot on `web-server` server

We have already installed `certbot` on the `web-server` server using Ansible. Now, navigate to this directory `/etc/letsencrypt`.

```
cd /etc/letsencrypt
```

Now, execute below command to run certbot.

```
certbot
```

After executing this command, it will prompt you couple of question. Once done, it will generate a dns challange. You need to add the given CNAME record in your domain's dns management so that certbot can verify your authority for that particular domain. After adding CNAME record, wait for few minutes so that record will be updated on most of the dns server (use https://dnschecker.org/).

Once done, hit enter, it will show you the list of domains you have configured in the Nginx configuration file. Just hit enter, to generate SSL for all the domains and you'r done! :sunglasses:

Just check your website in the browser. It will also add HTTP to HTTPS redirect rules for you. :fire: