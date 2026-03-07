@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "BUILD_TYPE=Release"
set "TARGET_ARCH=x86"
set "RUN_TESTS=1"

if /I "%~1"=="-h" goto :usage
if /I "%~1"=="--help" goto :usage

if not "%~1"=="" (
  if /I "%~1"=="Release" set "BUILD_TYPE=Release"
  if /I "%~1"=="Debug" set "BUILD_TYPE=Debug"
  if /I not "%~1"=="Release" if /I not "%~1"=="Debug" (
    echo [ERROR] Invalid build type "%~1".
    goto :usage_error
  )
)

if not "%~2"=="" (
  if /I "%~2"=="x86" set "TARGET_ARCH=x86"
  if /I "%~2"=="x64" set "TARGET_ARCH=x64"
  if /I not "%~2"=="x86" if /I not "%~2"=="x64" (
    echo [ERROR] Invalid arch "%~2".
    goto :usage_error
  )
)

if /I "%~3"=="--no-tests" set "RUN_TESTS=0"
if /I "%~4"=="--no-tests" set "RUN_TESTS=0"

set "SCRIPT_DIR=%~dp0"
pushd "%SCRIPT_DIR%" >nul
if errorlevel 1 (
  echo [ERROR] Unable to enter repository directory.
  exit /b 1
)

if /I "%TARGET_ARCH%"=="x86" (
  set "CONAN_ARCH=x86"
  set "CMAKE_ARCH=Win32"
) else (
  set "CONAN_ARCH=x86_64"
  set "CMAKE_ARCH=x64"
)

set "CONAN_CMD=conan"
where conan >nul 2>nul
if errorlevel 1 (
  echo [INFO] Conan not found. Attempting install via pip...
  where python >nul 2>nul
  if errorlevel 1 (
    echo [ERROR] python not found. Install Python 3.12+ and rerun.
    goto :fail
  )
  python -m pip install --disable-pip-version-check --user "conan==2.26.1"
  if errorlevel 1 (
    echo [ERROR] Failed to install Conan with pip.
    goto :fail
  )
  set "CONAN_CMD=python -m conan"
)

where cmake >nul 2>nul
if errorlevel 1 (
  echo [ERROR] cmake not found. Install CMake and rerun.
  goto :fail
)

echo [INFO] Build type: %BUILD_TYPE%
echo [INFO] Target arch: %TARGET_ARCH%
echo [INFO] Conan arch: %CONAN_ARCH%
echo [INFO] CMake arch: %CMAKE_ARCH%

call :run_cmd %CONAN_CMD% profile detect --force
if errorlevel 1 goto :fail

call :run_cmd %CONAN_CMD% install . --output-folder=conan --build=missing ^
  -s os=Windows ^
  -s arch=%CONAN_ARCH% ^
  -s compiler=msvc ^
  -s compiler.version=193 ^
  -s compiler.runtime=static ^
  -s compiler.runtime_type=%BUILD_TYPE% ^
  -s compiler.cppstd=17 ^
  -s build_type=%BUILD_TYPE%
if errorlevel 1 goto :fail

call :run_cmd cmake -S . -B build -G "Visual Studio 17 2022" -A %CMAKE_ARCH% ^
  "-DCMAKE_TOOLCHAIN_FILE=conan/conan_toolchain.cmake" ^
  "-DCMAKE_BUILD_TYPE=%BUILD_TYPE%"
if errorlevel 1 goto :fail

call :run_cmd cmake --build build --config %BUILD_TYPE% --target vSMR --parallel
if errorlevel 1 goto :fail

if "%RUN_TESTS%"=="1" (
  call :run_cmd ctest --test-dir build -C %BUILD_TYPE% --output-on-failure
  if errorlevel 1 goto :fail
)

echo [OK] Build complete.
if /I "%BUILD_TYPE%"=="Debug" (
  echo [OK] Output DLL: Debug\vSMR.dll
) else (
  echo [OK] Output DLL: Release\vSMR.dll
)

popd >nul
exit /b 0

:run_cmd
echo.
echo [CMD] %*
call %*
exit /b %errorlevel%

:usage_error
echo.
:usage
echo Usage: build-local.bat [Release^|Debug] [x86^|x64] [--no-tests]
echo Example: build-local.bat Release x86
echo Example: build-local.bat Debug x64 --no-tests
exit /b 2

:fail
echo [ERROR] Build script failed.
popd >nul
exit /b 1
