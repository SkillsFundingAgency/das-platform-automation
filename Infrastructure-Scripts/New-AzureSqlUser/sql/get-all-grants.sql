SELECT Principals.principal_id, Principals.name AS DatabaseUserName,  
	Permissions.permission_name AS PermissionName, '[' + DbSchemas.name + '].[' + DbObjects.name + ']' AS ObjectName 
FROM sys.database_principals AS Principals 
	JOIN sys.database_permissions AS Permissions 
		ON Permissions.grantee_principal_id = Principals.principal_id 
	LEFT OUTER JOIN sys.objects AS DbObjects 
		ON Permissions.major_id = DbObjects.object_id 
	LEFT OUTER JOIN sys.schemas AS DbSchemas 
		ON DbObjects.schema_id = DbSchemas.schema_id
ORDER BY Principals.name
