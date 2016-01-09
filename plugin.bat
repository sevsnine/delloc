if "%bat_version%"=="" exit /b

set PATH=!PATH!;%plugdir%\bin\;
set "skiplng=ru en uk"

rd /S /Q "%plugdir%temp\" 2>nul 1>nul
md "%plugdir%temp\" 2>nul 1>nul

FOR /D %%F IN ("_INPUT_APK\!apk_base!") DO (
	call :clean "%%~F"
)
pause
exit /b

:clean
set "errorlng="
cls
echo.
echo.                                              delloc %str_version%
echo.%bat_line%
echo [*] %str_cleaning% %~nx1...
if not exist "%~1.apk" goto :fail
aapt dump badging "%~1.apk" > "%plugdir%temp\dump"
if errorlevel 1 goto :fail
if not exist "%~1\AndroidManifest.xml" goto :fail

echo [*] ...
call :dumplocale
if errorlevel 1 goto:fail
call :getvaluefolders "%~1" "%locale_list%" "locale_list"
call :getvaluefolders "%~1" "%skiplnglist%" "skiplnglist"

set "locale_list="
for %%i in ("%plugdir%temp\locale_list\*") do set "locale_list=!locale_list!%%~nxi "
rem if "%locale_list%"=="" exit /b

dir /b /a-d "%~1\res\raw\">"%plugdir%temp\skiprawlist_unsort.txt" 2>nul
for %%S in (%skiplnglist%) do (
	dir /b /a-d "%~1\res\raw-%%S\">>"%plugdir%temp\skiprawlist_unsort.txt" 2>nul
)
findstr /Rv "^$" "%plugdir%temp\skiprawlist_unsort.txt" 2>nul | usort -u > "%plugdir%temp\skiprawlist.txt"

rd /S /Q "%plugdir%temp\dloc\" 2>nul 1>nul
md "%plugdir%temp\dloc\" 2>nul 1>nul

ren "%~1\res\values" "values-0" 2>nul 1>nul

for /f "tokens=*" %%A in ('dir /b "%~1\res\values-0\" ^| findstr /v "public " 2^>nul') do (
	call :parsexml "%~1" "values-0" "%%~xnA" "dloc"
)

for %%i in ("%plugdir%temp\skiplnglist\*") do (
	for /f "usebackq tokens=*" %%j in ("%plugdir%temp\skiplnglist\%%~nxi") do (
		for %%k in ("%~1\res\%%j\*") do (
			call :parsexml "%~1" "%%j" "%%~nxk" "dloc"
		)
	)
)

call :sortuniq "dloc"

