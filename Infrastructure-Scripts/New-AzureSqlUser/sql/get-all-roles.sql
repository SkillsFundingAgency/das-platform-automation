SELECT DatabasePrincipals2.name AS DatabaseUserName, DatabasePrincipals1.name AS DatabaseRoleName     
FROM sys.database_role_members AS DatabaseRoleMembers 
	RIGHT OUTER JOIN sys.database_principals AS DatabasePrincipals1 
		ON DatabaseRoleMembers.role_principal_id = DatabasePrincipals1.principal_id 
	LEFT OUTER JOIN sys.database_principals AS DatabasePrincipals2 
		ON DatabaseRoleMembers.member_principal_id = DatabasePrincipals2.principal_id 
WHERE DatabasePrincipals1.type = 'R' AND DatabasePrincipals2.name IS NOT NULL
ORDER BY DatabasePrincipals1.name;