USE afw;
/*--------------------------SUPPLY-------------------------*/
#SUPPLY is defined as the number of PILOTS (A)WITH EFFICIENCY HIGHER THAN 88% & (B)FLEW SUCCESSULLY AT LEAST 1 MISSION IN THE LAST YEAR
#(1) GET EFFICIENCY OF EACH PILOT FOR EACH MISSION_LEG
WITH EFFICIENCY AS(
SELECT 
        `ml`.`id` AS `mission_leg_id`,
        `pl`.`id` AS `pilot_id`,
        `member`.`external_id` AS `external_id`,
        `p`.`id` AS `personID`,
        `pl`.`primary_airport_id` AS `primary_airport_id`,
        #******************************************
        `member`.`flight_status` AS `flight_status`,
        #******************************************
        #`p`.`first_name` AS `first_name`,
        #`p`.`last_name` AS `last_name`,
        #`p`.`city` AS `city`,
        #`p`.`state` AS `state`,
        #`member`.`id` AS `memberID`,
        DATE_FORMAT(`member`.`join_date`, '%m-%d-%Y') AS `joinDate`,
                `pl`.`mop_regions_served` AS `mop_regions_served`,
        DATE_FORMAT(`pl`.`oriented_date`, '%m-%d-%Y') AS `dateOriented`,
        `m`.`mission_date` AS `mission_date`,
        #`hb`.`ident` AS `homeBase`,
        ((CAST((3437.848161706191 * ACOS((((COS(((PI() / 2) - RADIANS((90 - `hb`.`latitude`)))) * COS(((PI() / 2) - RADIANS((90 - `fa`.`latitude`))))) * COS((RADIANS(`hb`.`longitude`) - RADIANS(`fa`.`longitude`)))) + (SIN(((PI() / 2) - RADIANS((90 - `hb`.`latitude`)))) * SIN(((PI() / 2) - RADIANS((90 - `fa`.`latitude`))))))))
            AS DECIMAL (4 , 0 )) + CAST((3437.848161706191 * ACOS((((COS(((PI() / 2) - RADIANS((90 - `fa`.`latitude`)))) * COS(((PI() / 2) - RADIANS((90 - `ta`.`latitude`))))) * COS((RADIANS(`fa`.`longitude`) - RADIANS(`ta`.`longitude`)))) + (SIN(((PI() / 2) - RADIANS((90 - `fa`.`latitude`)))) * SIN(((PI() / 2) - RADIANS((90 - `ta`.`latitude`))))))))
            AS DECIMAL (4 , 0 ))) + CAST((3437.848161706191 * ACOS((((COS(((PI() / 2) - RADIANS((90 - `ta`.`latitude`)))) * COS(((PI() / 2) - RADIANS((90 - `hb`.`latitude`))))) * COS((RADIANS(`ta`.`longitude`) - RADIANS(`hb`.`longitude`)))) + (SIN(((PI() / 2) - RADIANS((90 - `ta`.`latitude`)))) * SIN(((PI() / 2) - RADIANS((90 - `hb`.`latitude`))))))))
            AS DECIMAL (4 , 0 ))) AS `trip_distance`,
        CAST((3437.848161706191 * ACOS((((COS(((PI() / 2) - RADIANS((90 - `fa`.`latitude`)))) * COS(((PI() / 2) - RADIANS((90 - `ta`.`latitude`))))) * COS((RADIANS(`fa`.`longitude`) - RADIANS(`ta`.`longitude`)))) + (SIN(((PI() / 2) - RADIANS((90 - `fa`.`latitude`)))) * SIN(((PI() / 2) - RADIANS((90 - `ta`.`latitude`))))))))
            AS DECIMAL (4 , 0 )) AS `leg_distance`,
        ((CAST((3437.848161706191 * ACOS((((COS(((PI() / 2) - RADIANS((90 - `fa`.`latitude`)))) * COS(((PI() / 2) - RADIANS((90 - `ta`.`latitude`))))) * COS((RADIANS(`fa`.`longitude`) - RADIANS(`ta`.`longitude`)))) + (SIN(((PI() / 2) - RADIANS((90 - `fa`.`latitude`)))) * SIN(((PI() / 2) - RADIANS((90 - `ta`.`latitude`))))))))
            AS DECIMAL (4 , 0 )) * 2) / ((CAST((3437.848161706191 * ACOS((((COS(((PI() / 2) - RADIANS((90 - `hb`.`latitude`)))) * COS(((PI() / 2) - RADIANS((90 - `fa`.`latitude`))))) * COS((RADIANS(`hb`.`longitude`) - RADIANS(`fa`.`longitude`)))) + (SIN(((PI() / 2) - RADIANS((90 - `hb`.`latitude`)))) * SIN(((PI() / 2) - RADIANS((90 - `fa`.`latitude`))))))))
            AS DECIMAL (4 , 0 )) + CAST((3437.848161706191 * ACOS((((COS(((PI() / 2) - RADIANS((90 - `fa`.`latitude`)))) * COS(((PI() / 2) - RADIANS((90 - `ta`.`latitude`))))) * COS((RADIANS(`fa`.`longitude`) - RADIANS(`ta`.`longitude`)))) + (SIN(((PI() / 2) - RADIANS((90 - `fa`.`latitude`)))) * SIN(((PI() / 2) - RADIANS((90 - `ta`.`latitude`))))))))
            AS DECIMAL (4 , 0 ))) + CAST((3437.848161706191 * ACOS((((COS(((PI() / 2) - RADIANS((90 - `ta`.`latitude`)))) * COS(((PI() / 2) - RADIANS((90 - `hb`.`latitude`))))) * COS((RADIANS(`ta`.`longitude`) - RADIANS(`hb`.`longitude`)))) + (SIN(((PI() / 2) - RADIANS((90 - `ta`.`latitude`)))) * SIN(((PI() / 2) - RADIANS((90 - `hb`.`latitude`))))))))
            AS DECIMAL (4 , 0 )))) AS `leg_efficiency`,
        CAST((3437.848161706191 * ACOS((((COS(((PI() / 2) - RADIANS((90 - `hb`.`latitude`)))) * COS(((PI() / 2) - RADIANS((90 - `fa`.`latitude`))))) * COS((RADIANS(`hb`.`longitude`) - RADIANS(`fa`.`longitude`)))) + (SIN(((PI() / 2) - RADIANS((90 - `hb`.`latitude`)))) * SIN(((PI() / 2) - RADIANS((90 - `fa`.`latitude`))))))))
            AS DECIMAL (4 , 0 )) AS `HbToOriginDistance`
    FROM
        (((((((`member`
        JOIN `person` `p` ON ((`member`.`person_id` = `p`.`id`)))
        JOIN `wing` ON ((`member`.`wing_id` = `wing`.`id`)))
        JOIN `pilot` `pl` ON ((`member`.`id` = `pl`.`member_id`)))
        JOIN `airport` `hb` ON ((`pl`.`primary_airport_id` = `hb`.`id`)))
        JOIN `pilot_stats` ON ((`pl`.`id` = `pilot_stats`.`pilot_id`)))
        LEFT JOIN `availability` `a` ON ((`member`.`id` = `a`.`member_id`)))
        JOIN ((`mission_leg` `ml`
        JOIN `airport` `fa` ON ((`ml`.`from_airport_id` = `fa`.`id`)))
        JOIN `airport` `ta` ON ((`ml`.`to_airport_id` = `ta`.`id`))))
        LEFT JOIN `mission` `m` ON `m`.`id` = `ml`.`mission_id`
    WHERE
        ((`member`.`active` = 1)
            AND (`hb`.`id` IS NOT NULL))
#When implementing, the following condition should be changed to "ml.id=xxxx"
	#******************************************
	AND mission_date between '2018-10-01' and '2019-09-30'
    #******************************************
    ),
