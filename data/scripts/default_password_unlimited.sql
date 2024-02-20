alter session set container=freepdb1;
alter profile default limit PASSWORD_LIFE_TIME UNLIMITED;
alter profile default limit PASSWORD_REUSE_MAX UNLIMITED;
alter profile default limit PASSWORD_REUSE_TIME UNLIMITED;
/
