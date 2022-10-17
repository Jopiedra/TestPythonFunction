@ECHO OFF

SETLOCAL EnableDelayedExpansion

@echo:
@echo Welcome to CANDEPLOY Tool, Version 3.1.
@echo:
@echo:

REM --- Error control. (Adjust vtimeout to increase or decrease the number of retries when an error occurs)
	set vtimeout=360
	set verror=0
	set vforcelastversion=1
	set envnametodeploy=
	set waitforawsactivesuccessresponse=
	set currentawslambdaversion=

REM --- Parameters cannot be empty or blank.
	if [%1]==[] goto :instructions
	if [%~1]==[] goto :instructions
	if [%2]==[] goto :instructions
	if [%~2]==[] goto :instructions
	if [%3]==[] goto :instructions
	if [%~3]==[] goto :instructions
	if [%4]==[] goto :instructions
	if [%~4]==[] goto :instructions

REM --- Validating and extracting lambda function name.
	set vfunctionname=%1

REM --- Validating and extracting the environment target.
	set vdeploymenttarget=%2
	set _condres=0
	if /I "!vdeploymenttarget!" == "/build" (
		set envnametodeploy=
		set _condres=1
	)
	if /I "!vdeploymenttarget!" == "/prod" (
		set envnametodeploy=Production
		set _condres=1
	)
	if /I "!vdeploymenttarget!" == "/dev" (
		set envnametodeploy=Development
		set _condres=1
	)
	if /I "!vdeploymenttarget!" == "/qa" (
		set envnametodeploy=QA
		set _condres=1
	)
	if /I "!vdeploymenttarget!" == "/aut" (
		set envnametodeploy=Automation
		set _condres=1
	)
	if !_condres! EQU 0 (
		@echo **** CANDeploy ERROR: Unknonw environment target. ****
		@echo **** Please, refer to the instructions below.     ****
		@echo:
		set verror=-1
		goto :instructions
	)

REM --- Validating and extracting source code format.
	set vsourcecode=%3
	set _condres=0
	@echo:
	if /I "!vsourcecode!" == "/python" set _condres=1
	if /I "!vsourcecode!" == "/netcore" set _condres=1
	if !_condres! EQU 0 (
		@echo **** CANDeploy ERROR: Unknonw source code type. ****
		@echo **** Please, refer to the instructions below.   ****
		@echo:
		set verror=-1
		goto :instructions
	)

REM *****************************************************************************
REM Deploying package.
REM ================================

REM --- Determine which deployment process must be executed.
	if /I "!vsourcecode!" == "/python" goto :pythondeploy
	if /I "!vsourcecode!" == "/netcore" goto :netcoredeploy
	set verror=-1
	goto :instructions

REM --- Python deployment subroutine.
:pythondeploy
    @echo ************* SUCCESS pythondeploy ************
    goto :end

REM --- .NET Core deployment subroutine.
:netcoredeploy
    @echo ************* SUCCESS netcoredeploy ************
    goto :end

REM *****************************************************************************
REM Help menu.
REM ================================
:instructions
   @echo ===========================================================================================================================
   @echo CANDEPLOY Tool, Version 3.1 (Supports: Python and .NET)
   @echo:
   @echo This tool deploys Lambda functions to AWS Servers.
   @echo ---------------------------------------------------------------------------------------------------------------------------
   @echo CANDEPLOY ^<function-name^> /[prod^|dev^|qa^|build^|aut] /[python^|netcore] /prj:^<project-directory^> /noforce
   @echo:
   @echo:
   @echo   ^<function-name^>           :   AWS Lambda function name.
   @echo   /[prod^|dev^|qa^|build]      :   Deploys to production, development, QA, Automation or /build to the AWS LATEST version.
   @echo   /[python^|netcore]         :   Kind of project to deploy (can be python or .net core).
   @echo   /prj:^<project-directory^>  :   Directory where the Python code is or where the .NET solution file is.
   @echo   /noforce                  :   When the code to deploy has no changes from the last deployed version AWS does not create
   @echo                                 a new version. By default, in this situation CANDeploy will set the lastest version number
   @echo                                 to the target environment. If you want to turn off this behavior and throw an error instead
   @echo                                 of the default action then you have to use /noforce.
   @echo:
   @echo:
   @echo Example:
   @echo   C:\^>candeploy AWSLambdaRocks /build /netcore /prj:C:\Development\temp\MyDotNETFunction\AWSLambda1
   @echo                                                                                               ^^
   @echo                                                                                               ^|
   @echo                           Directory where the project is. If it is a .NET project  ^<----------^*
   @echo                           then it must be the directory where the .csproj (project file) is.
   @echo                           DO NOT PUT THE FINAL "\".
   @echo:
   @echo WARNING!!!
   @echo ----------------------------------------------------------------------------------------------------------------
   @echo ^|This deployment script requires at least a basic schema version of the lambda function defined in AWS already.^|
   @echo ^|So, please make sure your AWS Lambda function already exists in AWS before using this Script.                 ^|
   @echo ----------------------------------------------------------------------------------------------------------------
   @echo:



REM *****************************************************************************
REM End of the Script.
REM ================================
:end
   @echo:
   if !verror! EQU 0 (
      @echo DONE.
   ) else (
      @echo ERROR.
   )
   exit /b !verror!
