# gce-initialize
This script automates installation and set-up of a GCE VM, installs a GUI desktop and Rstudio server. The script is designed to be compatible with users on remote ChromeOS systems, so inital authentication involves a guided interactive auth login step. All other GCE, desktop and Rstudio setup is automated.

Google Cloud Platform is a very flexible computing platform. However, automating start-up of a Google Compute Engine instance, set up credentials and make various services (i.e. Google Storage or BigQuery) coordinate properly can be time consuming. These tasks can also have a steep learning curve and be difficult for beginners to learn. This script aims to simplify instanstiation of GCE VMs and set-up of related services. It creates necessary firewall rules, installs Rstudio, and creates a buckets for general storage and R based data science projects. Additionally, as learning to use commands in a bash terminal can have a steep learning curve, it also installs one of several GUI desktops (i.e. a light xfce or a heavier gnome version) to interact with the VM remotely.

# GCE set-up and Running Initialization Script

