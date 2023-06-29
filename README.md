
# "Instant" Azure Proxy Server
The following short guide will allow you to create a simple Flatcar Linux VM instance in Azure using my default settings, and the cheapest configuration possible (>$4USD/mo as of 06/23). Flatcar is designed as a container OS, and is perfect for spinning up an instance of Nginx Proxy Manager.

## Step 1
Clone the files from this project and cd into the main directory
```bash
git clone https://github.com/alecsliger/instaproxy && cd instaproxy
```
## Step 2
Install Azure CLI & login via command line
- [Microsoft's Guide](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)

and 

Install Docker

- [Docker's Guide](https://docs.docker.com/engine/install/)

## Step 3
### This step and its prerequisites will only need to be completed once 
You will need update the parameter variables in the 'redeploy.sh' script with your editor of choice with your:
- Preferred Region (e.g "eastus")
- Authorized IP address for SSH (e.g. "8.8.8.8")
- Public SSH key (e.g. "ssh-rsa Aaaa111222333...")
- and Your Azure Subscription ID (e.g AAAAA-BBBBBB-CCCCC-DDDDD)
    - After logging in, you can run the below command and copy the string in quotes to get your ID
    ```bash
    az account show | grep id
    ```
- (Optionally: update paths to template files, if moved)

Don't forget to accept the terms of the Flatcar image:
```bash
az vm image terms show --urn kinvolk:flatcar-container-linux-free:stable-gen2:latest
```
```bash
az vm image terms accept --urn kinvolk:flatcar-container-linux-free:stable-gen2:latest
```
Finally, run the script with the options c, r, i, s, and p to update the template files and create the prerequisite group.
```bash
chmod +x redeploy.sh && ./redeploy.sh -crisp
```

The newly created resources should be automatically associated like so:

![ResourceVisualizer](images/diagram.png)

## Step 4

After the previous command has completed sucessfully, run the script again with the 'd' option to deploy the main template.

```bash
./redeploy.sh -d
```

Re-provisioning the server is as simple as running this command again.

## Step 5

SSH into your new proxy server, CD into the directory with your YAML config, and start NPM

```bash
cd ~ && docker-compose up -d
```
Congratz

# Details about the 'redeploy.sh' script
OPTIONS:
```
  -p      Runs pre-deployment operations to create the resource group and dependency devices. You should only need to run this once

  -d      This option will destroy and reprovision your VM. This is a destructive operation, and any data not saved from your VM will be lost

  -r      Apply the region variable in this script to both parameter files for deployment

  -i      Regenerate the Igniton config from Butane.yml and append result to the main parameters 'custom data' field

  -s      Apply the SSH key variable in this script to the main parameter file

  -c      Apply Azure subscription ID variable from this script to the main parameter file

  -h      Show this menu
```

# Modifications

You can change various items in the ARM template and still retain the core functionality of the project; Most notably, the Ignition configuration

## Ignition

Included with the template is a YAML file called 'butane.yml'. This file contains all the additional parameters that structure the deployment of the read-only file system on the VM. By default, the 'custom data' field in the main ARM template is populated with the Ignition output from the file converted into base64 format. This configuration adds:

- 2GB of swap space to the OS for running on the Azure B1ls 
- A systemd service to install/update docker-compose on boot
- A systemd service to download a 'default' Nginx Proxy Manager docker-compose file from this repo
- A reboot strategy for automatic updates

I highly recommend that you leave the swap and update strategy configs in place to support system stability.

[The documentation for writing a Butane file for this version of Flatcar linux can be found here](https://coreos.github.io/butane/config-flatcar-v1_0/)

## Regions

Before deploying the project, you may want to change the region that azure deploys to. Updating the 'REGION' variable in the main script, and running it with the '-r' option will update all configs tied to this project with the input from the variable

```bash
./redeploy.sh -r
```

[A list of Azure regions and name 'codes' can be found in this article](https://azuretracks.com/2021/04/current-azure-region-names-reference/)

## Tags

To change the tags of your newly created resources, you can simply run a Find for the string 'tags' in the JSON files, and change them to your liking.

## Admin Username

Changing the admin username in the flatcar.parameters.json file should create a new user on the machine, and bind the ssh-key you added to said user. Changing this should be as simple as replacing 'core' with your chosen value. 

Note that the default user 'core' will have ownership of the docker-compose binary unless changed in the Ignition file. 

Permissions could also get quite messy, should you change this

## Adding an rsync service for configuration files

Append the following YAML code to your Butane.yml file, and update the 'ExecStart=...' line with your rsync command: (Improvements in progress for this)

```yaml
    - name: rsync-npm-db.service
      enabled: true
      contents: |
        [Unit]
        Description=Pull NPM DB and compose file(s) from external server

        [Service]
        Type=oneshot
        ExecStart=/usr/bin/rsync --COMMAND GOES HERE--
```
Then run the main script with the '-i' option to regenerate the Ignition file and convert it for use.

```bash
./redeploy.sh -i
```

## If you *aren't* using any existing configuration or database files...
A default configuration should have been placed in the home directory of the core user (provided you didnt remove the service from the ignition file). I would not recommend running this file 'as-is' for longer than a day.

[A guide to editing this file can be found on the NPM webpage](https://nginxproxymanager.com/setup/#running-the-app)