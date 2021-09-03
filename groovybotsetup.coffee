sqlite3 = require 'sqlite3'
sqlite = require 'sqlite'

queries =
	create_runs: 
		"""
		    CREATE TABLE IF NOT EXISTS runs (
		        userid TEXT,
		        category TEXT,
		        track TEXT,
		        time TEXT,
		        date TEXT,
		        place INTEGER,
		        PRIMARY KEY (userid, category, track, time, date)
		    );
		"""

	create_users: 
		"""
		    CREATE TABLE IF NOT EXISTS users (
		        userid TEXT,
		        name TEXT,
		        PRIMARY KEY (userid)
		    );
		"""

	create_scores: 
		"""
		    CREATE TABLE IF NOT EXISTS scores (
		        userid TEXT PRIMARY KEY,
		        score INTEGER
		    );
		"""

	create_files:
		"""
		    CREATE TABLE IF NOT EXISTS files (
		        filename TEXT PRIMARY KEY,
		        data BLOB
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
		    INSERT INTO runs (userid, category, track, time, date, place)
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

db = do ->
	db = await sqlite.open(
		filename: './groovy.db'
		driver: sqlite3.Database
	)
	await db.exec(queries.create_runs)
	await db.exec(queries.create_users)
	await db.exec(queries.create_scores)
	await db.exec(queries.create_files)
	db

module.exports = 
	queries: queries
	db: db
