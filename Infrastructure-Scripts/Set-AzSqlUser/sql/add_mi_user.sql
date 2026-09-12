IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE NAME = '$(Username)') BEGIN
	CREATE USER "$(Username)" FROM EXTERNAL PROVIDER;
END