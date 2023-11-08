#create system user
useradd -r -d /var/spool/ansible -m -s /bin/bash ansible
mkdir -p ~ansible/bin
chown ansible:ansible ~ansible/bin
# copy script
cp zfsBackup.sh ~/ansible/bin
chown ansible:ansible ~/ansible/bin/zfsBackup.sh
#copy crontab definition
cp zfsBackup /etc/crontab.d/