#!/bin/bash
shopt -s nocasematch; #shell option -s allows for case insensitivty throughout the script
#######################################################
#sFTP Chroots with bind mount script v1.3
#Author: Luke Shirnia
#Website: lukeslinuxlessons.co.uk
#Copyright
#######################################################
 
 
#run script with:
#bash <(curl -s https://raw.githubusercontent.com/luke7858/sFTP-Chroot-with-BIND-Mounts/master/sFTPchroot.sh)
 
 
####################################################################################
#Release v1.3 Update notes:
#Script tested abd works with:
#Ubuntu 14.04LTS, 12.04LTS
#CentOS 6, 6.5/6.6
#redhat 6, 6.5
####################################################################################
####################################################################################
#Release v1.2 Update notes:
#New features:
#-Script now has the ability to show all non-system users
#-Comments have started to be added to the code
 
#Other changes:
#-Code has been cleaned up
#-Script now only mounts the specified location rather than the whole of /etc/fstab
####################################################################################
 
globalg1="/home/chroot/"
clear
printf "\n----------------------------------------------"
printf "\nsFTP chroot (with mounts)\nBy LukesLinuxLessons"
printf "\n----------------------------------------------\n\n"
 
###################################################################################
############################sftp group section ####################################
###################################################################################
checkifnewgroupexists() { #Check New Group exists or if it doesnt
if [ ! "$newsftp" = "" ] && ( ! getent group "$newsftp" ); then #checks to make sure newsftp is not equal to nothing and the group does not exist already
read -p "Are you sure you want to create the group $newsftp? (y/N) " newsftpyn
  case $newsftpyn in
  y|ye|yes)
   if ( ! getent group "$newsftp" ) && [ ! "$newsftp" = "" ]; then
     groupadd "$newsftp"
     printf " ----------------------------------------------\n"
     grep "^$newsftp:" /etc/group
     globalgroup=$newsftp
     printf "Group has been added!"
     printf "\n----------------------------------------------\n"
   fi
  ;;
  n|no )
     printf "Please try again\n"
     read -p "What would you like the group to be called? " newsftp
  ;;
  *)
     printf "Please enter a valid Option"
     printf "\n----------------------------------------------\n"
  ;;
  esac
 else
printf "Please enter a group name that doesn't exist"
printf "\n----------------------------------------------\n"
read -p "What would you like the group to be called? " newsftp
fi
}
checkexistinggroup() { #Check Existing Group Exists---------------------------
cegeno1=$( grep -c "$esftpgroup:" /etc/group ) #greps for the exact username from /etc/passwd. Returns values
cegeno2=$( grep -ci "$esftpgroup" /etc/group ) #greps for case insensive username from /etc/password and similar group names. Returns values
    if [ "$esftpgroup" = "" ]; then
     printf "Please do not leave the group field empty\n"
     printf "\n----------------------------------------------\n"
     cegeno1="0" #reset the value to 0 so that the loop continues
    elif [ "$cegeno1" -ge 1 ]; then
     globalgroup=$esftpgroup
     getent group "$esftpgroup"
     printf "Exists!"
     printf "\n----------------------------------------------\n"
    elif [ "$cegeno2" -ge 1 ]; then
     printf "That doesn't exist however the following similar group does: \n\n"
     grep -i "$esftpgroup" /etc/group
     printf " ----------------------------------------------\n"
    else
     printf "That does not exist, please try again\n"
     printf " ----------------------------------------------\n"
    fi
}
#--------------------sFTP Groups---------------------------------------------
while [[ ! ("$newsftpyn" =~ (y|ye|yes)$ ) ]]; do
read -p "Would you like to create a NEW sFTP group? <y/N> " ngyn
  case $ngyn in
  y|ye|yes )
    read -p "What would you like the group to be called? " newsftp
       while [[ ! ("$newsftpyn" =~ (y|ye|yes)$ ) ]]; do #while the new sftp group has not been confirmed (yes) keep looping
    checkifnewgroupexists
       done
  ;;
  n|N|no )
   cegeno1="0" #assins a value to the vaiable until the loop starts
   while [ "$cegeno1" -lt 1 ]; do
    read -p "Please enter a groupname that already exists: " esftpgroup
    checkexistinggroup
   done
   break #use this to get out of the main loop
  ;;
  *)
    printf "Please enter a valid option"
    printf "\n----------------------------------------------\n"
  ;;
  esac
