sqlite3 = require 'sqlite3'
sqlite = require 'sqlite'
_ = require 'lodash'

srcomHelper = require './srcomHelper'

queries =
    createRuns: 
        """
            CREATE TABLE IF NOT EXISTS runs (
                userid TEXT NOT NULL,
                category TEXT NOT NULL,
                track TEXT NOT NULL,
                time TEXT NOT NULL,
                date TEXT NOT NULL,
                place INTEGER NOT NULL,
                PRIMARY KEY (userid, category, track, time, date)
            );
        """

    createUsers: 
        """
            CREATE TABLE IF NOT EXISTS users (
                userid TEXT NOT NULL,
                name TEXT NOT NULL,
                date TEXT NOT NULL,
                PRIMARY KEY (userid)
            );
        """

    createScores: 
        """
            CREATE TABLE IF NOT EXISTS scores (
                userid TEXT PRIMARY KEY NOT NULL,
                score INTEGER NOT NULL
            );
        """

    createFiles:
        """
            CREATE TABLE IF NOT EXISTS files (
                filename TEXT PRIMARY KEY NOT NULL,
                data BLOB NOT NULL
            );
        """

    getOneRunForILRanking:
        """
            SELECT runs.*, users.name FROM runs 
            INNER JOIN users ON users.userid = runs.userid
            WHERE
                category = :category
                AND track = :track
                AND lower(name) = lower(:name);
        """

    getOneRunForNewRuns: 
        """
            SELECT runs.*, users.name from runs
            INNER JOIN users ON users.userid = runs.userid
            WHERE
                track = :track
                AND category = :category
                AND time = :time
                AND lower(name) = lower(:name)
                AND date = :date;
        """

    insertRun:
        """
            REPLACE INTO runs (userid, category, track, time, date, place)
                VALUES (:userid, :category, :track, :time, :date, :place);
        """

    insertScore: 
        """
            INSERT INTO scores (userid, score)
                VALUES (:userid, :score);
        """

    getWRRuns: 
        """
            SELECT runs.*, users.name FROM runs
            INNER JOIN users ON users.userid = runs.userid
            WHERE place = 1;
        """

    getPointRankings: "SELECT data FROM files WHERE filename = 'PointRankings';"

    replacePointRankings:
        """
            REPLACE INTO files (filename, data) VALUES ('PointRankings', ?);
        """

    deleteAllRuns: "DELETE FROM runs;"

    deleteAllScores: "DELETE FROM scores;"

    getNumberOfRunsPerPlayer:
        """
            SELECT users.name, count(users.name) AS c
            FROM runs
            INNER JOIN users ON users.userid = runs.userid
            GROUP BY name
            ORDER BY c DESC;
        """

    getNewestRuns:
        """
            SELECT runs.*, users.name FROM runs
            INNER JOIN users ON users.userid = runs.userid
            ORDER BY date DESC LIMIT ?;
        """


getdb = do () ->
    db = null
    return () ->
        unless db?
            db = await sqlite.open(
                filename: './groovy.db'
                driver: sqlite3.Database
            )
            await db.exec(queries.createRuns)
            await db.exec(queries.createUsers)
            await db.exec(queries.createScores)
            await db.exec(queries.createFiles)
        db

addColons = (obj) ->
    _.fromPairs([":#{k}", v] for k, v of obj)

exports.insertRuns = (runs) ->
    db = await getdb()
    await Promise.all(db.run(queries.insertRun, addColons(run)) for run from runs)
    
exports.getNumberOfRunsPerPlayer = () ->
    db = await getdb()
    await db.all(queries.getNumberOfRunsPerPlayer)

exports.getNewestRuns = (numruns) ->
    db = await getdb()
    await db.all(queries.getNewestRuns, numruns)

exports.updateUserCache = (userids) ->
    db = await getdb()
    currentDate = new Date()
    userids = await db.all 'SELECT DISTINCT userid FROM runs'
    Promise.all(for userid from userids.map((x) => x.userid)
        do (userid) -> # this is needed or you get weird var-related misbehaviour
            db.get('SELECT date FROM users WHERE userid = ?', userid)
            .then((result) =>
                unless result? and (currentDate - new Date(result.date)) < 604800000 # 1 week in milliseconds
                    srcomHelper.getUsername(userid)
                    .then((name) => 
                        db.run(
                            'REPLACE INTO users (userid, name, date) VALUES (?, ?, ?)',
                            userid, name, currentDate.toJSON()
                        )
                    )
            )
    )

exports.getWRRuns = () ->
    db = await getdb()
    await db.all(queries.getWRRuns)