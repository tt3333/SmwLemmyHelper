echo f | xcopy /y "smw_U.smc" "LemmyHelper_U.smc"
asar --symbols=wla -DVER_U LemmyHelper.asm LemmyHelper_U.smc

pause
