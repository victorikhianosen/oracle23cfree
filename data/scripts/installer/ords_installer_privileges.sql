Rem  Copyright (c) Oracle Corporation 2014. All Rights Reserved.
Rem
Rem    NAME
Rem      ords_installer_privileges.sql
Rem
Rem    DESCRIPTION
Rem      Provides privileges required to install, upgrade, validate and uninstall 
Rem      ORDS schema, ORDS proxy user and related database objects.
Rem
Rem    NOTES
Rem      This script includes privileges to packages and views that are normally granted PUBLIC 
Rem      because these privileges may be revoked from PUBLIC.
Rem   
Rem
Rem    ARGUMENT:
Rem      1  : ADMINUSER - The database user that will be granted the privilege
Rem
Rem    REQUIREMENTS
Rem      Oracle Database Release 11.1 or later
Rem
Rem    MODIFIED   (MM/DD/YYYY)
Rem      dwhittin  06/19/2023  Refactor to better support 11g
Rem      epaglina  09/25/2019  Grant SELECT object privilege if DB version 12.1.0.1.
Rem      epaglina  05/22/2019  Created.
Rem

set define '^'
set serveroutput on
set termout on

define ADMINUSER = '^1'

--
-- System privileges
--
grant alter any table                   to ^ADMINUSER;
grant alter user                        to ^ADMINUSER with admin option;
grant comment any table                 to ^ADMINUSER;
grant create any context                to ^ADMINUSER;
grant create any index                  to ^ADMINUSER;
grant create any job                    to ^ADMINUSER;
grant create any procedure              to ^ADMINUSER;
grant create any sequence               to ^ADMINUSER;
grant create any synonym                to ^ADMINUSER;
grant create any table                  to ^ADMINUSER;
grant create any trigger                to ^ADMINUSER with admin option;
grant create any type                   to ^ADMINUSER;
grant create any view                   to ^ADMINUSER;
grant create job                        to ^ADMINUSER with admin option;
grant create public synonym             to ^ADMINUSER with admin option;
grant create role                       to ^ADMINUSER;
grant create session                    to ^ADMINUSER with admin option;
grant create synonym                    to ^ADMINUSER with admin option;
grant create user                       to ^ADMINUSER;
grant create view                       to ^ADMINUSER with admin option;
grant delete any table                  to ^ADMINUSER;
grant drop any context                  to ^ADMINUSER;
grant drop any index                    to ^ADMINUSER;
grant drop any role                     to ^ADMINUSER;
grant drop any table                    to ^ADMINUSER;
grant drop any type                     to ^ADMINUSER;
grant drop any synonym                  to ^ADMINUSER;
grant drop public synonym               to ^ADMINUSER with admin option;
grant drop user                         to ^ADMINUSER;
grant execute any procedure             to ^ADMINUSER;
grant execute any type                  to ^ADMINUSER;
grant grant any object privilege        to ^ADMINUSER;
grant insert any table                  to ^ADMINUSER;
grant select any table                  to ^ADMINUSER;
grant update any table                  to ^ADMINUSER;

declare
  c_grant_set_con constant varchar2(255)  := 'grant set container to ' || dbms_assert.enquote_name('^ADMINUSER')
                                           || ' with admin option';
begin
  -- Only for Oracle DB 12c and later
  if sys.dbms_db_version.VERSION >= 12 then
    dbms_output.put_line(c_grant_set_con);
    execute immediate c_grant_set_con;
  end if;
end;
/

