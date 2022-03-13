#!/bin/bash

if [[ $(id -u) -ne 0 ]]
then
	echo "Please run as root"
	exit 1
fi

# Install packages
apt-get -y install postgresql postgresql-client python3-psycopg2

# Configure database login
USER=$(logname)
HOME="/home/$USER"
password=$1
if [[ "password" != "" ]]
then
	user_exists=$(sudo -u postgres psql postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='workouts'")
	if [[ "$user_exists" != "1" ]]
	then
		sudo -u postgres createuser -U postgres workouts
		sudo -u postgres psql -tAc "ALTER USER workouts WITH ENCRYPTED PASSWORD '$password'"
	else
		echo "User already exists, skipping"
	fi
	if [[ ! -e "$HOME/.workout.ini" ]]
	then
		cp workout.ini "$HOME/.workout.ini"
		echo "password=$password" >> "$HOME/.workout.ini"
		chown "$USER:$USER" "$HOME/.workout.ini"
	else
		echo "$HOME/.workout.ini already exists, skipping"
	fi
else
	echo "No password specified, skipping creation of postgres login."
fi
sudo -u postgres psql < sql/permissions.sql

# Check authentication method
pg_hba_conf=$(ls /etc/postgresql/*/main/pg_hba.conf)
if local_all_all=$(cat "$pg_hba_conf" | grep "local\s*all\s*all\s*peer")
then
	echo
	echo "ERROR: All local connections are configured to use peer authentication."
	echo "       To fix, edit $pg_hba_conf and replace the line:"
	echo "           $local_all_all"
	echo "       with"
	echo "           $local_all_all" | sed s/peer/md5/
	exit 1
fi
