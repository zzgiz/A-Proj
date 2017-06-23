@echo off
set dt=%date:/=%%time: =0%
set dt=%dt:~0,4%%dt:~4,2%%dt:~6,2%_%dt:~8,2%%dt:~11,2%%dt:~14,2%
mkdir _backup\%dt%
copy *.sql _backup\%dt%