--
-- Object privileges with grant option
--
grant execute on sys.dbms_assert        to ^ADMINUSER with grant option;
grant execute on sys.dbms_crypto        to ^ADMINUSER with grant option;
grant execute on sys.dbms_lob           to ^ADMINUSER with grant option;
grant execute on sys.dbms_metadata      to ^ADMINUSER with grant option;
grant execute on sys.dbms_network_acl_admin to ^ADMINUSER with grant option;
grant execute on sys.dbms_output        to ^ADMINUSER with grant option;
grant execute on sys.dbms_scheduler     to ^ADMINUSER with grant option;
grant execute on sys.dbms_session       to ^ADMINUSER with grant option;
grant execute on sys.dbms_utility       to ^ADMINUSER with grant option;
grant execute on sys.dbms_sql           to ^ADMINUSER with grant option;
grant execute on sys.default_job_class  to ^ADMINUSER with grant option;
grant execute on sys.htp                to ^ADMINUSER with grant option;
grant execute on sys.owa                to ^ADMINUSER with grant option;
grant execute on sys.wpiutl             to ^ADMINUSER with grant option;
grant execute on sys.wpg_docload        to ^ADMINUSER with grant option;
grant execute on sys.utl_smtp           to ^ADMINUSER with grant option;

grant select on sys.user_cons_columns   to ^ADMINUSER with grant option;
grant select on sys.user_constraints    to ^ADMINUSER with grant option;
grant select on sys.user_objects        to ^ADMINUSER with grant option;
grant select on sys.user_procedures     to ^ADMINUSER with grant option;
grant select on sys.user_tab_columns    to ^ADMINUSER with grant option;
grant select on sys.user_tables         to ^ADMINUSER with grant option;
grant select on sys.user_views          to ^ADMINUSER with grant option;

--
-- Object privileges
--

-- For Oracle DB 12.1.0.2 and later, grant READ.  Otherwise, grant SELECT.
declare
  type obj_rec is record (
      obj_name   sys.dba_tab_privs.table_name%TYPE, 
      db_version pls_integer, 
      db_release pls_integer
      );
      
  type obj_list is table of obj_rec;
  
  -- does this database support READ 
  function read_supported
    return boolean
  is
    l_prod_version varchar2(20) := '';
  begin
    if sys.dbms_db_version.VERSION > 12 then
      return TRUE;
    elsif sys.dbms_db_version.VERSION = 12 then
      begin
        select version into l_prod_version from sys.v$instance where version like '12.1.0.1.%';
      exception
        when NO_DATA_FOUND then
          -- 12.1.0.2 or later
          return TRUE;
        when others then
          null;
      end;
    end if;
    
    return FALSE;
  end read_supported;
  
  -- does the database support this object
  function obj_supported(l_obj obj_rec) 
    return boolean
  is
  begin
   if sys.dbms_db_version.version < l_obj.db_version then
     return FALSE;
   elsif sys.dbms_db_version.version > l_obj.db_version then
     return TRUE;
   end if;
   
   if sys.dbms_db_version.release < l_obj.db_release then
     return FALSE;
   end if;
   
   return TRUE;
  end obj_supported;

  -- create and obj_rec
  function obj(
      p_obj_name        IN sys.dba_tab_privs.table_name%TYPE, 
      p_db_version      IN pls_integer default 11, 
      p_db_release      IN pls_integer default 0)
    return obj_rec
  is
    l_obj obj_rec;
  begin
    l_obj.obj_name   := p_obj_name;
    l_obj.db_version := p_db_version;
    l_obj.db_release := p_db_release;
    return l_obj;
  end obj;