done
###################################################################################
#############Would you like a create a new user for sftp?##########################
###################################################################################
newuseryestest() {
if [ ! "$username" = "" ] && ( ! getent passwd "^$username:" ); then
 read -p "Are you sure you wish to add the user $username ? (y/N)" nuyn  #nuyn = new user yes no
 case $nuyn in
 y|ye|yes )
   useradd "$username"
   globaluser=$username
   egrep "^$username:" /etc/passwd
   printf "\n----------------------------------------------\n"
 ;;
 n|no )
   printf "Please try again"
   printf "\n----------------------------------------------\n"
   read -p "What username would you like for the new user? " username
 ;;
 *)
   printf "Please enter a valid option\n"
 ;;
 esac
 
else
  printf "\nPlease enter a valid option"
  printf "\n----------------------------------------------\n"
  read -p "What username would you like for the new user? " username
fi
}
useexistinguser() {
value=$( grep -ic "^$currentuser" /etc/passwd )
valuecatch=$( grep -c "^$currentuser:" /etc/passwd )
if [ "$currentuser" = "" ]; then
   printf "Please enter a username\n"
elif [ ! "$currentuser" = "" ] && [ "$value" -ge 1 ] && [ "$valuecatch" -ge 1 ]; then
  printf "Thank you, you will be chrooting: $currentuser"
  globaluser=$currentuser
  printf "\n----------------------------------------------\n"
elif [ "$value" -ge 1 ]; then
  printf "\n----------------------------------------------\n"
  printf "You did not enter an existing user, please try again\n"
  printf "Available users with similar name are: \n\n"
  egrep -i "^$currentuser" /etc/passwd
  printf "\n----------------------------------------------\n"
fi
}
listusers() { #this function is used to list all of the current non-system users
l=$(grep "^UID_MIN" /etc/login.defs) # get mini UID limit from /etc/login.defs
l1=$(grep "^UID_MAX" /etc/login.defs) # get max UID limit from /etc/login.defs
awk -F':' -v "min=${l##UID_MIN}" -v "max=${l1##UID_MAX}" '{ if ( $3 >= min && $3 <= max ) print $0}' /etc/passwd # use awk to print if UID >= $MIN and UID <= $MAX
}
#--------------------------------sF./TP user-------------------------------------
valuecatch="0" #valuecatch receives a proper value in the function "useexistinguser", assigning 0 here allows the loop to start before it received a valid value in the function
while [[ ! ( "$nuyn" =~ (y|ye|yes)$ ) ]]; do
 
read -p "Would you like to create a NEW sftp user? (l to list current users) (y/N/l): " newsftpuser #newsftpuser = new sftp user
case $newsftpuser in
y|ye|yes )
    read -p "What username would you like for the new user? " username
    while [[ !( "$nuyn" =~ (y|ye|yes)$ ) ]]; do #while nuyn (new user yes no) is not equal to yes, then keep looping ??&& usernameval??
      newuseryestest
    done
;;
n|no )
   while [ "$valuecatch" -lt 1 ]; do #while valuecatch  (valuecatch=$( grep -c "^$currentuser:" /etc/passwd )) is not equal to a valid user, keep looping
     read -p "What is the current user you wish to chroot? " currentuser
     useexistinguser
   done
   break #this breaks out of the main while loop as the condition !( "$nuyn" =~ (y|ye|yes)$ will not be met however the loop is complete
;;
l|list) #calls a function to list all of the current non-system users
     printf "\nCurrent users are:\n"
     listusers
     printf " ----------------------------------------------\n"
;;
*)
    printf " -------Please enter a valid option!-------\n"
    printf "        ----Try again---- \n"
;;
esac
done
###################################################################################
###########################"Edit" User [Functions]###################################
###################################################################################
editchrootyes() {
    mkdir -p $globalg1$globaluser
    usermod -d $globalg1$globaluser -s /sbin/nologin -G $globalgroup $globaluser
    printf "\n"
    egrep "^$globaluser:" /etc/passwd
    eus=$(egrep -i "^$globaluser" /etc/passwd)
}
editchrootno() {
    printf "\nPlease remember to set up the correct user configuration after the script has run \n"
    usermod -G $globalgroup $globaluser
    eus="Please remember to edit the home directory and group of $globaluser"
}
editcustomchroot() {
if [ ! "$ccd" = "" ] && [ -d "$ccd" ]; then
  read -p "Are you sure you want to chroot the user $globaluser to $ccd (y/N) " ccyn
 case $ccyn in
 y|ye|yes )
    mkdir -p $ccd$globaluser
    usermod -d "$ccd" -G $globalgroup $globaluser
    printf "\n"
    grep "$globaluser:" /etc/passwd
    printf " ----------------------------------------------\n"
    eus=$(egrep -i "^$globaluser" /etc/passwd)
    globalg1=$ccd
  while [[ ! ( $sbinyn =~ (y|ye|yes|n|no)$ ) ]]; do
    editcustomchrootshell
  done
 ;;
 n|no )
    printf "Please try again\n"
    printf "\n----------------------------------------------\n"
    printf "What location would you like to chroot the user $globaluser to? \n"
    read -p "Please finish the directory location with a / eg. /home/: " ccd
 
 ;;
 *)
    printf "Please enter a valid option\n"
    printf "\n----------------------------------------------\n"
 ;;
 esac
