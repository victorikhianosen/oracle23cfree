Rem  Copyright (c) Oracle Corporation 2023. All Rights Reserved.
Rem
Rem    NAME
Rem      ords_set_editioning.sql
Rem
Rem    DESCRIPTION
Rem      A script to set all editionable objects in ORDS_METADATA schema to the same editioning setting
Rem
Rem    REQUIREMENTS
Rem      Oracle Database Release 12.1 or later
Rem      Assumes user with administrator privileges is connected.
Rem
Rem    ARGUMENTS:
Rem      1  : Editioning setting. Pass either EDITIONABLE or NONEDITIONABLE. NONEDITIONABLE is the recommended default value.

Rem    NOTES
Rem      This script is to ensure all ORDS_METADATA objects have the same editioning setting.
Rem      ORDS does not explicitly set editioning for editionable object, however database upgrades can leave objects
Rem      in an inconsistent or incompatible state. Run this script if you see the following error
Rem      during the upgrade:
Rem
Rem        Error: ORA-38824: A CREATE OR REPLACE command may not change the EDITIONABLE property of an existing object.
Rem
Rem      Setting the objects to NONEDITIONABLE is the recommended action but EDITIONABLE may be the correct setting depending on
Rem      the database configuration.
Rem
Rem    MODIFIED   (MM/DD/YYYY)
Rem      epaglina  05/31/2023  Created.
Rem      dwhittin  11/20/2023  Support switching to either editioning settings.
Rem
set verify off
set termout off
set define '&'
set termout on

define EDITIONING = '&1'

declare
  c_schema constant VARCHAR2(50) := 'ORDS_METADATA';
  c_enq_schema constant VARCHAR2(60) := sys.dbms_assert.enquote_name('ORDS_METADATA');
  c_editionable constant VARCHAR2(11) := 'EDITIONABLE';
  c_non_editionable constant VARCHAR2(14) := 'NONEDITIONABLE';

  l_editioning VARCHAR2(14) := '&EDITIONING';
  l_edition_filter varchar2(1);

  function set_edition_filter return varchar2
  as
  begin
    if l_editioning = c_editionable then
      -- look for non-editionable objects
      return 'N';
    elsif l_editioning = c_non_editionable then
      -- look for editionable objects
      return 'Y';
    else
      -- invalid editioning
      raise_application_error(-20001,'Invalid editioning parameter passed. Only EDITIONABLE and NONEDITIONABLE allowed.');
    end if;
  end set_edition_filter; 
begin
  l_edition_filter := set_edition_filter;

  dbms_output.put_line('Started: Setting editionable objects in ' || c_schema || ' to ' || l_editioning);

  for obj in (select object_type, object_name from sys.dba_objects where owner = c_schema
                    and object_type not in ('PACKAGE BODY','TYPE BODY')
                    and editionable=l_edition_filter
                    order by object_type, object_name)
  loop
    dbms_output.put_line('ALTER ' || obj.object_type || ' ' || c_enq_schema || '.' || sys.dbms_assert.enquote_name(obj.object_name) || ' ' || l_editioning);
    execute immediate 'ALTER ' || obj.object_type || ' ' || c_enq_schema || '.' || sys.dbms_assert.enquote_name(obj.object_name) || ' ' || l_editioning;
  end loop;

  dbms_output.put_line('Completed: All editionable objects in ' || c_schema || ' are set to ' || l_editioning);
exception
  when others then
    dbms_output.put_line('Error occurred: ' || sqlerrm);
end;
/