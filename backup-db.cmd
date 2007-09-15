@echo off
if not exist backups\*.* mkdir backups
set fn=backups\backup_%DATE:~10,4%%DATE:~7,2%%DATE:~4,2%_%TIME:~0,2%%TIME:~3,2%.sql
mysqldump -uroot ujudge_development >%fn%
echo %fn% created.


