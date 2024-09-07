cd "$(dirname -- "$BASH_SOURCE")"
[[ -d build ]] && rm -rf build
coffee --compile --output build .
cd build
while true; do
    node groovybot.js |& tee -a log.txt
    echo "$(date -u): PROCESS ENDED, SLEEPING FOR 1 HOUR"
    sleep 1h # sleep and then try again after an hour if it exits 
done