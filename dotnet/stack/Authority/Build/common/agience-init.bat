@echo off

set ENVIRONMENT=%1

SETLOCAL ENABLEDELAYEDEXPANSION

set AGIENCE_INITIALIZE=TRUE

cd ..

echo Creating configurations...

cd ..\Identity

IF NOT EXIST .env.%ENVIRONMENT% (
    copy .env.sample .env.%ENVIRONMENT%
)

cd ..\Database

IF NOT EXIST .env.%ENVIRONMENT% (
    copy .env.sample .env.%ENVIRONMENT%
    
    echo Generating DB password...
    cd ..\Build\common
    call generate-db-password.bat %ENVIRONMENT%
    cd ..

)

cd ..\Manage

IF NOT EXIST .env.%ENVIRONMENT% (
    copy .env.sample .env.%ENVIRONMENT%
)

cd ..\Build\common

echo Initializing database...

call docker-up.bat %ENVIRONMENT% database

call ef-migrate.bat

docker exec -it database-cont psql -U agience_db_root -d agience_authority -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
docker exec -it database-cont psql -U agience_db_root -d agience_authority -c "SELECT * FROM pg_extension WHERE extname = 'pg_trgm';"

echo Configuring manage host...

call docker-up.bat %ENVIRONMENT% identity

 timeout /t 10

call update-manage-env.bat %ENVIRONMENT% 

REM call docker-down.bat %ENVIRONMENT% 

ENDLOCAL