#(2) fILTER PILOTS (A)WITH EFFICIENCY HIGHER THAN 88% & (B)FLEW SUCCESSULLY AT LEAST 1 MISSION IN THE LAST YEAR
PILOT_EFFICIENCY AS(
SELECT *
	FROM EFFICIENCY
    WHERE pilot_id in (
		select distinct ml.pilot_id
		from mission_leg ml inner join mission m
		on m.id=ml.mission_id inner join pilot p
		on p.id=ml.pilot_id  
		where transportation='air_mission'        
        and cancelled is null
		and camp_id is null
#The following condition needs to be changed accordingly to filter those who flew at least 1 mission in the last year
	#******************************************
    # include new pilots joined last year 
    and mission_date between '2018-10-01' and '2019-09-30'
    or joinDate between '2018-10-01' and '2019-09-30'
    #******************************************
    )
	AND leg_efficiency >= 0.88
#The following condition makes sure that pilots considered as supply are oriendted before the mission_date
	#******************************************	#AND dateOriented <= mission_date
	#determine if the member is a Command Pilot 
    AND flight_status = "Command Pilot"
    #******************************************
),
#(3) GET SUPPLY FOR EACH MISSION_LEG
SUPPLY AS (
SELECT 
	mission_leg_id,
	count(*) as supply
	FROM PILOT_EFFICIENCY
    GROUP BY mission_leg_id
    ),