else
  printf "\nPlease enter a valid directory \n"
  printf "\n----------------------------------------------\n"
  printf "What location would you like to chroot the user $globaluser to? \n"
  read -p "Please finish the directory location with a / eg. /home/: " ccd
 
fi
}
editcustomchrootshell() {
    read -p "Would you like to change the user to /sbin/nologin? Yes/No/Custom (y/N) " sbinyn
case $sbinyn in
y|ye|yes)
    usermod -s /sbin/nologin $globaluser
;;
n|no)
    printf "\nThe sFTP user created will still be able to ssh into the system\n"
;;
 
*)
   printf "\nPlease can you enter a valid input\n"
   printf "\n----------------------------------------------\n"
;;
esac
}
#------------------------------Edit User ---------------------------------
while [[ ! ( "$chrootyn" =~ (y|ye|yes)$ ) ]]; do
  printf "Chroot the user $globaluser to a home directory of $globalg1$globaluser\n"
  printf "and a shell of /sbin/nologin? "
  read -p "Yes, No, Custom Directory (y/N/c): " chrootyn
  case $chrootyn in
    y|ye|yes)
    editchrootyes
    printf " ----------------------------------------------\n"
    break #comment out once main loop is changed?
  ;;
  n|no )
    editchrootno
    break
  ;;
  c|custom)
    printf ""
    printf "What location would you like to chroot the user $globaluser to? \n"
    read -p "Please finish the directory location with a / eg. /home/: " ccd
 while [[ ! ("$ccyn" =~ (y|ye|yes)$ ) ]]; do
    editcustomchroot
 done
    break
  ;;
  *)
    printf "Please enter a valid option\n"
    printf " ----------------------------------------------\n"
    ;;
  esac
done
##################################################################################
#########################directory permissions [Functions]#########################
###################################################################################
setdirectorypermissions() {
printf "Users home directory: $globalg1$globaluser \n"
globalg2="$globalg1$globaluser/"
read -p "Would you like to automatically set permissions or manually set permissions? (a/M): " permissionsam
   case $permissionsam in
   a|auto|automatic )
    chmod 711 $globalg1
    chmod 755 $globalg2
    chown root:root $globalg2
    printf "\nThe following permissions have been set:"
    printf "\nchmod 711 $globalg1"
    printf "\nchmod 755 $globalg2\nchroot root:root $globalg2"
    printf "\n----------------------------------------------\n"
   ;;
   m|man|manually )
    printf "Please remember to change the permissions after the script has run"
    printf "\n----------------------------------------------\n"
    break
    ;;
   * )
    printf "Please enter a valid input (a/m)"
    printf "\n----------------------------------------------\n"
   ;;
   esac
}
#-----------------------directory permissions---------------------------------
# The following section is for setting the permissions on the directories
shopt -s nocasematch; #this command configures the shell option -s (set enable) no-case-match which allows for case insensitivity.
while [[ ! ( $permissionsam =~ (a|auto|automatic)$ ) ]]; do
 setdirectorypermissions
done
###################################################################################
########################Setting Mount Binds [functions]############################
###################################################################################
confirmmountsyesno() {
printf "What directory would you like to mount e.g. /var/www/vhost/website1 ? \n"
read -p "Please enter the directory starting and ending with / e.g. /var/www/ " mountdirectory
     mdirectory=$mountdirectory
if [ -d "$mdirectory" ] && [ ! "$mdirectory" = "" ]; then
          printf "$mdirectory"" Exists!! :)"
          printf "\n---------------------------------------------\n"
 
while [[ ! ( "$myn" =~ (y|ye|yes)$ ) ]]; do
         read -p "Are you sure you would like to mount the directory $mdirectory? (y/N): " myn #mount yes no
         case $myn in
         y|ye|yes )
           printf "Thank You"
           printf "\n---------------------------------------------"
      while [[ ! ( "$wmdyn" =~ (y|ye|yes)$ ) ]]; do  #while
       mountdirectoryyesno #function
      done
         ;;
         n|no )
           printf "Please try again!\n\n"
          break
         ;;
         *)
           printf "\nPlease enter yes or no (y/n) \n"
         ;;
         esac
