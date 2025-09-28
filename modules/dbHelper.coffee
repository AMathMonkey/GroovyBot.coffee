import Database from 'better-sqlite3'

import * as srcomHelper from './srcomHelper.js'
import * as utilities from './utilities.js'

db = new Database('./groovy.db')
db.pragma 'journal_mode = WAL'

queries =
    createRuns: db.prepare "
        CREATE TABLE IF NOT EXISTS runs (
            userid TEXT NOT NULL,
            category TEXT NOT NULL,
            track TEXT NOT NULL,
            time TEXT NOT NULL,
            date TEXT NOT NULL,
            PRIMARY KEY (userid, category, track)
        )
    "

    createUsers: db.prepare "
        CREATE TABLE IF NOT EXISTS users (
            userid TEXT NOT NULL,
            name TEXT NOT NULL,
            date TEXT NOT NULL,
            PRIMARY KEY (userid)
        )
    "

    createScores: db.prepare "
        CREATE TABLE IF NOT EXISTS scores (
            userid TEXT PRIMARY KEY NOT NULL,
            score INTEGER NOT NULL
        )
    "

    createFiles: db.prepare "
        CREATE TABLE IF NOT EXISTS files (
            filename TEXT PRIMARY KEY NOT NULL,
            data BLOB NOT NULL
        )
    "

    createRunsView: db.prepare "
        CREATE VIEW IF NOT EXISTS runsView
        AS
        SELECT runs.*, users.name, RANK() OVER(PARTITION BY category, track ORDER BY time) AS place FROM runs
        JOIN users USING(userid)
    "

    getOneRunForILRanking: db.prepare "
        SELECT * from runsView
        WHERE
            category = @category
            AND track = @track
            AND name LIKE @name
    "

    getOneRunForNewRuns: db.prepare "
        SELECT * FROM runsView
        WHERE
            track = @track
            AND category = @category
            AND time = @time
            AND userid = @userid
            AND date = @date
    "

    getAllRuns: db.prepare "SELECT * from runsView"

    getLongestStandingWRRuns: db.prepare "
        SELECT *, FLOOR(JULIANDAY('now') - JULIANDAY(date)) AS age
        FROM runsView WHERE place = 1 ORDER BY date
    "

    getNumberOfRunsPerPlayer: db.prepare "
        SELECT name, COUNT(name) AS count
        FROM runsView
        GROUP BY name
        ORDER BY count DESC
    "

    getNewestRuns: db.prepare "SELECT * from runsView ORDER BY date DESC LIMIT ?"
    
    getAllScores: db.prepare "
        SELECT
            users.name,
            scores.score,
            RANK() OVER (ORDER BY scores.score DESC) AS pos
        FROM scores
        JOIN users USING(userid)
    "

    getPointRankings: db.prepare "SELECT * FROM files WHERE filename = 'pointrankings'"

    replacePointRankings: 
        db.prepare "REPLACE INTO files (filename, data) VALUES ('pointrankings', ?)"

    getRunsForUser: db.prepare "SELECT * FROM runsView WHERE name LIKE ?"

do queries[query].run for query in ['createRuns', 'createUsers', 'createScores', 'createFiles', 'createRunsView']

createVirtualRunTable = (runs) ->
    db.table 'virtualRunTable', 
        columns: ['userid', 'category', 'track', 'time', 'date']
        rows: -> yield from runs

updateScores = ->
    reducer = (acc, run) -> {
        acc...
        [run.userid]: (acc[run.userid] ? 0) + utilities.calcScore run.place
    }
    scores = (do getAllRuns).reduce reducer, {}
    db.table 'virtualScoreTable', 
        columns: ['userid', 'score']
        rows: -> yield { userid, score } for userid, score of scores; return
    do (db.prepare "REPLACE INTO scores SELECT * FROM virtualScoreTable").run
    return

export insertRuns = db.transaction (runs) ->
    createVirtualRunTable runs
    do (db.prepare "REPLACE INTO runs SELECT * FROM virtualRunTable").run
    do updateScores
    return
    
export deleteRuns = db.transaction (runs) ->
    createVirtualRunTable runs
    do (db.prepare "DELETE FROM runs WHERE (userid, category, track) IN (SELECT userid, category, track FROM virtualRunTable)").run
    do updateScores
    return

export getNumberOfRunsPerPlayer = -> do queries.getNumberOfRunsPerPlayer.all

export getNewestRuns = (numruns) -> queries.getNewestRuns.all numruns

export updateUserCache = (runs) ->
    db.table 'virtualUseridTable', 
        columns: ['userid']
        rows: -> yield { userid } for { userid } in runs; return
    uncached = do (db.prepare "SELECT DISTINCT userid FROM virtualUseridTable LEFT JOIN users USING(userid) WHERE date IS NULL OR JULIANDAY('now') - JULIANDAY(date) >= 7").all
    updates = await Promise.all ({ userid, name: await srcomHelper.getUsername userid } for { userid } in uncached)
    db.table 'virtualUseridTable',
        columns: ['userid', 'name']
        rows: -> yield from updates; return 
    do (db.prepare "REPLACE INTO users SELECT *, DATETIME('now') FROM virtualUseridTable").run

export getLongestStandingWRRuns = -> do queries.getLongestStandingWRRuns.all 

export getAllRuns = -> do queries.getAllRuns.all 

export getScores = -> do queries.getAllScores.all 

export getTable = -> (do queries.getPointRankings.get)?.data

export saveTable = (tableString) -> queries.replacePointRankings.run tableString

export getOneRunForILRanking = (query) -> queries.getOneRunForILRanking.get query

export findNewRuns = (allRunsFromSRC) ->
    createVirtualRunTable allRunsFromSRC
    do (db.prepare "SELECT * FROM virtualRunTable EXCEPT SELECT * FROM runs").all

export findDeletedRuns = (allRunsFromSRC) ->
    createVirtualRunTable allRunsFromSRC
    do (db.prepare "SELECT * FROM runs WHERE (userid, category, track) NOT IN (SELECT userid, category, track FROM virtualRunTable)").all

export getRunsWithPositions = (runs) -> 
    createVirtualRunTable runs
    do (db.prepare "SELECT * FROM runsView WHERE (userid, category, track) in (SELECT userid, category, track FROM virtualRunTable)").all

export getRunsForUser = (name) -> queries.getRunsForUser.all name
