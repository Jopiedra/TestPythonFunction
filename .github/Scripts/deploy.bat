@ECHO OFF

SETLOCAL EnableDelayedExpansion

@echo:
@echo Welcome to CANDEPLOY Tool, Version 3.1.
@echo:
@echo:

REM *****************************************************************************
REM VALIDATION PROCESS
REM ================================

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

REM --- Validating and extracting source code directory.
	set vprjdirectory=%4
	if /I NOT "!vprjdirectory:~0,5!" == "/prj:" (
		@echo **** CANDeploy ERROR: Project directory was not specified. ****
		@echo **** Please, refer to the instructions below.              ****
		@echo:
		set verror=-1
		goto :instructions
	)
	set vprjdirectory=!vprjdirectory:~5!
	if /I "!vprjdirectory!" == "" (
		@echo **** CANDeploy ERROR: Project directory was not specified. ****
		@echo **** Please, refer to the instructions below.              ****
		@echo:
		set verror=-1
		goto :instructions
	)
	if NOT exist !vprjdirectory!\ (
		@echo **** CANDeploy ERROR: Project directory not found. ****
		@echo **** Please, refer to the instructions below.      ****
		@echo:
		set verror=-1
		goto :instructions
	)

REM --- Force the environment to assume the latest version when the deployed code does not have changes.
	if [%5]==[] (
		goto :endforcelastversion
	)
	if [%~5]==[] (
		goto :endforcelastversion
	)
	set vforcedeploytolastversion=%5
	if /I "!vforcedeploytolastversion!" == "/noforce" (
		set vforcelastversion=0
	)	
	:endforcelastversion

REM --- Getting current AWS Lambda Version (Before deploying).
	set vcurrentversion=
	CALL :getcurrentawslambdaversion
	if !currentawslambdaversion!=="UNKNOWN" (
		@echo **** CANDeploy ERROR: The current version of the requested lambda function could not be obtained. ****
		@echo **** Please, refer to the instructions below.              ****
		@echo:
		set verror=-1
		goto :instructions
	)
	set vcurrentversion=!currentawslambdaversion!



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
	if exist !vfunctionname!.zip DEL !vfunctionname!.zip
	7z a -r !vfunctionname!.zip !vprjdirectory!\*.*
	if %ERRORLEVEL% NEQ 0 ( 
		set verror=-1
		goto :end
	)

	REM --- BEGIN ONLY BUILD, DO NOT DEPLOY.
	if "!vdeploymenttarget!" == "/build" (
		REM ==================== Deploying AWS Lambda ====================
		aws lambda update-function-code --function-name !vfunctionname! --zip-file fileb://!vfunctionname!.zip
		if %ERRORLEVEL% NEQ 0 ( 
			set verror=-1
			goto :end
		)
		REM ==================== Deploying AWS Lambda ====================
						 
						 
		REM ==================== Waiting for AWS Lambda status ACTIVE and SUCCESSFUL... ====================
		CALL :waitforawsactivesuccess
		if !waitforawsactivesuccessresponse! EQU -1 (
			set verror=-1
			goto :end
		)
		REM ==================== Waiting for AWS Lambda status ACTIVE and SUCCESSFUL... ====================	  


		@echo:
		@echo Deployment to the LATEST version...
		goto :end
	)
	REM --- END ONLY BUILD, DO NOT DEPLOY.
	
	
	REM --- BEGIN BUILD AND DEPLOY!
	REM ==================== Deploying AWS Lambda ====================
	aws lambda update-function-code --publish --function-name !vfunctionname! --zip-file fileb://!vfunctionname!.zip
	if %ERRORLEVEL% NEQ 0 (
		set verror=-1
		goto :end
	)
	REM ==================== Deploying AWS Lambda ====================


	REM ==================== Waiting for AWS Lambda status ACTIVE and SUCCESSFUL... ====================
	CALL :waitforawsactivesuccess
	if !waitforawsactivesuccessresponse! EQU -1 (
		set verror=-1
		goto :end
	)
	REM ==================== Waiting for AWS Lambda status ACTIVE and SUCCESSFUL... ====================


	REM ==================== Installing deployed version into the requested environment... ====================
	set /A while_pcounter=0
	:while_p
		set newversion=
		CALL :getcurrentawslambdaversion
		if !currentawslambdaversion!=="UNKNOWN" (
			@echo **** CANDeploy ERROR: The current version of the requested lambda function could not be obtained. ****
			@echo **** Please, refer to the instructions below.              ****
			@echo:
			set verror=-1
			goto :instructions
		)
		set newversion=!currentawslambdaversion!

		if "!newversion!"=="!vcurrentversion!" (
			if !while_pcounter! LEQ !vtimeout! (
				SET /A while_pcounter=!while_pcounter!+1
				REM timeout 10 > NUL		  JENKINS DIDN'T LIKE THIS COMMAND, SO WE WILL RETRY 360 TIMES INSTEAD OF 18!	
				goto :while_p
			) else (
				if !vforcelastversion! EQU 0 (
					@echo **** CANDeploy ERROR: The new version of the requested lambda function could not be obtained. ****
					@echo **** Maybe the code to deploy does not have changes from the current latest version.          ****
					@echo:
					set verror=-1
					goto :end
				) else (
					@echo **** The code to deploy seems to be the same one as the current latest version. ****
					@echo **** The version !newversion! will be applied to the environment !envnametodeploy!.             ****
					@echo:
				)
			)	
		)

	aws lambda update-alias --function-name !vfunctionname! --function-version !newversion! --name !envnametodeploy!
	if %ERRORLEVEL% NEQ 0 (
		@echo **** CANDeploy ERROR: The new number version of the requested lambda function could not be set. ****
		@echo:
		set verror=-1
		goto :end
	)
	REM ==================== Installing deployed version into the requested environment... ====================
	
	
	REM ==================== Waiting for AWS Lambda status ACTIVE and SUCCESSFUL... ====================
	CALL :waitforawsactivesuccess
	if !waitforawsactivesuccessresponse! EQU -1 (
		set verror=-1
		goto :end
	)
	REM ==================== Waiting for AWS Lambda status ACTIVE and SUCCESSFUL... ====================	  


	@echo:
	@echo Deployment to the !envnametodeploy! version...
	goto :end
	REM --- END BUILD AND DEPLOY!


