alter session set container=freepdb1;
BEGIN
  apex_instance_admin.set_workspace_parameter
   (p_workspace => 'NOVAJI',
    p_parameter => 'MAX_WEBSERVICE_REQUESTS' ,
    p_value     => 10000000);
    COMMIT;
END;
/
