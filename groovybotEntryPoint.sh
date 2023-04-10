cd "$(dirname -- "$BASH_SOURCE")"
while true; do
    coffee groovybot.coffee |& tee -a log.txt
    echo "$(date -u): PROCESS ENDED, SLEEPING FOR 1 HOUR"
    sleep 1h # sleep and then try again after an hour if it exits 
done