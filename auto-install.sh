#manual work
#GCP new instance:
#Name=instance-1
#Zone=us-central1-a, ubuntu 16.04, all other defualt
#Boot disk image=Ubuntu 16.04 LTS
#Access scopes=Allow full access to all Cloud APIs

#need a seperate delete instance script:
#delete static IP
#delete bucket "general storage"
#delect bucket "R storage"
#delete firewall rules "rstudio" and "vnc-server"
#if possible, delete VM
#write all variables to a bucket "uninstall" for later scripting

#after vm running, click "connect SSH"
#install gcloud
# Create an environment variable for the correct distribution
export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"

# Add the Cloud SDK distribution URI as a package source
echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

# Import the Google Cloud Platform public key
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

# Update the package list and install the Cloud SDK
sudo apt-get update && sudo apt-get install google-cloud-sdk

#initialize
#account
# xxxxx-compute@developer.gserviceaccount.com
#project
#hadoop-000
#zone
#us-central1-a

gcloud init

#need a pass
PASSWRD="chris123"
#all other parameters populated by exiting data
USER=$(echo `whoami`)
RAND_NUM=$RANDOM
STATIC_NAME="external-static-$RAND_NUM"
INSTANCE_NAME=$(gcloud compute instances list --format="value(name)")
REGION=$(gcloud config list --format="flattened(compute.region)" | cut -d':' -f2 | tr -d [:space:])
ZONE=$(gcloud config list --format="flattened(compute.zone)" | cut -d':' -f2 | tr -d [:space:])

echo user: $USER
echo rand: $RAND_NUM
echo static: $STATIC_NAME
echo instance: $INSTANCE_NAME
echo region: $REGION
echo zone: $ZONE


#create user password - GCE don't have pswd by default
echo "$USER:$PASSWRD" | sudo chpasswd

cd $HOME

mkdir -p $HOME/run

#if ! [GREP $HOME/run .bashrc]:
echo 'export PATH=$PATH:$HOME/run' >> ~/.bashrc

source ~/.bashrc

#Promote ephemeral external IP to staticinstance
EPHERMERAL=$(gcloud compute instances describe $INSTANCE_NAME --zone us-central1-a --format="flattened(networkInterfaces[0].accessConfigs[0].natIP)" | cut -d':' -f2 | tr -d [:space:])
echo $EPHERMERAL

gcloud compute addresses create $STATIC_NAME \
    --addresses $EPHERMERAL --region $REGION


#install GSC fuse
export GCSFUSE_REPO=gcsfuse-`lsb_release -c -s`
echo "deb http://packages.cloud.google.com/apt $GCSFUSE_REPO main" | sudo tee /etc/apt/sources.list.d/gcsfuse.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

sudo apt-get update
sudo apt-get install gcsfuse


#create buckets
gsutil mb -c regional -l us-central1 gs://gen-storage$RAND_NUM/
gsutil mb -c regional -l us-central1 gs://r-storage$RAND_NUM/

#alter /mnt permissions so can create folders
sudo chmod -R 777 /mnt/

#make all transfer folders
mkdir /mnt/gcs-bucket /mnt/gcs-bucket-R gcs-put gcs-put-R gcs-working

#make symbolic links to access data from buckets
PRESDIR=$(eval echo "~")
ln -s /mnt/gcs-bucket $HOME/gcs-bucket
ln -s /mnt/gcs-bucket-R $HOME/gcs-bucket-R



#cron runs in subshell so it won't print test cases like echo "hello"
(crontab -l 2>/dev/null; echo "@reboot gcsfuse gen-storage$RAND_NUM /mnt/gcs-bucket") | crontab -
(crontab -l 2>/dev/null; echo "@reboot gcsfuse r-storage$RAND_NUM /mnt/gcs-bucket-R") | crontab -
(crontab -l 2>/dev/null; echo "*/5 * * * * gsutil mv $HOME/gcs-put/* gs://gen-storage$RAND_NUM") | crontab -
(crontab -l 2>/dev/null; echo "*/5 * * * * gsutil mv $HOME/gcs-put-R/* gs://r-storage$RAND_NUM") | crontab -
(crontab -l 2>/dev/null; echo "") | crontab -


#set firewall rules
#rstudio
gcloud compute firewall-rules create rstudio --allow tcp:8787

#vnc server
gcloud compute firewall-rules create vnc-server --allow tcp:5901



#install GUI
#full gnome desktop (Open Office, Internet, email, etc)
sudo apt-get update && sudo apt-get upgrade
sudo apt-get --yes install ubuntu-desktop gnome-panel gnome-settings-daemon metacity nautilus gnome-terminal

#install vnc server
sudo apt-get --yes install tightvncserver
#add vncserver password from bash:
#https://stackoverflow.com/questions/30606655/set-up-tightvnc-programmatically-with-bash



# Configure VNC password
# use safe default permissions
umask 0077

# create config directory
mkdir -p "$HOME/.vnc"

# enforce safe permissions
chmod go-rwx "$HOME/.vnc"

# generate and write a password
#use same password as used for GCE, rstudio
vncpasswd -f <<<"$PASSWRD" >"$HOME/.vnc/passwd"


#start server for immediate use
vncserver

vncserver -kill :1


#create startup file
cat >$HOME/.vnc/xstartup <<EOL
#!/bin/sh

#xrdb $HOME/.Xresources
[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup
[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources

xsetroot -solid grey
#vncconfig -iconic &
#vncconfig -geometry 1366x768 &
#x-terminal-emulator -geometry 80x24+10+10 -ls -title "$VNCDESKTOP Desktop" &
#x-window-manager &
# Fix to make GNOME work
export XKL_XMODMAP_DISABLE=1
/etc/X11/Xsession

gnome-panel &
gnome-settings-daemon &
metacity &
nautilus &
EOL

#create vnc startup entry in /etc/rc.local file
sudo sed -i -e '$i \su - currentuser -c "/usr/bin/vncserver :1" &\n' /etc/rc.local
sudo sed -i "s/currentuser/$USER/g" /etc/rc.local

#install Rstudio