REM --- .NET Core deployment subroutine.
:netcoredeploy
	REM --- BEGIN ONLY BUILD, DO NOT DEPLOY.
	if "!vdeploymenttarget!" == "/build" (
		REM ==================== Deploying AWS Lambda ====================
		cd !vprjdirectory!
		dotnet lambda deploy-function !vfunctionname!
		if %ERRORLEVEL% NEQ 0 ( 
			set verror=-1
			goto :end
		)
		REM ==================== Deploying AWS Lambda ====================
		
		
		REM ==================== Waiting for AWS Lambda status ACTIVE and SUCCESSFUL... ====================
		CALL :waitforawsactivesuccess
		if !waitforawsactivesuccessresponse! EQU -1 (
			set verror=-1
			goto :end
		)		
		REM ==================== Waiting for AWS Lambda status ACTIVE and SUCCESSFUL... ====================
		
		
		@echo:
		@echo Deployment to the LATEST version...
		goto :end
	) 
	REM --- END ONLY BUILD, DO NOT DEPLOY.
	

	REM --- BEGIN BUILD AND DEPLOY!
	REM ==================== Deploying AWS Lambda - Step 1 ====================
	set awsversion=
	cd !vprjdirectory!
	dotnet lambda deploy-function !vfunctionname!
	if %ERRORLEVEL% NEQ 0 ( 
		set verror=-1
		goto :end
	)
	REM ==================== Deploying AWS Lambda - Step 1 ====================


	REM ==================== Waiting for AWS Lambda status ACTIVE and SUCCESSFUL... ====================
	CALL :waitforawsactivesuccess
	if !waitforawsactivesuccessresponse! EQU -1 (
		set verror=-1
		goto :end
	)		
	REM ==================== Waiting for AWS Lambda status ACTIVE and SUCCESSFUL... ====================


	REM ==================== Deploying AWS Lambda - Step 2 ====================
	aws lambda publish-version --function-name !vfunctionname!
	if %ERRORLEVEL% NEQ 0 ( 
		set verror=-1
		goto :end
	)						
	REM ==================== Deploying AWS Lambda - Step 2 ====================


	REM ==================== Waiting for AWS Lambda status ACTIVE and SUCCESSFUL... ====================
	CALL :waitforawsactivesuccess
	if !waitforawsactivesuccessresponse! EQU -1 (
		set verror=-1
		goto :end
	)		
	REM ==================== Waiting for AWS Lambda status ACTIVE and SUCCESSFUL... ====================


	REM ==================== Installing deployed version into the requested environment... ====================
	set /A while_ncounter=0
	:while_n
		set newversion=
		CALL :getcurrentawslambdaversion
		if !currentawslambdaversion!=="UNKNOWN" (
			@echo **** CANDeploy ERROR: The current version of the requested lambda function could not be obtained. ****
			@echo **** Please, refer to the instructions below.              ****
			@echo:
			set verror=-1
			goto :instructions
		)
		set newversion=!currentawslambdaversion!

		if "!newversion!"=="!vcurrentversion!" (
			if !while_ncounter! LEQ !vtimeout! (
				SET /A while_ncounter=!while_ncounter!+1
				REM timeout 10 > NUL		  JENKINS DIDN'T LIKE THIS COMMAND, SO WE WILL RETRY 360 TIMES INSTEAD OF 18!	
				goto :while_n
			) else (
				if !vforcelastversion! EQU 0 (
					@echo **** CANDeploy ERROR: The new version of the requested lambda function could not be obtained. ****
					@echo **** Maybe the code to deploy does not have changes from the current latest version.          ****
					@echo:
					set verror=-1
					goto :end
				) else (
					@echo **** The code to deploy seems to be the same one as the current latest version. ****
					@echo **** The version !newversion! will be applied to the environment !envnametodeploy!.             ****
					@echo:
				)
			)	
		)

	aws lambda update-alias --function-name !vfunctionname! --function-version !newversion! --name !envnametodeploy!
	if %ERRORLEVEL% NEQ 0 (
		@echo **** CANDeploy ERROR: The new number version of the requested lambda function could not be set. ****
		@echo:
		set verror=-1
		goto :end
	)
	REM ==================== Installing deployed version into the requested environment... ====================

	
	REM ==================== Waiting for AWS Lambda status ACTIVE and SUCCESSFUL... ====================
	CALL :waitforawsactivesuccess
	if !waitforawsactivesuccessresponse! EQU -1 (
		set verror=-1
		goto :end
	)		
	REM ==================== Waiting for AWS Lambda status ACTIVE and SUCCESSFUL... ====================
	
	
	@echo:
	@echo Deployment to the !envnametodeploy! version...
	goto :end
	REM --- END BUILD AND DEPLOY!



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



