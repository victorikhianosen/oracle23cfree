alter session set container=freepdb1;
grant db_developer_role to swift_parser;
grant execute on javascript to swift_parser;
grant db_developer_role to novaji;
grant execute on javascript to novaji;
grant execute on DBMS_CRYPTO to swift_parser;
grant execute on DBMS_CRYPTO to novaji;
grant execute on UTL_HTTP to swift_parser;
grant execute on UTL_HTTP to novaji;

/
