@echo off
:: Configura tu contraseña aquí
set SUPABASE_DB_PASSWORD=TU_CONTRASEÑA_AQUI

echo Generando tipos de Dart directamente desde la base de datos...

:: Usamos la conexión directa, esto evita el error de permisos de roles
call supabase gen types dart --db-url "postgresql://postgres:qS15W6dMgN6NNEML@db.cavapauhxtotjtlousch.supabase.co:5432/postgres" > lib/models/database.types.dart

echo.
echo ¡Sincronización de tipos completada!
echo Archivo generado en: lib/models/database.types.dart
echo.
pause