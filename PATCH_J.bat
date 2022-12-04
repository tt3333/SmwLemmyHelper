echo f | xcopy /y "smw_J.smc" "LemmyHelper_J.smc"
asar --symbols=wla -DVER_J LemmyHelper.asm LemmyHelper_J.smc

pause
