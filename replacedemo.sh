#######################################################################################
## Script Name :- Replacedemocdb.sh						     ##	
## Purpose     :- Clone democdb database from PROD Backup for KESW using Company     ##
## Created by  :- Mizanul                                                            ##
## Created on  :- 26/05/2020							     ##
#######################################################################################

echo "Started the duplication process at "`date`

rm -rf /u02/oradata/democdb/demopdb/*.dbf

sqlplus /nolog <<EOF
        conn sys/manager@democdb as sysdba
        shutdown abort;
        startup nomount pfile='/u01/app/oracle/product/12.2.0/dbhome_1/dbs/initdemocdb.ora';
EOF

rman target 'sys/manager@prodcdb' auxiliary 'sys/manager@democdb' <<EOF
run
{
DUPLICATE DATABASE TO 'democdb'
  FROM ACTIVE DATABASE
  USING COMPRESSED BACKUPSET
  SPFILE
     parameter_value_convert ('prodcdb','democdb')
    set db_file_name_convert='/u02/oradata/prodcdb/','/u02/oradata/democdb/'
    set log_file_name_convert='/u02/oradata/prodcdb/','/u02/oradata/democdb/'
    set audit_file_dest='/u01/app/oracle/admin/democdb/adump'
    set core_dump_dest='/u01/app/oracle/admin/democdb/cdump'
    set control_files='/u02/oradata/democdb/control01.ctl','/u02/oradata/democdb/control02.ctl','/u02/oradata/democdb/control03.ctl'
    set db_name='democdb'
  NOFILENAMECHECK;
}
EOF

echo "Ended the duplication process at "`date`

sqlplus /nolog <<EOF
        conn sys/manager@democdb as sysdba
        shutdown immediate;
        startup mount;
        alter database noarchivelog;
        alter database open;
        alter pluggable database PRODPDB close;
        alter pluggable database PRODPDB open restricted;
        alter session set container=PRODPDB;
        alter pluggable database rename global_name to DEMOPDB;
        alter pluggable database close immediate;
        alter pluggable database open;
        alter session set container=CDB$ROOT;
        alter session set container=DEMOPDB;
alter database move datafile '/u02/oradata/democdb/prodpdb/ifsapp_archive_data01.dbf'  to '/u02/oradata/democdb/demopdb/ifsapp_archive_data01.dbf';
alter database move datafile '/u02/oradata/democdb/prodpdb/ifsapp_data01.dbf'  to '/u02/oradata/democdb/demopdb/ifsapp_data01.dbf'; 
alter database move datafile '/u02/oradata/democdb/prodpdb/ifsapp_lob01.dbf'  to '/u02/oradata/democdb/demopdb/ifsapp_lob01.dbf';        
alter database move datafile '/u02/oradata/democdb/prodpdb/ifsapp_report_index01.dbf' to '/u02/oradata/democdb/demopdb/ifsapp_report_index01.dbf'; 
alter database move datafile '/u02/oradata/democdb/prodpdb/system01.dbf'  to '/u02/oradata/democdb/demopdb/system01.dbf';
alter database move datafile '/u02/oradata/democdb/prodpdb/undotbs01.dbf' to '/u02/oradata/democdb/demopdb/undotbs01.dbf';
alter database move datafile '/u02/oradata/democdb/prodpdb/ifsapp_archive_index01.dbf'  to '/u02/oradata/democdb/demopdb/ifsapp_archive_index01.dbf';
alter database move datafile '/u02/oradata/democdb/prodpdb/ifsapp_index01.dbf'  to '/u02/oradata/democdb/demopdb/ifsapp_index01.dbf';
alter database move datafile '/u02/oradata/democdb/prodpdb/ifsapp_report_data01.dbf'  to '/u02/oradata/democdb/demopdb/ifsapp_report_data01.dbf';
alter database move datafile '/u02/oradata/democdb/prodpdb/sysaux01.dbf' to '/u02/oradata/democdb/demopdb/sysaux01.dbf';              
alter database move datafile '/u02/oradata/democdb/prodpdb/users01.dbf' to '/u02/oradata/democdb/demopdb/users01.dbf';
alter database tempfile '/u02/oradata/democdb/prodpdb/temp01.dbf' drop including datafiles;
alter tablespace TEMP add tempfile '/u02/oradata/democdb/prodpdb/temp01.dbf' size 500M autoextend on next 10m maxsize unlimited;
alter session set container=DEMOPDB;
alter user ifsapp identified by ifsdemo;
        begin
        dbms_network_acl_admin.assign_acl (
        acl => 'IFSAPP-PLSQLAP-Permission.xml',
        host => 'https://appserver:48080',
        lower_port => 50000,
        upper_port => 60000);
        end;
        /
        update ifsapp.plsqlap_environment_tab set value='https://appserver:48080/fndext/internalsoapgateway' where name='CONN_STR';
        commit
        /
        exit;
EOF
 