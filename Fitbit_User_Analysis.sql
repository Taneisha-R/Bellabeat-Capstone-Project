-- CAPSTONE PROJECT FOR THE GOOGLE ANALYTICS CERTIFICATE THROUGH COURSERA.
-- OBJECTIVE: ANALYZE FITBIT USER DATA TO PROVIDE RECOMMENDATIONS FOR BELLABEAT'S MARKETING STRATEGY.

-- I used Google Sheets and MySQL to process and analyze the data. 
-- I used Tableau to share insights and provide recommendations.

-- 1. Create the Bellabeats database in MySQL
CREATE DATABASE bellabeats;

-- 2. Use Google Sheets to update all datetime columns to YYYY-MM-DD HH:MM:SS format
-- 3. Upload necessary data files using data import wizard. Tables used include:
		/* 	daily_Activity_merged
			hourlyCalories_merged
            hourlySteps_merged
            sleepDay_merged
            weightLogInfo_merged */

-- 4. Determine which measurements are used the most (steps, sleep, or weight) 

-- Create a table for each measurement and then combine them.
CREATE TABLE step_records AS
SELECT id, COUNT(totalsteps) AS step_records 
FROM bellabeats.daily_activity
WHERE totalsteps <> 0 -- Entries where total steps = 0 potentially indicate days where the user did not wear the device
GROUP BY id

CREATE TABLE sleep_records AS
SELECT id, SUM(totalsleeprecords) AS sleep_rrecords
FROM bellabeats.sleep
GROUP BY id

CREATE TABLE weight_records AS
SELECT id, COUNT(weightkg) AS weight_records 
FROM bellabeats.weight
GROUP BY id

SELECT 
	step_records.id, 
    step_records.step_records,
    sleep_records.sleep_records,
    weight_records.weight_records
FROM step_records
LEFT JOIN sleep_records ON step_records.id = sleep_records.id
LEFT JOIN weight_records ON sleep_records.id = weight_records.id
UNION
SELECT 
	step_records.id, 
    step_records.step_records,
    sleep_records.sleep_records,
    weight_records.weight_records
FROM step_records
RIGHT JOIN sleep_records ON step_records.id = sleep_records.id
RIGHT JOIN weight_records ON sleep_records.id = weight_records.id
WHERE step_records.id IS NULL -- Save table for visualizations

-- 5. Determine the days of the week that users are most active
 
-- Add day of the week column to daily_activity table
ALTER TABLE daily_activity
ADD COLUMN day_of_week VARCHAR(9)

UPDATE daily_activity
SET day_of_week = DAYNAME(activitydate)

-- Calculate average steps, calories, and distance per day
SELECT 
	day_of_week,
    AVG(totalsteps) AS avg_steps,
    AVG(totaldistance) AS avg_distance,
    AVG(calories) AS avg_calories
FROM daily_activity
WHERE totalsteps <> 0
GROUP BY day_of_week -- Save table for visualizations

-- Calculate average active minutes per day
SELECT
	day_of_week,
    AVG(veryactiveminutes) AS very_active,
    AVG(fairlyactiveminutes) AS fairly_active,
    AVG(lightlyactiveminutes) AS lightly_active,
    AVG(sedentaryminutes) AS not_active
FROM daily_activity
WHERE totalsteps <> 0
GROUP BY day_of_week

-- 6. Determine the time of day that users are most active
SELECT
	DATE_FORMAT(hc.activityhour, '%H:00:00') AS hour_of_day,
    AVG(hc.calories) AS avg_calories,
    AVG(hs.steptotal) AS avg_steps
FROM bellabeats.hourly_calories hc
JOIN bellabeats.hourly_steps hs 
	ON hc.id = hs.id 
    AND hc.activityhour = hs.activityhour
WHERE hs.steptotal <> 0
GROUP BY hour_of_day
ORDER BY hour_of_day -- Save table for visualizations

-- 7. Determine the average difference between sleep time and time in bed per day

SELECT COUNT(id)
FROM sleep_records -- 24 users utilized the sleep measurement

-- Add day of week to sleep table
ALTER TABLE sleep
ADD COLUMN day_of_week VARCHAR(9)

UPDATE sleep
SET day_of_week = DAYNAME(sleepday)

SELECT
	day_of_week,
    AVG(totaltimeinbed - TotalMinutesAsleep) AS avg_idle_in_bed
FROM bellabeats.sleep
GROUP BY day_of_week -- Save table for visualizations

-- 8. Determine the activity level of users in the sample size

-- Confirm whether active minutes are recorded for all minutes in a day
SELECT 
	id,
    activitydate, 
	total_mins_recorded,
    (24 * 60) - total_mins_recorded AS time_not_recorded
 FROM (
	SELECT
		id,
        activitydate,
        (veryactiveminutes + fairlyactiveminutes + lightlyactiveminutes + sedentaryminutes) AS total_mins_recorded
	FROM bellabeats.daily_activity
) AS mins_recorded_table -- Save table for visualizations

-- Previous query determines that time is not recorded for all minutes in the day for each user
-- This indicates that some users do not wear the device all day
-- Therefore activity level will be based on total minutes recorded

SELECT
	id,
    SUM(veryactiveminutes) / SUM(veryactiveminutes + fairlyactiveminutes + lightlyactiveminutes + sedentaryminutes) * 100  AS very_active_perc,
    SUM(fairlyactiveminutes) / SUM(veryactiveminutes + fairlyactiveminutes + lightlyactiveminutes + sedentaryminutes) * 100  AS fairly_active_perc,
    SUM(lightlyactiveminutes) / SUM(veryactiveminutes + fairlyactiveminutes + lightlyactiveminutes + sedentaryminutes) * 100 AS lightly_active_perc,
    SUM(sedentaryminutes) / SUM(veryactiveminutes + fairlyactiveminutes + lightlyactiveminutes + sedentaryminutes) * 100 AS not_active_perc
FROM daily_activity
WHERE totalsteps <> 0
GROUP BY id -- Save table for visualizations

    

