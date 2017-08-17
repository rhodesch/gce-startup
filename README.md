# Start up a new GCE virtual machine, install GUI desktop, Rstudio and set-up Google Storage Bucket for data science use
This script automates set-up of a Google Cloud Platform Compute Engine (GCE) VM, installs a GUI desktop and Rstudio server, links GUI desktop and RStudio to Google storage buckets for easy access. . The script is designed to be compatible with users on remote ChromeOS systems, so inital authentication involves a guided interactive auth login step. All other GCE, Google Storage, firewall rules, desktop and Rstudio setup steps are automated.

Google Cloud Platform is a very flexible computing platform. However, automated start-up of Google Compute Engine instances, and set up of related services (i.e. Google Storage or BigQuery) can be time consuming. These tasks can also be difficult for beginners to learn easily. This script aims to simplify set-up of GCE VMs related services. It creates necessary firewall rules, installs Rstudio, and creates a buckets for general storage and R based data science projects. Additionally, as learning to use commands in a bash terminal can have a steep learning curve, it also installs one of several GUI desktops (i.e. a light xfce or a heavier gnome version) to interact with the VM remotely.

Several processes in this script can either be automated further (such as Oauth authentication) or made more secure (such as SOCKS proxy instead of using public facing firewall rule). However, if you know what these features are, you can adapt this script accordingly, or you probably don't need this script at all.

# GCE Set-Up and Running Startup Script
If you have any trouble getting this script, accessing the GUI desktop by vncserver, or Rstudio server: either stop all VMs in your current project, or better yet, create a new project. Creating a new project will reset any networking rules to defaults and ensures you have the standard compute engine service account used to authorize the gcloud program. If you decide to create a new project, use Google Cloud Console to create the new project as outlined [here](https://cloud.google.com/resource-manager/docs/creating-managing-projects).

Start up a GCE VM as described [here](https://cloud.google.com/compute/docs/quickstart-linux). Choose the following options, leave everything else default. Other options might be compatible with the script, but have not been validated. Complete the following:
* Instance Name: your choice
* Zone: your choice
* Boot disk image=Ubuntu 16.04 LTS
* Access scopes=Allow full access to all Cloud APIs

After VM is running, click "connect SSH" button. In the window that pops up copy and paste the following 7 commands:

git clone https://github.com/ctrhodes/gce-startup.git

mkdir -p $HOME/run

mv gce-startup/initialize_gce.sh $HOME/run

echo 'export PATH=$PATH:$HOME/run' >> ~/.bashrc

source ~/.bashrc

chmod 755 $HOME/run/initialize_gce.sh

initialize_gce.sh

Optional: Before running **initialize_gce.sh**, edit the script and change the password to a password of your choice:  
nano ~/run/initialize_gce.sh  
On line 5, find: PASSWRD="chris123", change the string within the quotes to your preferred password

Optionally: By default the script installs a light GUI called XFCE. If you feel more comfortable using the classic Ubuntu interface for your GUI desktop try running **initialize_gce.sh -f** or **initialize_gce.sh -b**, which installs different flavors of the Ubuntu desktop. See Usage section below for more details.

This script was designed ot be compatable with ChromeOS which has limited SSH capabilities. As such, the easiest way to initialize Oauth with **gcloud init** is to use interactive set-up. When running **gcloud init**, choose something similar to the examples below:

Examples of input needed during **gloud init** which is the first part of the **initialize_gce.sh** and the only part that requires interactive input from the user:  
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
full Gnome desktop (includes Firefox browser, OpenOffice, etc). Allows you to do ALL your work at on a remote virtual machine.

# File transfer between GCE and Google Storage
Based on the way data is stored in Google Storage, it is best practice not to alter the files directly in a GStorage Bucket unless special services have been configured for your VM. The way this startup script causes the files/folders to sync between a new GCE and Google Storage, it is best practice to move the files in a particular sequence when doing your work. When your Google Storage bucket is accessible, either by terminal or GUI, move desired desired files from a bucket to "gcs-working" folder in user's home directory. Edit file there (i.e. use in vm, libre Office, R, etc). After file is saved to the "gcs-working" folder, manually move (don't copy) files/folders to your "gcs-put" folder, where the file is staged for transfer back to Google Storage. The syncs back into your bucket occur every 5 min. While there are more direct ways to access files in buckets (will be added later), this method works easily from terminal or GUI interfaces, as long as the proper order is followed: gcs-bucket(fused to GS Bucket) > gcs-working > gcs-put(syncs to GS Bucket).

# If needed, view desktop with VNC viewer
If using Windows or ChromeOS, install VNCviewer client. If using Linux, Remmina Remote Desktop Client. Find external IP listed under active VM.
* Find your external IP by typing **gcloud compute addresses list --format="value(address)"** into your VM terminal
* Open VNC client
* Choose VNC as connection type
* Enter External-IP:5901
* Enter password used in initialize_gce.sh script

# Start Rstudio
* Find your external IP by typing **gcloud compute addresses list --format="value(address)"** into your VM terminal
* Open new browser tab
* Enter External-IP:8787
* Enter google username and password used in initialize_gce.sh script

# Clean-up GCP components and delete VM
The initialization start-up script installs a clean-up script to assist shutting down the running VM. The cleanup script releases the assigned static external IP, deletes the rstudio and vnc firewall rules, and removes the 2 buckets installed for general storage and R related files. This script prevents accumulation of excess GS Buckets and prevents network rule conflicts.
* Download or transfer any important files from your Google Storage Buckets prior to running the clean-up script. The clean-up script will delete the 2 buckets linked to your VM, as well as any files contained within the buckets
* Run **cleanup_gce.sh** which is installed in the ~/run folder and has already been added to the VM's PATH.
* After script completes, delete your VM in Google Cloud Console.
