import sqlite3 from 'sqlite3'
import { open } from 'sqlite'

import * as srcomHelper from './srcomHelper.js'
import * as utilities from './utilities.js'

queries =
    createRuns: "
        CREATE TABLE IF NOT EXISTS runs (
            userid TEXT NOT NULL,
            category TEXT NOT NULL,
            track TEXT NOT NULL,
            time TEXT NOT NULL,
            date TEXT NOT NULL,
            PRIMARY KEY (userid, category, track)
        )
    "

    createUsers: "
        CREATE TABLE IF NOT EXISTS users (
            userid TEXT NOT NULL,
            name TEXT NOT NULL,
            date TEXT NOT NULL,
            PRIMARY KEY (userid)
        )
    "

    createScores: "
        CREATE TABLE IF NOT EXISTS scores (
            userid TEXT PRIMARY KEY NOT NULL,
            score INTEGER NOT NULL
        )
    "

    createFiles: "
        CREATE TABLE IF NOT EXISTS files (
            filename TEXT PRIMARY KEY NOT NULL,
            data BLOB NOT NULL
        )
    "

    createRunsView: "
        CREATE VIEW IF NOT EXISTS runsView
        AS
        SELECT runs.*, users.name, RANK() OVER(PARTITION BY category, track ORDER BY time) AS place FROM runs
        INNER JOIN users USING(userid)
    "

    getOneRunForILRanking: "
        SELECT * from runsView
        WHERE
            category = :category
            AND track = :track
            AND lower(name) = :name
    "

    getOneRunForNewRuns: "
        SELECT * FROM runs
        WHERE
            track = :track
            AND category = :category
            AND time = :time
            AND userid = :userid
            AND date = :date
    "

    getAllRuns: "SELECT * from runsView"

    insertRun: "
        REPLACE INTO runs (userid, category, track, time, date)
            VALUES (:userid, :category, :track, :time, :date)
    "

    insertScore: "
        INSERT INTO scores (userid, score)
            VALUES (:userid, :score)
    "

    getLongestStandingWRRuns: "
        SELECT *, FLOOR(JULIANDAY('now') - JULIANDAY(date)) AS age
        FROM runsView WHERE place = 1 ORDER BY date
    "

    deleteAllRuns: "DELETE FROM runs"

    getNumberOfRunsPerPlayer: "
        SELECT name, count(name) AS count
        FROM runsView
        GROUP BY name
        ORDER BY count DESC
    "

    getNewestRuns: "SELECT * from runsView ORDER BY date DESC LIMIT ?"
    
    replacePointRankings: 
        "REPLACE INTO files (filename, data) VALUES ('pointrankings', ?)"

    getNameByUserId: 'SELECT name FROM users WHERE userid = ?'

    updateUser: "REPLACE INTO users (userid, name, date) VALUES (?, ?, DATETIME('now'))"

    updateScore: "REPLACE INTO scores (userid, score) VALUES (?, ?)"

    getAllScores: "
        SELECT
            users.name,
            scores.score,
            RANK() OVER (ORDER BY scores.score DESC) AS pos
        FROM scores
        INNER JOIN users USING(userid)
    "

    isUsernameCached: "
        SELECT EXISTS(
            SELECT date FROM users WHERE userid = ?
                AND JULIANDAY('now') - JULIANDAY(date) < 7
        ) as isCached
    "

    getPointRankings: "SELECT * FROM files WHERE filename = 'pointrankings'"

db = await open
    filename: './groovy.db'
    driver: sqlite3.Database
for query in ['createRuns', 'createUsers', 'createScores', 'createFiles', 'createRunsView']
    await db.run queries[query]

objToNamedQueryParameters = (obj, fieldsToUse) ->
    s = new Set fieldsToUse
    Object.fromEntries ([":#{k}", v] for k, v of obj when s.has k)

export insertRuns = (runs) ->
    Promise.all(for run in runs
        db.run \
            queries.insertRun,
            objToNamedQueryParameters run, ["userid", "category", "track", "time", "date"])

export runInDB = (run) ->
    result = await db.get \
        queries.getOneRunForNewRuns,
        objToNamedQueryParameters(run, ["userid", "category", "track", "time", "date"]),
    result?
    
export getNumberOfRunsPerPlayer = -> db.all queries.getNumberOfRunsPerPlayer

export getNewestRuns = (numruns) -> db.all queries.getNewestRuns, numruns

export getRunsWithUsernames = (runs) ->
    {
        run...
        (await db.get queries.getNameByUserId, run.userid)...
    } for run in runs

export updateUserCache = (runs) ->
    userids = new Set(run.userid for run in runs)
    Promise.all(for userid from userids
        do (userid) -> # this is needed or you get weird var-related misbehaviour
            result = await db.get queries.isUsernameCached, userid
            unless result.isCached
                name = await srcomHelper.getUsername userid
                db.run queries.updateUser, userid, name)

export getLongestStandingWRRuns = -> db.all queries.getLongestStandingWRRuns

export getAllRuns = -> db.all queries.getAllRuns

export updateScores = ->
    result = (await do getAllRuns).reduce \
        ((acc, run) -> {
            acc...,
            [run.userid]: (acc[run.userid] ? 0) + utilities.calcScore run.place
        }),
        {},
    
    Promise.all(for userid, score of result
        db.run queries.updateScore, userid, score)

export getScores = -> db.all queries.getAllScores

export getPointRankings = -> (await db.get queries.getPointRankings)?.data

export saveTable = (tableString) -> db.run queries.replacePointRankings, tableString

export getOneRunForILRanking = (query) -> 
    db.get queries.getOneRunForILRanking, objToNamedQueryParameters query, ['track', 'category', 'name']

export getNewRunsString = (runs) ->
    (for run in runs
        if await runInDB run then continue
        else "New run! #{run.track} - #{run.category} in #{run.time} by #{run.name}")
    .join '\n'
