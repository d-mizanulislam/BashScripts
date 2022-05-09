##############################################################################################
## Script Name :- RunRMAN.sh                                                                ##
## Purpose     :- Backup script for Laltier using RMAN                                      ##
## Created by  :- Mizanul                                                                   ##
## Created on  :- 27/08/2020                                                                ##
##############################################################################################

echo "Starting the backup process at: "`date`

BACKUPDIR=/u03/backups/backup_files
BACKUPLOGDIR=/u03/backups/backup_logs
LOG=RMAN_`date +%F`.log
NLS_DATE_FORMAT='dd/mm/yyyy hh24:mi:ss'
ORACLE_BASE=/u01/app/oracle
ORACLE_HOME=/u01/app/oracle/product/12.2.0/dbhome_1
ORACLE_SID=prodcdb
PATH=$ORACLE_HOME/bin:$PATH

export BACKUPDIR BACKUPLOGDIR LOG NLS_DATE_FORMAT ORACLE_BASE ORACLE_HOME ORACLE_SID PATH

echo "Backup directory :"$BACKUPDIR
echo "Backup log name :"$BACKUPLOGDIR/$LOG

rman target sys/manager@prodcdb msglog=$BACKUPLOGDIR/$LOG <<EOF
        CROSSCHECK BACKUPSET;
        CROSSCHECK ARCHIVELOG ALL;
        DELETE NOPROMPT OBSOLETE RECOVERY WINDOW OF 2 DAYS;
        BACKUP SPFILE;
        BACKUP AS COMPRESSED BACKUPSET DATABASE PLUS ARCHIVELOG;
EOF

echo "Backup process ended at: "`date`
