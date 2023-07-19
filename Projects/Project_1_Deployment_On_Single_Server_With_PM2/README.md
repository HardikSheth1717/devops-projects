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

### Create key pairs on AWS to connect newly created servers
<br>

**Step 1 - Generate SSH key pair**

Generate an SSH key pair if you don't already have one. You can use tools like `ssh-keygen` to generate an SSH key pair.

```
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

This command generates an RSA key pair with a key size of 4096 bits. Replace "your_email@example.com" with your own email address.

**Step 2 - Import key pairs in AWS**

Upload the public key to AWS. In the AWS Management Console, go to the EC2 service, select "Key Pairs" in the navigation panel, and click "Import Key Pair." Provide a name for the key pair `my-new-pk` and paste the contents of the public key file (id_rsa.pub by default) into the "Public Key Contents" field.

<i>Please make sure to use `my-new-pk` name for the key pair. If you want to use different name, then you have to update `key_name` field in `./Infrastructure/terraform/aws/ec2.tf`.</i>

### Create EC2 instance with Terraform


You can find the Terraform script in `./Infrastructure/terraform/aws/`. This script will create two EC2 instances on AWS. 

Please follow below commands to execute the Terraform script:

First, navigate to `./Infrastructure/terraform/aws/` folder and initialize the Terraform.

```
terraform init
```

Next, create a plan to review the deployment changes.

```
terraform plan
```

Finally, if everything looks good, apply changes and create the EC2 instances.

```
terraform apply
```

After the successful creation of EC2 instances, Terraform will print instance id, public IP and private IP addresses of the newly created EC2 instances.

Terraform will create below two EC2 instances:
1. `controlplane-server` - This server will be used to manage and configure our deployment server. Terraform has already installed Ansible on this server.
2. `web-server` - This server will be used to deploy our applications.

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

Now, we have to copy the public key to our `web-server` server, on which we are going to host our application.

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

In our case, Terraform has already installed Ansible and updated the inventory file on the `controlplane-server` server. So, you don't need follow steps 1-3, just follow step 4. But you can update inventory file manually by following steps 1-3.

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

Execute below commond to verify the inventory file configuration.

```ansible-inventory --list -y```

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

Next, we have create Ansible playbook to configure our web server. We will transfer `./Infrastructure/ansible/` folder on the `controlplane-server` server.

```
scp -i C:\Users\<your-users-folder>\.ssh\aws -r ..\..\ansible\ ubuntu@<public_ip_address>:/home/ubuntu
```

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

Once you update the variables according to your needs, execute below command to run the playbook.

```
ansible-playbook playbook.yaml
```

It will take couple of minutes to finish the execution of the playbook. Once its completed, SSH into `web-server` and verify that the processes of both the applications using below command.

```
pm2 ls
```
<i>Note: Use sudo if your user do not have permissions.</i>

Now, if you check with your public ip address, the react application will be accessible. Our next you can configure any domain so that it will point to `web-server`. This step is optional.