/*--------------------------DEMAND-------------------------*/
#DEMAND is defined as how many competitive trips in the last 30 days for each mission_leg. 
#For each mission_leg, we first get the SUPPLY. Second, for each pilot in SUPPLY, we get his primary airport.
#Third, in the last three months, all mission_legs that origined or destinated at these airports are considered as DEMAND.

#(1) GET THE MISSSION_LEG_ID-PRIMARY_AIRPORT_ID PAIRS. The PRIMARY_AIRPORT_ID is where 88%-efficiency pilots base.
LEG_AIRPORT_PAIRS AS(
SELECT mission_leg_id, primary_airport_id, mission_date
FROM PILOT_EFFICIENCY
GROUP BY mission_leg_id, primary_airport_id),

#(2) GET MISSION_LEGS ORGIN OR DESTINATE AT A CERTAIN AIRPORT WITHIN 30 DAYS
DUMMY AS(
select d1.mission_leg_id, d1.primary_airport_id, ml1.id
from LEG_AIRPORT_PAIRS d1 
left join mission_leg ml1 on d1.primary_airport_id=ml1.from_airport_id 
left join mission m1 on ml1.mission_id=m1.id 
join EFFICIENCY on EFFICIENCY.mission_leg_id = d1.mission_leg_id
#******************************************
#consider routes that are 88% or higher efficient for the pilot instead of 100% efficient
#change the timeframe to 14 instead of 30
where (timestampdiff(day, m1.mission_date,d1.mission_date)<=14 and timestampdiff(day, m1.mission_date,d1.mission_date)>=0)
and leg_efficiency >= 0.88
#******************************************
union
select d2.mission_leg_id, d2.primary_airport_id, ml2.id
from LEG_AIRPORT_PAIRS d2 
left join mission_leg ml2 on d2.primary_airport_id=ml2.to_airport_id
left join mission m2 on ml2.mission_id=m2.id
join EFFICIENCY on EFFICIENCY.mission_leg_id = d2.mission_leg_id
#******************************************
#consider routes that are 88% or higher efficient for the pilot instead of 100% efficient
#change the timeframe to 14 instead of 30
where (timestampdiff(day, m2.mission_date,d2.mission_date)<=14 and timestampdiff(day, m2.mission_date,d2.mission_date)>=0)
and leg_efficiency >= 0.88
#******************************************
),
#---GET DEMAND---
DEMAND AS(
select mission_leg_id,
count(*) as demand
from DUMMY
group by mission_leg_id#,primary_airport_id
)
#---GET DEMAND & SUPPLY-----
SELECT S.mission_leg_id, demand, supply 
FROM DEMAND D
LEFT JOIN SUPPLY S ON D.mission_leg_id = S.mission_leg_id
UNION
SELECT S.mission_leg_id, demand, supply 
FROM DEMAND D
RIGHT JOIN SUPPLY S ON D.mission_leg_id = S.mission_leg_id;
