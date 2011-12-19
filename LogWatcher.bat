@echo off
SET DESTINYPATH=G:\deploy\FSC-Destiny\jboss\server\destiny\log\serverlog.txt
SET CONFIGFILE=config.json
SET COFFEEHOME=node_modules\.bin\coffee.cmd
SET LOGWATCHERHOME=lib\LogWatcher.coffee
SET POLLHOME=lib\openPoll.coffee
START %COFFEEHOME% %LOGWATCHERHOME% %CONFIGFILE% %DESTINYPATH%
START %COFFEEHOME% %POLLHOME% %DESTINYPATH%