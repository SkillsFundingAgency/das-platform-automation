SELECT m.name as Member, r.name AS Role
FROM sys.database_role_members
INNER JOIN sys.database_principals m ON sys.database_role_members.member_principal_id = m.principal_id
INNER JOIN sys.database_principals r ON sys.database_role_members.role_principal_id = r.principal_id
WHERE m.name = '$(Username)' and r.name NOT IN ( '$(Roles)' )