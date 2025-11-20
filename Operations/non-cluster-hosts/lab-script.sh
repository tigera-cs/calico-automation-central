#!/bin/bash

typeset -i OPTION
OPTION=0
KU="/usr/local/bin/kubectl"
BSCRIPTS="/home/tigera/Calico-Non-Cluster-Nodes-Workshop/tstasks/.scripts/.blab"
FSCRIPTS="/home/tigera/Calico-Non-Cluster-Nodes-Workshop/tstasks/.scripts/.flab"


clear
while [ $OPTION -ne 99 ]
do

  echo ""	
  echo " ---------------------------- Break Scripts"
  echo ""
  echo "################################################################################"
  echo "#                                                                              #"
  echo "# 1 - LAB Break communication between non-Kubernetes nodes                     #"
  echo "#                                                                              #"
  echo "# 2 - LAB Break communication between non-Kuberentes node and POD              #"
  echo "#                                                                              #"
  echo "# 3 - LAB Break non-Kubernetes node 1                                          #"
  echo "#                                                                              #"
  echo "################################################################################"
  echo ""
  echo " ---------------------------- Fix Scripts"
  echo ""
  echo "################################################################################"
  echo "#                                                                              #"
  echo "# 21 - LAB Fix communication between non-Kubernetes nodes                      #"
  echo "#                                                                              #"
  echo "# 22 - LAB Fix communication between non-Kuberentes node and POD               #"
  echo "#                                                                              #"
  echo "# 23 - LAB Break non-Kubernetes node 1                                         #"
  echo "#                                                                              #"
  echo "################################################################################"
  echo ""
  echo "99 - Exit"
  echo ""
  read  -p "Enter the option: " OPTION

  case $OPTION in
	1|2|3)
                $KU replace -f $BSCRIPTS$OPTION".yaml" > /dev/null
                echo ""
                read -p "------------- Press any key to continue"
                clear
                ;; 
	21|22|23)
                $KU replace -f $FSCRIPTS$OPTION".yaml" > /dev/null
                echo ""
                read -p "------------- Press any key to continue"
                clear
                ;;
	99)
                clear
                ;;
	*)
		echo ""
		echo "!!!!!! Invalid Option !!!!!!!"
		sleep 1
		clear
		;;
  esac
done