begin
  declare
    c_grant_read    constant varchar2(100) := 'grant read on sys.';
    c_grant_select  constant varchar2(100) := 'grant select on sys.';
    c_user_grant    constant varchar2(255) := ' to ' || sys.dbms_assert.enquote_name('^ADMINUSER');
    c_grant_opt     constant varchar2(100) := ' with grant option';
  
    c_use_read      constant boolean := read_supported;
  
    -- grant without grant option
    c_without_admin constant obj_list := obj_list(
                         obj('CDB_SERVICES',     12),
                         obj('CDB_TABLESPACES',  12),
                         obj('DBA_APPLICATIONS', 12,2),
                         obj('DBA_ROLES'),
                         obj('DBA_SYNONYMS'),
                         obj('DBA_TABLESPACES'),
                         obj('DBA_TAB_COLS'),
                         obj('DBA_TAB_PRIVS'),
                         obj('DBA_TEMP_FILES'),
                         obj('PROXY_USERS'),
                         obj('V_$CONTAINERS',    12),
                         obj('V_$DATABASE'),
                         obj('V_$LISTENER_NETWORK'),
                         obj('V_$PARAMETER')
                         );

    -- grant with grant option
    c_with_admin    constant obj_list := obj_list(
                         obj('DBA_NETWORK_ACL_PRIVILEGES'),
                         obj('DBA_NETWORK_ACLS'),
                         obj('DBA_OBJECTS'),
                         obj('DBA_REGISTRY'),
                         obj('DBA_ROLE_PRIVS'),
                         obj('DBA_TAB_COLUMNS'),
                         obj('DBA_USERS'),
                         obj('SESSION_PRIVS')
                         );
  begin
    -- grant objects without grant option
    for i in c_without_admin.first .. c_without_admin.last loop
      if obj_supported(c_without_admin(i)) then
        if c_use_read then
          -- 12c and later use the READ privilege
          dbms_output.put_line( c_grant_read || c_without_admin(i).obj_name || c_user_grant);
          execute immediate c_grant_read || c_without_admin(i).obj_name || c_user_grant;
        else
          dbms_output.put_line(c_grant_select || c_without_admin(i).obj_name || c_user_grant);
          execute immediate c_grant_select || c_without_admin(i).obj_name || c_user_grant;
        end if;
      end if;
    end loop;
  
    -- grant objects with grant option
    for i in c_with_admin.first .. c_with_admin.last loop
      if obj_supported(c_with_admin(i)) then
        if c_use_read then
          -- 12c and later use the READ privilege
          dbms_output.put_line( c_grant_read || c_with_admin(i).obj_name || c_user_grant || c_grant_opt);
          execute immediate c_grant_read || c_with_admin(i).obj_name || c_user_grant || c_grant_opt;
        else
          dbms_output.put_line(c_grant_select || c_with_admin(i).obj_name || c_user_grant || c_grant_opt);
          execute immediate c_grant_select || c_with_admin(i).obj_name || c_user_grant || c_grant_opt;
        end if;
      end if;
    end loop;
  end;
end;
/

-- APEX Support
declare
  c_sel_stmt     constant varchar2(400) := 'select version, schema, status from sys.dba_registry where comp_id = ''APEX''';
  c_grant_select constant varchar2(100) := 'grant select on ';
  c_to_user      constant varchar2(400) := ' to ' || dbms_assert.enquote_name('^ADMINUSER') || ' with grant option';
  l_apex_schema  varchar2(255) := null;
  l_apex_version   varchar2(100) := '';
  l_status         varchar2(100) := null;
  l_tmp_str        varchar2(100) := null;
  l_ver_no         number;
  l_ndx            number;
  
begin
  begin
      execute immediate c_sel_stmt into l_apex_version, l_apex_schema, l_status;
  exception
     when no_data_found then
        null;  -- APEX doesn't exist
  end;
   
  if (l_status is not null) and (l_status = 'VALID') and
      (l_apex_version is not null) and (l_apex_schema is not null) then
   
     l_ndx := instr(l_apex_version, '.');
     l_ndx := l_ndx - 1;
     l_tmp_str := substr(l_apex_version,1,l_ndx);

     l_ver_no := to_number(l_tmp_str);
     
     if (l_ver_no >= 5) or (substr(l_apex_version,1,4) = ('4.2.'))  then
        for c1 in (select table_name from all_tables where owner=l_apex_schema and table_name='WWV_FLOW_RT$MODULES')
        loop
          execute immediate c_grant_select || l_apex_schema || '.' || c1.table_name || c_to_user;
          dbms_output.put_line(c_grant_select || l_apex_schema || '.' || c1.table_name || c_to_user);
        end loop;
        for c1 in (select view_name from all_views where owner=l_apex_schema and view_name='WWV_FLOW_POOL_CONFIG')
        loop
          execute immediate c_grant_select || l_apex_schema || '.' || c1.view_name || c_to_user;
          dbms_output.put_line(c_grant_select || l_apex_schema || '.' || c1.view_name || c_to_user);
        end loop;
     end if;   
   end if;
end;
/