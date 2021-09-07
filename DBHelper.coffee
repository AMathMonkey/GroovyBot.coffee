sqlite3 = require 'sqlite3'
sqlite = require 'sqlite'
_ = require 'lodash'
fetch = require 'node-fetch'

queries =
    create_runs: 
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

    create_users: 
        """
            CREATE TABLE IF NOT EXISTS users (
                userid TEXT NOT NULL,
                name TEXT NOT NULL,
                date TEXT NOT NULL,
                PRIMARY KEY (userid)
            );
        """

    create_scores: 
        """
            CREATE TABLE IF NOT EXISTS scores (
                userid TEXT PRIMARY KEY NOT NULL,
                score INTEGER NOT NULL
            );
        """

    create_files:
        """
            CREATE TABLE IF NOT EXISTS files (
                filename TEXT PRIMARY KEY NOT NULL,
                data BLOB NOT NULL
            );
        """

    get_one_run_for_ilranking:
        """
            SELECT * FROM runs 
            INNER JOIN users ON users.userid = runs.userid
            WHERE
                category = :category
                AND track = :track
                AND lower(name) = lower(:name)
        """

    get_one_run_for_new_runs: 
        """
            SELECT * from runs
            INNER JOIN users ON users.userid = runs.userid
            WHERE
                track = :track
                AND category = :category
                AND time = :time
                AND lower(name) = lower(:name)
                AND date = :date
        """

    insert_run:
        """
            REPLACE INTO runs (userid, category, track, time, date, place)
                VALUES (:userid, :category, :track, :time, :date, :place)
        """

    insert_score: 
        """
            INSERT INTO scores (userid, score)
                VALUES (:userid, :score)
        """

    get_wr_runs: 
        """
            SELECT * FROM runs
            INNER JOIN users ON users.userid = runs.userid
            WHERE place = 1
        """

    get_point_rankings: "SELECT data FROM files WHERE filename = 'PointRankings'"

    replace_point_rankings:
        """
            REPLACE INTO files (filename, data) VALUES ('PointRankings', ?);
        """

    delete_all_runs: "DELETE FROM runs;"

    delete_all_scores: "DELETE FROM scores;"

    get_number_of_runs_per_player:
        """
            SELECT name, count(name) AS c
            FROM runs
            INNER JOIN users ON users.userid = runs.userid
            GROUP BY name
            ORDER BY c DESC;
        """

    get_newest_runs: (numruns) ->
        "SELECT * FROM runs ORDER BY date DESC LIMIT #{numruns}"


getdb = do () ->
    db = null
    return () ->
        unless db?
            db = await sqlite.open(
                filename: './groovy.db'
                driver: sqlite3.Database
            )
            await db.exec(queries.create_runs)
            await db.exec(queries.create_users)
            await db.exec(queries.create_scores)
            await db.exec(queries.create_files)
        db

add_colons = (obj) ->
    _.fromPairs([":#{k}", v] for k, v of obj)

class DBHelper
    insert_runs: (runs) ->
        db = await getdb()
        await Promise.all(db.run(queries.insert_run, add_colons(run)) for run from runs)
    
    get_number_of_runs_per_player: () ->
        db = await getdb()
        await db.all(queries.get_number_of_runs_per_player)

    update_user_cache: (runs) ->
        db = await getdb()
        currentDate = new Date()
        userqueries = for run from runs
            do (run) -> # this is needed or you get weird var-related misbehaviour
                db.get('SELECT date FROM users WHERE userid = ?', run.userid)
                .then((result) =>
                    unless result? and (currentDate - new Date(result.date)) < 604800000 # 1 week in milliseconds
                        fetch "https://www.speedrun.com/api/v1/users/#{run.userid}"
                        .then((response) => response.json())
                        .then((json) => json.data.names.international)
                        .then((name) => 
                            db.run(
                                'REPLACE INTO users (userid, name, date) VALUES (?, ?, ?)',
                                run.userid, name, currentDate.toJSON()
                            )
                        )
                )
        await Promise.all userqueries
            
        
module.exports = DBHelper