REM *****************************************************************************
REM Waiting for AWS Lambda ACTIVE and SUCCESSFUL status subroutine.
REM ================================
:waitforawsactivesuccess
	set /A waitforawsactivesuccessresponse=0
	set /A awsstatuscounter=0

	@echo:
	@echo Waiting for AWS Lambda status ACTIVE and SUCCESSFUL...
	:while_awsstatuscounter
		set awsstatus=
		for /f "tokens=*" %%i in ('aws lambda get-function --function-name !vfunctionname! --query "Configuration.[State, LastUpdateStatus]"') do (
			if %ERRORLEVEL% NEQ 0 ( 
				set /A waitforawsactivesuccessresponse=-1
				goto :eof
			)

			SET awsstatusline=%%i

			REM Replacing double quote with single quote.
			SET awsstatusline=!awsstatusline:^"='!
				
			REM Concatenating results to evaluate them in the loop.
			SET awsstatus=!awsstatus!!awsstatusline!
		)

		@echo Current status (#!awsstatuscounter!): !awsstatus!
		if /I NOT "!awsstatus!"=="['Active','Successful']" (
			if !awsstatuscounter! LEQ !vtimeout! (
				SET /A awsstatuscounter=!awsstatuscounter!+1
				REM timeout 10 > NUL		  JENKINS DIDN'T LIKE THIS COMMAND, SO WE WILL RETRY 360 TIMES INSTEAD OF 18!	
				goto :while_awsstatuscounter
			) else (
				set /A waitforawsactivesuccessresponse=-1
				@echo TIME-OUT While waiting for AWS Lambda status ACTIVE and SUCCESSFUL..
				goto :eof
			)	
		)
	
	REM ==== RETURN THE FOUND VALUE ====
	exit /b



REM *****************************************************************************
REM Getting the current version number of the Lambda.
REM ================================
:getcurrentawslambdaversion
	set /A awsgetversioncounter=0

	@echo:
	@echo Getting the current AWS Lambda Version...
	set currentawslambdaversion=

	REM Trying with pagination.
	:while_awsgetversioncounterp
		set currentawslambdaversionp=
		set awsversion=
		
		for /f "tokens=*" %%i in ('aws lambda list-versions-by-function --function-name !vfunctionname! --query "max_by(Versions, &to_number(to_number(Version) || '0'))"') do (
			if %ERRORLEVEL% NEQ 0 (
				if !awsgetversioncounter! LEQ !vtimeout! (
					SET /A awsgetversioncounter=!awsgetversioncounter!+1
					REM timeout 10 > NUL		  JENKINS DIDN'T LIKE THIS COMMAND, SO WE WILL RETRY 360 TIMES INSTEAD OF 18!	
					goto :while_awsgetversioncounterp
				) else (
					@echo TIME-OUT While waiting for AWS Lambda Version number...
					set currentawslambdaversionp="UNKNOWN"
					goto :getcurrentawslambdaversion_end
				)	
			)

			set awsversion=%%i

			if "!awsversion:~1,4!"=="Vers" (

				set fversion=!awsversion:~0,-2!
				set fversion=!fversion:~12!
				set currentawslambdaversionp=!fversion!
				goto :wend_awsgetversioncounterp

			)
		)
	:wend_awsgetversioncounterp

	REM Trying with no pagination.
	set /A awsgetversioncounter=0
	:while_awsgetversioncounternp
		set currentawslambdaversionnp=
		set awsversion=
		
		for /f "tokens=*" %%i in ('aws lambda list-versions-by-function --function-name !vfunctionname! --no-paginate --query "max_by(Versions, &to_number(to_number(Version) || '0'))"') do (
			if %ERRORLEVEL% NEQ 0 (
				if !awsgetversioncounter! LEQ !vtimeout! (
					SET /A awsgetversioncounter=!awsgetversioncounter!+1
					REM timeout 10 > NUL		  JENKINS DIDN'T LIKE THIS COMMAND, SO WE WILL RETRY 360 TIMES INSTEAD OF 18!	
					goto :while_awsgetversioncounternp
				) else (
					@echo TIME-OUT While waiting for AWS Lambda Version number...
					set currentawslambdaversionnp="UNKNOWN"
					goto :getcurrentawslambdaversion_end
				)	
			)

			set awsversion=%%i

			if "!awsversion:~1,4!"=="Vers" (

				set fversion=!awsversion:~0,-2!
				set fversion=!fversion:~12!
				set currentawslambdaversionnp=!fversion!
				goto :wend_awsgetversioncounternp
				
			)
		)
	:wend_awsgetversioncounternp

	REM Getting the higher version of them.
	if !currentawslambdaversionp!=="UNKNOWN" (
		set currentawslambdaversion="UNKNOWN"
		goto :getcurrentawslambdaversion_end
	)
	if !currentawslambdaversionnp!=="UNKNOWN" (
		set currentawslambdaversion="UNKNOWN"
		goto :getcurrentawslambdaversion_end
	)
	set currentawslambdaversion=!currentawslambdaversionp!
	if !currentawslambdaversionp! LEQ !currentawslambdaversionnp! (
		set currentawslambdaversion=!currentawslambdaversionnp!
	)

	REM ==== RETURN THE FOUND VALUE ====
	:getcurrentawslambdaversion_end
	@echo Current version (#!awsgetversioncounter!): !currentawslambdaversion!
	exit /b
