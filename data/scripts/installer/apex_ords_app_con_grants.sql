Rem  Copyright (c) 2011, 2023, Oracle and/or its affiliates.
Rem
Rem    NAME
Rem      apex_ords_app_con_grants.sql
Rem
Rem    DESCRIPTION
Rem      This script provides the following grants:
Rem        1. Make the APEX gateway user proxiable to the runtime user
Rem        2. Grant execute on ORDS_APEX_SSO package to APEX schema for the current release.
Rem
Rem    PARAMETERS
Rem
Rem    NOTES
Rem      Assumes the user has Oracle Application Container privileges.
Rem
Rem    REQUIRMENTS
Rem    This must be executed in the APEX application.
Rem
Rem    alter pluggable database application APEX begin upgrade to <APEX_UPGRADE_VERSION>
Rem    @/path/to/scripts/installer/apex_ords_app_con_grants.sql
Rem    alter pluggable database application APEX end upgrade;
Rem
Rem    where <APEX_UPGRADE_VERSION> is the next upgrade version in the format <Year.Quarter.UpgradeNumber>
Rem    select app_name, app_version, app_status from dba_applications where app_name = 'APEX';
Rem    If app_version = '23.1' then the <APEX_UPGRADE_VERSION> = '23.1.1'
Rem    Example:  alter pluggable database application APEX begin upgrade to '23.1.1';
Rem
Rem
Rem    MODIFIED   (MM/DD/YYYY)
Rem    epaglina   10/02/2023 - Created script for Bug 35193383
Rem
set serveroutput on;

declare
   c_ords_schema  constant varchar2(255) := 'ORDS_METADATA';
   c_runtime_user constant varchar2(255) := 'ORDS_PUBLIC_USER';
   c_gateway_user constant varchar2(255) := 'APEX_PUBLIC_USER';

    procedure grant_connect_through(p_gateway_user IN VARCHAR2, 
                                    p_runtime_user IN VARCHAR2) is
       c_gateway_usr constant varchar2(255) := sys.dbms_assert.schema_name(p_gateway_user);
       c_runtime_usr constant varchar2(255) := sys.dbms_assert.schema_name(p_runtime_user);
       c_alter_user_connect constant varchar2(255) := 'alter user ' || c_gateway_usr || ' grant connect through ' || c_runtime_usr;
    begin
       execute immediate c_alter_user_connect;
       -- sys.dbms_output.put_line(c_alter_user_connect);
       sys.dbms_output.put_line('Made ' || c_gateway_usr || ' proxiable from ' || c_runtime_usr);
    exception 
       when others then
          sys.dbms_output.put_line('ERROR: Failed to make ' || c_gateway_usr || ' proxiable from ' || c_runtime_usr || ' , error: '|| sqlerrm);
    end grant_connect_through;
    
    procedure grant_execute_apex_sso(p_schema IN VARCHAR2) is
      c_ords_schema   constant varchar2(255) := sys.dbms_assert.schema_name(p_schema);
      c_pkg_name      constant varchar2(255) := sys.dbms_assert.sql_object_name('ORDS_METADATA.ORDS_APEX_SSO');
      c_grant_execute constant varchar2(255) := 'grant execute on ' || c_pkg_name || ' to ';
      c_select_ver    constant varchar2(200) := 'select version_no from apex_release';
      l_apex_schema     varchar2(255);
      l_current_release varchar2(100) := 'UNKNOWN';
    begin
       -- Get the APEX schema
       for apex_cursor in (select table_owner from sys.dba_synonyms
                              where  owner = 'PUBLIC'
                                     and synonym_name = 'APEX'
                                     and table_owner like 'APEX_%')
       loop
         l_apex_schema := sys.dbms_assert.schema_name(apex_cursor.table_owner);
         
         begin
           execute immediate c_select_ver into l_current_release;
         exception 
           when others then
           null;
         end;
       end loop;
    
       -- Grant execute on ORDS_APEX_SSO package to the resolved APEX schema
       if l_apex_schema is not null then
         begin
           execute immediate c_grant_execute || l_apex_schema;
           -- sys.dbms_output.put_line(c_grant_execute || l_apex_schema);
           sys.dbms_output.put_line('Found APEX release ' || l_current_release || '. Grant execute on ORDS_APEX_SSO package to ' || l_apex_schema);
         exception
           when others then
             sys.dbms_output.put_line('ERROR: Failed to ' || c_grant_execute || l_apex_schema || ' , error: '|| sqlerrm);
         end;
       end if;
    end grant_execute_apex_sso;

begin
    for i in ( select username from sys.dba_users where username = 'ORDS_METADATA' )
    loop
         -- Make gateway user proxiable to the runtime user
         grant_connect_through(c_gateway_user, c_runtime_user);

         -- Allow apex schema to execute package ords_apex_sso
         grant_execute_apex_sso(c_ords_schema);
    end loop;
    
 end;
/