cecho [*] {!colG!}%str_locales%: {# #}%locale_list%{\n}
cecho [*] {!colG!}%str_skip%: {# #}%skiplnglist%{\n}
echo.
del /s /q "%~1\delloc.log" >nul 2>nul
if "%locale_list%"=="" exit /b
if not "!apk_base!"=="*" (
	pause
	echo.
)
echo %bat_line%>"%~1\delloc.log"
echo [*] %str_locales%: %locale_list%>>"%~1\delloc.log"
echo [*] %str_skip%: %skiplnglist%>>"%~1\delloc.log"
echo %bat_line%>>"%~1\delloc.log"
echo.>>"%~1\delloc.log"
for %%i in ("%plugdir%temp\locale_list\*") do (
	call :try "%~1" "%%~nxi"
)
echo %bat_line%
cecho %str_skip%: {!colR!}!errorlng!{# #}{\n}
echo %bat_line%
echo.
cecho [*] {!colG!}%str_done%{# #}{\n}
ren "%~1\res\values-0" "values" 2>nul 1>nul
exit /b

:try
echo %str_checking% %~2...
echo %str_checking% %~2...>>"%~1\delloc.log"
call :compvalue "%~1" "%~2"
if !compvalue! equ 0 (
	for /f "usebackq tokens=*" %%j in ("%plugdir%temp\locale_list\%~2") do (
		rd /s /q "%~1\res\%%j"
	)
	rd /s /q "%~1\res\raw-%~2" >nul 2>nul
	cecho {!colG!}%str_done%{# #}{\n}{\n}
	echo %str_done%>>"%~1\delloc.log"
	echo.>>"%~1\delloc.log"
) else (
	set "errorlng=!errorlng!%~2 "
	cecho {!colR!}%str_error%{# #}{\n}{\n}
	echo %str_error%>>"%~1\delloc.log"
	echo.>>"%~1\delloc.log"
)
exit /b

:dumplocale
for /f "tokens=*" %%S in ('2^>nul findstr /B "locales:" "%plugdir%temp\dump"') do set "dumplocale=%%S"
if "%dumplocale%"=="" exit /b 1
set "dumplocale=%dumplocale:~17%"
if "%dumplocale%"=="" exit /b 1
set "dumplocale=%dumplocale:-=-r%"
set "dumplocale=%dumplocale:'=%"
set "locale_list="
set "skiplnglist="

for %%j in (%dumplocale%) do (
	echo %%j | findstr /bv "%skiplng%" >nul 2>nul && set "locale_list=!locale_list!%%j " || set "skiplnglist=!skiplnglist!%%j "
)
if "%locale_list%"=="" exit /b 1
exit /b 0

:compvalue
setlocal enableextensions enabledelayedexpansion
set sOut=%~0
set /A sResult=0

for /f "usebackq tokens=*" %%A in ("%plugdir%temp\locale_list\%~2") do (
	if !sResult! equ 0 (
		call :needdelete "%~1" "%%A"
		if !needdelete! equ 0 set /A sResult=1
	)
)
if exist "%~1\res\raw-%~2\" if !sResult! equ 0 (
	dir /b /a-d "%~1\res\raw-%~2\">"%plugdir%temp\cur_skiprawlist.txt" 2>nul
	>nul 2>nul findstr /ilxvg:"%plugdir%temp\skiprawlist.txt" "%plugdir%temp\cur_skiprawlist.txt" && (
		set /A sResult=1
	)
)

endlocal & set %sOut:~1%=%sResult%
exit /b

:getvaluefolders
rd /S /Q "%plugdir%temp\%~3" 2>nul 1>nul
md "%plugdir%temp\%~3" 2>nul 1>nul

setlocal enableextensions enabledelayedexpansion
for %%A in (%~2) do (
	for /f "tokens=*" %%B in ('2^>nul dir /b "%~1\res\" ^| findstr "values-%%A"') do (
		set tVar=%%B
		set tVar=!tVar:~7!
		set tVar1=TRUE
		if /i not "!tVar:~3,1!"=="r" (
			if /i "!tVar:~0,2!"=="sw" if not "!tVar:~2,1!"=="" if not "!tVar:~2,1!"=="-" set tVar1=FALSE
			if "!tVar1!"=="TRUE" echo %%B>>"%plugdir%temp\%~3\%%A"
		) else (
			if /i "!tVar:~0,6!"=="%%A" echo %%B>>"%plugdir%temp\%~3\%%A"
		)
	)
)
endlocal
exit /b

:needdelete
setlocal enableextensions enabledelayedexpansion
set sOut=%~0
set /A sResult=1

rd /s /q "%plugdir%temp\cloc\" 2>nul 1>nul
md "%plugdir%temp\cloc\" 2>nul 1>nul

for %%A in ("%~1\res\%~2\*") do (
	call :parsexml "%~1" "%~2" "%%~nxA" "cloc"
)
call :sortuniq "cloc"

for %%A in ("%plugdir%temp\cloc\*") do ( 
	if !sResult! equ 1 (
		if exist "%plugdir%temp\dloc\%%~nxA" (
			>nul 2>nul findstr /ilxvg:"%plugdir%temp\dloc\%%~nxA" "%plugdir%temp\cloc\%%~nxA" && (
				set tVar3=%%~nxA
				echo.>>"%~1\delloc.log"
				echo ---^> !tVar3:-=\!>>"%~1\delloc.log"
				echo %bat_line%>>"%~1\delloc.log" 
				>>"%~1\delloc.log" 2>nul findstr /ilxvg:"%plugdir%temp\dloc\%%~nxA" "%plugdir%temp\cloc\%%~nxA"
				echo %bat_line%>>"%~1\delloc.log"
				set /A sResult=0	
			)
		) else  (
			set tVar3=%%~nxA
			echo.>>"%~1\delloc.log"
			echo %bat_line%>>"%~1\delloc.log" 
			echo !tVar3:-=\! %str_notfound%>>"%~1\delloc.log"
			echo %bat_line%>>"%~1\delloc.log"
			set /A sResult=0
		)
	)
)
endlocal & set %sOut:~1%=%sResult%
exit /b

:fail
cecho {!colR!}%str_error%{# #}{\n}
exit /b

:parsexml
setlocal enableextensions enabledelayedexpansion
for /f "tokens=* delims=" %%A in ('2^>nul uxml el -u "%~1\res\%~2\%~3" ^| findstr /R "resources/.[^/]*$"') do (
	set "tVar=%%A"
	set "tVar=!tVar:~10!"
	uxml sel -t -m //resources -v @name -n -m !tVar! -n -v @name "%~1\res\%~2\%~3">>"%plugdir%temp\%~4\%~n3-!tVar!" 2>nul
)
endlocal
exit /b

:sortuniq
setlocal enableextensions enabledelayedexpansion
for %%A in ("%plugdir%temp\%~1\*") do (
	type "%plugdir%temp\%~1\%%~nxA" | findstr /Rv "^$" | usort -u > "%plugdir%temp\%~1\%%~nxA-sort"
	del /s /q "%plugdir%temp\%~1\%%~nxA" 2>nul >nul
	ren "%plugdir%temp\%~1\%%~nxA-sort" "%%~nxA" 2>nul >nul
)
endlocal
exit /b