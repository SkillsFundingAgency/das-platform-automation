select  princ.name
,       perm.permission_name
,       perm.class_desc
,       object_name(perm.major_id) AS "schema_object"
from    sys.database_principals princ
left join
        sys.database_permissions perm
on      perm.grantee_principal_id = princ.principal_id
WHERE princ.name = '$(Username)';

