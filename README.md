# Initialize a new GCE machine for data science use
This script automates installation and set-up of a GCE VM, installs a GUI desktop and Rstudio server. The script is designed to be compatible with users on remote ChromeOS systems, so inital authentication involves a guided interactive auth login step. All other GCE, desktop and Rstudio setup is automated.

Google Cloud Platform is a very flexible computing platform. However, automated start-up of Google Compute Engine instances, and set up of related services (i.e. Google Storage or BigQuery) can be time consuming. These tasks can also be difficult for beginners to learn easily. This script aims to simplify set-up of GCE VMs related services. It creates necessary firewall rules, installs Rstudio, and creates a buckets for general storage and R based data science projects. Additionally, as learning to use commands in a bash terminal can have a steep learning curve, it also installs one of several GUI desktops (i.e. a light xfce or a heavier gnome version) to interact with the VM remotely.

Several processes in this script can either be automated further (such as Oauth authentication) or made more secure (such as SOCK proxy instead of using public facing firewall rule). However, if you know what these features are, you can adapt this script accordingly, or you don't need this script.

# GCE Set-Up and Running Initialization Script
Start up a GCE VM as described on GCP instructions. Choose the following options, leave everything else default. Other options might be compatible with the script, but have not been validated. Complete the following:
* Instance Name: your choice
* Zone: your choice
* Boot disk image=Ubuntu 16.04 LTS
* Access scopes=Allow full access to all Cloud APIs

After VM is running, click "connect SSH" button. In the window that pops up type:

git clone https://github.com/ctrhodes/gce-initialize.git

mkdir -p $HOME/run

mv gce-initialize/initialize_gce.sh $HOME/run

echo 'export PATH=$PATH:$HOME/run' >> ~/.bashrc

source ~/.bashrc

chmod 755 $HOME/run/initialize_gce.sh

initialize_gce.sh

Optionally, before running **initialize_gce.sh**, edit the script and change the password to a password of your choice:  
nano ~/run/initialize_gce.sh

This script was designed ot be compatable with ChromeOS which has limited SSH capabilities. As such, the easiest way to initialize Oauth with **gcloud init** is to use interactive set-up. When running **gcloud init**, choose something similar to the examples below:

* account: xxxxx-compute@developer.gserviceaccount.com
* project: my-project
* configure GCE settings: y
* zone: us-central1-a

# Usage
initialize_gce.sh \[OPTION\]

Default useage (i.e. no options) will install a light-weight XFCE GUI desktop

**Options**

-b, --base  
basic Gnome desktop (just file browser)

-f, --full  
full Gnome desktop (includes Firefox browser, OpenOffice, etc)

# File transfer between GCE and Google Storage
Based on the way the folders sync between the new GCE and Google Storage, it is best practice to move the files in a particular sequence. When your Google Storage bucket is accessible, either by terminal or GUI, move desired desired files from bucket to "gcs-working" folder in user's home directory. Edit file there (i.e. use in R, etc). After file is saved, move to "gcs-put" folder, where the file is staged for transfer back to Google Storage. The syncs occur every 5 min. While there are more direct ways to access files in buckets, this method works easily from terminal or GUI interfaces, as long as the proper order is followed: gcs-bucket(fused to GS Bucket) > gcs-working > gcs-put(syncs to GS Bucket).

# If needed, view desktop with VNC viewer
If using Windows or ChromeOS, install VNCviewer client. If using Linux, Remmina Remote Desktop Client. Find external IP listed under active VM.
* Choose VNC as connection type
* Enter External-IP:5901
* Enter password used in initialize_gce.sh script

# Start Rstudio
* Open new browser tab
* Enter External-IP:8787
* Enter google username and password used in initialize_gce.sh script

# Clean-up GCP components and delete VM
The initialization start-up script installs a clean-up script to assist shutting down the running VM. The cleanup script releases the assigned static external IP, deletes the rstudio and vnc firewall rules, and removes the 2 buckets installed for general storage and R related files. This script prevents accumulation of excess GS Buckets and prevents network rule conflicts.
* Download or transfer any important files from your Google Storage Buckets prior to running the clean-up script. The clean-up script will delete the 2 buckets linked to your VM, as well as any files contained within the buckets
* Run **cleanup_gce.sh** which is installed in the ~/run folder and has already been added to the VM's PATH.
* After script completes, delete your VM in Google Cloud Console.
