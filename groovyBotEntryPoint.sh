cd "$(dirname -- "$BASH_SOURCE")"
while ! coffee groovybot.coffee | tee -a log.txt; do sleep 1h; done