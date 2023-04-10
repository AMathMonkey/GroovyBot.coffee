sqlite3 = require 'sqlite3'
sqlite = require 'sqlite'

srcomHelper = require './srcomHelper'
utilities = require './utilities'

queries = {
    createRuns: """
        CREATE TABLE IF NOT EXISTS runs (
            userid TEXT NOT NULL,
            category TEXT NOT NULL,
            track TEXT NOT NULL,
            time TEXT NOT NULL,
            date TEXT NOT NULL,
            place INTEGER NOT NULL,
            PRIMARY KEY (userid, category, track, time, date)
        )
    """

    createUsers: """
        CREATE TABLE IF NOT EXISTS users (
            userid TEXT NOT NULL,
            name TEXT NOT NULL,
            date TEXT NOT NULL,
            PRIMARY KEY (userid)
        )
    """

    createScores: """
        CREATE TABLE IF NOT EXISTS scores (
            userid TEXT PRIMARY KEY NOT NULL,
            score INTEGER NOT NULL
        )
    """

    createFiles: """
        CREATE TABLE IF NOT EXISTS files (
            filename TEXT PRIMARY KEY NOT NULL,
            data BLOB NOT NULL
        )
    """

    createRunsView: """
        CREATE VIEW IF NOT EXISTS runsView
        AS
        SELECT runs.*, users.name FROM runs
        INNER JOIN users USING(userid)
    """

    getOneRunForILRanking: """
        SELECT * from runsView
        WHERE
            category = :category
            AND track = :track
            AND lower(name) = :name
    """

    getOneRunForNewRuns: """
        SELECT * FROM runs
        WHERE
            track = :track
            AND category = :category
            AND time = :time
            AND userid = :userid
            AND date = :date
    """

    getAllRuns: "SELECT * from runsView"

    insertRun: """
        REPLACE INTO runs (userid, category, track, time, date, place)
            VALUES (:userid, :category, :track, :time, :date, :place)
    """

    insertScore: """
        INSERT INTO scores (userid, score)
            VALUES (:userid, :score)
    """

    getLongestStandingWRRuns: """
        SELECT *, FLOOR(JULIANDAY('now') - JULIANDAY(date)) AS age
        FROM runsView WHERE place = 1 ORDER BY date
    """

    deleteAllRuns: "DELETE FROM runs"

    getNumberOfRunsPerPlayer: """
        SELECT name, count(name) AS c
        FROM runsView
        GROUP BY name
        ORDER BY c DESC
    """

    getNewestRuns: "SELECT * from runsView ORDER BY date DESC LIMIT ?"
    
    replacePointRankings: 
        "REPLACE INTO files (filename, data) VALUES ('pointrankings', ?)"

    getNameByUserId: 'SELECT name FROM users WHERE userid = ?'

    updateUser: "REPLACE INTO users (userid, name, date) VALUES (?, ?, DATETIME('now'))"

    updateScore: "REPLACE INTO scores (userid, score) VALUES (?, ?)"

    getAllScores: """
        SELECT
            users.name,
            scores.score,
            RANK() OVER (ORDER BY scores.score DESC) AS pos
        FROM scores
        INNER JOIN users USING(userid)
    """

    isUsernameCached: """
        SELECT EXISTS(
            SELECT date FROM users WHERE userid = ?
                AND JULIANDAY('now') - JULIANDAY(date) < 7
        ) as isCached
    """

    getPointRankings: "SELECT * FROM files WHERE filename = 'pointrankings'"
}

getdb = do ->
    db = null
    return ->
        unless db?
            db = await sqlite.open({
                filename: './groovy.db'
                driver: sqlite3.Database
            })
            for query in ["createRuns", "createUsers", "createScores", "createFiles", "createRunsView"]
                await db.run(queries[query])
        db

objToDBQueryParam = (obj, arr) ->
    s = new Set arr
    Object.fromEntries([":#{k}", v] for k, v of obj when s.has(k))

exports.insertRuns = (runs) ->
    db = await getdb()
    await db.run(queries.deleteAllRuns)
    Promise.all(
        db.run(
            queries.insertRun
            objToDBQueryParam(run, ["userid", "category", "track", "time", "date", "place"])
        ) for run in runs
    )

exports.runInDB = (run) ->
    db = await getdb()
    result = await db.get(
        queries.getOneRunForNewRuns
        objToDBQueryParam(run, ["userid", "category", "track", "time", "date"])
    )
    result?
    
exports.getNumberOfRunsPerPlayer = ->
    db = await getdb()
    db.all(queries.getNumberOfRunsPerPlayer)

exports.getNewestRuns = (numruns) ->
    db = await getdb()
    db.all(queries.getNewestRuns, numruns)

exports.getRunsWithUsernames = (runs) ->
    db = await getdb()
    {
        run...
        (await db.get(queries.getNameByUserId, run.userid))...
    } for run in runs

exports.updateUserCache = (runs) ->
    db = await getdb()
    userids = [new Set(run.userid for run in runs)...]
    Promise.all(for userid in userids
        do (userid) -> # this is needed or you get weird var-related misbehaviour
            db.get(queries.isUsernameCached, userid).then((result) ->
                unless result.isCached
                    srcomHelper.getUsername(userid).then((name) ->
                        db.run(queries.updateUser, userid, name)
                    )
            )
    )

exports.getLongestStandingWRRuns = ->
    db = await getdb()
    db.all(queries.getLongestStandingWRRuns)

exports.getAllRuns = ->
    db = await getdb()
    db.all(queries.getAllRuns)

exports.updateScores = ->
    db = await getdb()
    runs = await @getAllRuns()

    result = {}
    for run in runs
        result[run.userid] ?= 0
        result[run.userid] += utilities.calcScore(run.place)

    Promise.all(for userid, score of result
        db.run(queries.updateScore, userid, score)
    )

exports.getScores = ->
    db = await getdb()
    db.all(queries.getAllScores)

exports.getPointRankings = ->
    db = await getdb()
    db.get(queries.getPointRankings)
        .then((obj) -> obj?.data)

exports.saveTable = (tableString) ->
    db = await getdb()
    db.run(queries.replacePointRankings, tableString)

exports.getOneRunForILRanking = (query) ->
    db = await getdb()
    db.get(queries.getOneRunForILRanking, objToDBQueryParam(query, ["track", "category", "name"]))

exports.getNewRunsString = (runs) ->
    (for run in runs
        runInDB = await @runInDB run
        if runInDB then continue
        else "New run! #{run.track} - #{run.category} in #{utilities.formatTime(run.time)} by #{run.name}")
    .join('\n')