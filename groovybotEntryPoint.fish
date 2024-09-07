cd (dirname (status --current-filename))
test -d build; and rm -rf build
coffee --compile --output build .
cd build
while true
    node groovybot.js &| tee -a log.txt
    echo (date -u)": PROCESS ENDED, SLEEPING FOR 1 HOUR"
    sleep 1h # sleep and then try again after an hour if it exits 
end
