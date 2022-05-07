REM umbraco9 install script V.0.5.4 by Roger Grimstad

@echo off & setlocal
SETLOCAL EnableDelayedExpansion

if exist %~dp0defaults.txt (
 	for /f "delims== tokens=1,2" %%G in (%~dp0defaults.txt) do call :setvar %%G %%H
)

set "DEFAULT_INSTALLPATH=%CD%"	
set "SNAME=MySolution"
set "PNAME=Myproject"
set "DEFAULT_EMAIL=umbraco@idium.no"
set "DEFAULT_PWD=1234567890"
set "DEFAULT_INSTALL_IGLOO=y"
set "DEFAULT_ADD_TO_IIS=y"
set "DEFAULT_DBUSER=sa"
set "IGLOO_PACKAGE=LittleNorth.Igloo"
set "ISEC=Integrated Security"
set "DEFAULT_DBSERVER=localhost\SQLEXPRESS"
set "DEFAULT_UPDATE=n"
set "DEFAULT_FRAMEWORK=net5.0"
set "DEFAULT_ADD_SOLUTION=y"

if not defined FRAMEWORK set "FRAMEWORK=%DEFAULT_FRAMEWORK%"
if not defined UMBRACO_UPDATE_TEMPLATES set /p UPDATE="Update Umbraco Templates (Y/[N]): " || set "UMBRACO_UPDATE_TEMPLATES=%DEFAULT_UPDATE%"
if /I "%UMBRACO_UPDATE_TEMPLATES%" == "y" dotnet new -i Umbraco.Templates::*
if not defined INSTALLPATH set /p INSTALLPATH="Install path (root folder) [%DEFAULT_INSTALLPATH%]: " || set "INSTALLPATH=%DEFAULT_INSTALLPATH%"
if not defined ADD_SOLUTION set /p ADD_SOLUTION="Add solution ([Y]/N): " || set "ADD_SOLUTION=%DEFAULT_ADD_SOLUTION%"
if /I "%ADD_SOLUTION%" == "y" set /p SNAME="Solution Name [%SNAME%]: "
set /p PNAME="Project Name [%PNAME%]: "
set "DEFAULT_DBNAME=%PNAME%"
if not defined DBSERVER set /p DBSERVER="Database Server [%DEFAULT_DBSERVER%]: " || set "DBSERVER=%DEFAULT_DBSERVER%"
if not defined DBNAME set /p DBNAME="Database Name [%DEFAULT_DBNAME%]: " || set "DBNAME=%DEFAULT_DBNAME%"
if not defined UMBRACO_EMAIL set /p UMBRACO_EMAIL="Umbraco login email [%DEFAULT_EMAIL%]: " || set "UMBRACO_EMAIL=%DEFAULT_EMAIL%"
if not defined UMBRACO_PWD set /p UMBRACO_PWD="Umbraco login password [%DEFAULT_PWD%]: " || set "UMBRACO_PWD=%DEFAULT_PWD%"
if not defined ADD_TO_IIS set /p ADD_TO_IIS="Add to IIS? ([Y]/N): " || set "ADD_TO_IIS=%DEFAULT_ADD_TO_IIS%"

if /I "%ADD_TO_IIS%" == "y" (	
	set /p IISNAME="iis name [%PNAME%]: " || set "IISNAME=%PNAME%"
	set /p SUBDOMAIN="Subdomain name [%PNAME%]: " || set "SUBDOMAIN=%PNAME%"
	echo You have to add a DB user and password for IIS to work.
	if not defined DBUSER set /p DBUSER="Database User [%DEFAULT_DBUSER%]: " || set "DBUSER=%DEFAULT_DBUSER%"	
	if not defined DBUSERPWD set /p DBUSERPWD="Database User Password: " || set "DBUSERPWD=%DEFAULT_PWD%"	
)

if defined DBUSERPWD (	
	set "DBCSTRING=Server=%DBSERVER%;Database=%DBNAME%;user id=%DBUSER%;password='%DBUSERPWD%'"
) else (	
	set "DBCSTRING=Server=%DBSERVER%;Database=%DBNAME%;Integrated Security=true"
)

if not defined INSTALL_IGLOO set /p INSTALL_IGLOO="Add Igloo ([Y]/N): " || set "INSTALL_IGLOO=%DEFAULT_INSTALL_IGLOO%"

if /I "%INSTALLPATH%" NEQ "%CD%" cd /d "%INSTALLPATH%"

if /I "%ADD_SOLUTION%" == "y" (
	mkdir "%SNAME%"
	cd "%SNAME%"
	dotnet new sln --name "%SNAME%"
)

dotnet new umbraco -n "%PNAME%" --friendly-name "Admin User" --email "%UMBRACO_EMAIL%" --password "%UMBRACO_PWD%" --connection-string "%DBCSTRING%" --Framework "%FRAMEWORK%"

if /I "%ADD_SOLUTION%" == "y" (
	dotnet sln add "%PNAME%"
)

cd "%PNAME%"

if /I "%INSTALL_IGLOO%" == "y" (
	dotnet add "%PNAME%" package "%IGLOO_PACKAGE%"
)

if defined "%PACKAGES%" (
	for %%a in ("%PACKAGES:,=" "%") do (
		dotnet add "%PNAME%" package %%a
	)
)

if defined "%CUSTOM_PACKAGES%" if defined "%CUSTOM_NUGET_SOURCE%" (
	for %%a in ("%CUSTOM_PACKAGES:,=" "%") do (
		dotnet add "%PNAME%" package %%a -s "%CUSTOM_NUGET_SOURCE%"	   
	)
)

if /I "%ADD_TO_IIS%" == "y" (
	dotnet add package System.Drawing.Common --version 6.0.0
	dotnet add package System.Security.Cryptography.Pkcs --version 6.0.0
	powershell -ExecutionPolicy Bypass addtoiis.ps1 -path "%CD%" -name "%IISNAME%" -sdname "%SUBDOMAIN%" -pname "%PNAME%" -netframework "%FRAMEWORK%"
)

if /I "%ADD_SOLUTION%" == "y" (
	mv .gitignore ..
	git init ..
) else (
	git init
)

dotnet build

if /I "%ADD_TO_IIS%" == "y" (
	if /I "%FRAMEWORK%" == "net6.0" (
		copy "%~dp0System.Security.Cryptography.Pkcs.dll" "%CD%\bin\debug\net6.0\"
	)
	explorer "https://%SUBDOMAIN%.localtest.me"
)

dotnet run

exit /b

:setvar
set p1=%1
set p2=%2
if "%p1:~0,1%" NEQ "#" if defined p2 (
	set %1=%p2:"=%
)

exit /b