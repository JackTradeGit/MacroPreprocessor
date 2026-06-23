REM Generate 'Compare' files for tests
REM processing-java.exe --sketch=%~dp0 --run --force-test --self-test

REM Run tests, using 'Compare' files to check outputs
processing-java.exe --sketch=%~dp0 --run --self-test