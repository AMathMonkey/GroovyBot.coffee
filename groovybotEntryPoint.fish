cd (status --current-filename)
while true
    coffee groovybot.coffee >> log.txt 2>&1
    echo (date -u)": PROCESS ENDED, SLEEPING FOR 1 HOUR"
    sleep 1h # sleep and then try again after an hour if it exits 
end