done
 
else
printf "$mdirectory Does not exist, please try again!"
printf "\n---------------------------------------------\n"
  fi
}
mountdirectoryyesno() {
printf "\nWhat directory would you like to CREATE for this mount?\n"
printf "Please enter this location WITHOUT / before or after \n"
read -p "Examples: $globalg2 website1 or domain1.co.uk: " wmd #wd = what mount directory
 
while [[ ! ( "$wmdyn" =~ (y|ye|yes)$ ) ]]; do
 
if [ ! "$wmd" = "" ]; then
read -p "Are you sure you would like to mount to the following location $globalg2$wmd (y/N)? " wmdyn #wdyn = what mount directory yes no
case $wmdyn in
        y|ye|yes )
          printf "\nThank You!"
          printf "\n---------------------------------------------"
          printf "\n\nMaking directory "$globalg2$wmd"....\n"
          mkdir -p $globalg2$wmd
          echo "$mdirectory " "$globalg2$wmd " "none bind 0 0" >> /etc/fstab
          printf "Configuring fstab....\n"
          mount $globalg2$wmd #this command mounts the location that has been confirmed and then written to /etc/fstab
          chown $globaluser:$globalgroup $globalg2$wmd #changing ownsership of the mounted directory to allow the chrooted user to edit the files
          printf "Setting permissions on the directory....\n"
          printf "Mounting the directory....\n"
          printf "Setting correct permissions on the mount....\n"
        ;;
        n|no )
          printf "\nPlease try again!\n"
          break
        ;;
        *)
          printf "\nPlease enter yes or no (y/n) \n"
          printf "\n---------------------------------------------\n"
        ;;
        esac
else
          printf "Please enter a directory you wish to create for this mount"
          printf "\n---------------------------------------------\n"
fi
done
}
#--------------------------Setting Mount Binds---------------------------------
printf "\nSetting bind mounts\n"
printf "\n---------------------------------------------\n"
while [[ !( "$wmdyn" =~ (y|ye|yes)$ ) ]]; do #while the mount directory is not confirmed (yes) keep looping
read -p "Would you like to set bind mount? (y/N) " mountyn
case $mountyn in
y|ye|yes )
      while [[ !( "$myn" =~ (y|ye|yes)$ ) ]]; do #while mount directory (eg /var/) is not equal to yes then keep looping the function
       confirmmountsyesno #function
      done
      ;;
 
n|no )
      break #breaks the while loop as the following will not be met: !( "$wdyn" =~ (y|ye|yes)$ )
;;
*)
      printf "\nPlease enter yes or no \n"
      printf "\n---------------------------------------------\n"
;;
esac
done
printf "\n---------------------------------------------\n"
###################################################################################
################################ Summary Sections##################################
###################################################################################
  printf "\n\n\n-----------------------------------------------------------------"
  printf "\n-------------------------Summary Section-------------------------"
  printf "\n-----------------------------------------------------------------"
  printf "\nThe following group was used: $globalgroup"
  printf "\nThe following user was added to that group: $globaluser "
  printf "\nIf you have created a new user please REMEMBER to change the password for the user"
  printf "\nChroot Directory: $globalg2"
case $permissionsam in
a|auto|automatic )
  printf "\n-----------------------------------------------------------------"
  printf "\n\nThe following permissions have been set:"
  printf "\nchmod 711 $globalg1"
  printf "\nchmod 755 / chroot root:root $globalg2"
;;
*)
  printf "\n------------Permissions------------"
  printf "\nYou chose to manually set permissions, please remember to do this now."
;;
esac
  case $mountyn in
a|auto|automatic )
  printf "\n\n------------bind mounts------------"
  printf "\nYou configured:\n $mdirectory to mount to the location: $globalg2$wmd\n"
;;
*)
  printf "\n----You chose NOT to set up bind mounts----\n"
;;
esac
  printf "\n-----------------------------------------------------------------"
  printf "\n--Please remember to manually configure /etc/ssh/sshd_config file--\n"
  printf "Visit the following domain for an example configuration guide for sFTP"
  printf "\nhttp://lukeslinuxlessons.co.uk/sftp-chroot/#sshconfig\n"
  printf "\n-----------------------------------------------------------------\n"
###################################################################################
