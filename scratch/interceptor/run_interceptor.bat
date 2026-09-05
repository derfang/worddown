@echo off
cd /d "%~dp0"
echo ========================================================
set PYTHON_EXE=C:\Users\PADIDAR\AppData\Local\Programs\Python\Python311\python.exe

echo Installing Playwright...
"%PYTHON_EXE%" -m pip install playwright

echo.
echo Installing Playwright Chromium browser...
"%PYTHON_EXE%" -m playwright install chromium

echo.
echo Running Interceptor...
"%PYTHON_EXE%" intercept.py
pause
