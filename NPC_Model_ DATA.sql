USE afw;
#This query is to get the information for missions happening in '2017-09-30' and '2019-09-30'
#Therefore, the date needs to be changed accordingly when implenmentation
/*-----------'2016-10-01' and '2019-09-30'--------------*/
with 
companion_weight as (select mission_id, coalesce(sum(weight),0) as weight
from companion c inner join mission_companion mc
on c.id = mc.companion_id inner join mission m
on mc.mission_id = m.id
group by mission_id ),

leg_count as (select mission_id, count(*) as leg_count from mission_leg ml group by mission_id),

distance as (select mission_id, ml.id as 'mission_leg_id' , sum(CAST((3437.848161706191 * ACOS((((COS(((PI() / 2) - RADIANS((90 - `fa`.`latitude`)))) * COS(((PI() / 2) - RADIANS((90 - `ta`.`latitude`))))) * COS((RADIANS(`fa`.`longitude`) - RADIANS(`ta`.`longitude`)))) + (SIN(((PI() / 2) - RADIANS((90 - `fa`.`latitude`)))) * SIN(((PI() / 2) - RADIANS((90 - `ta`.`latitude`)))))))) AS DECIMAL (4 , 0 ))) over(partition by mission_id) as 'total_distance',
CAST((3437.848161706191 * ACOS((((COS(((PI() / 2) - RADIANS((90 - `fa`.`latitude`)))) * COS(((PI() / 2) - RADIANS((90 - `ta`.`latitude`))))) * COS((RADIANS(`fa`.`longitude`) - RADIANS(`ta`.`longitude`)))) + (SIN(((PI() / 2) - RADIANS((90 - `fa`.`latitude`)))) * SIN(((PI() / 2) - RADIANS((90 - `ta`.`latitude`)))))))) AS DECIMAL (4 , 0 )) as 'leg_distance'
from mission_leg ml
left join airport fa
on fa.id=ml.from_airport_id
left join airport ta
on ta.id=ml.to_airport_id),

appt as (select afw.mission_request.id as mission_request_id, afw.mission_request.appt_time, case 
	when (time(afw.mission_request.appt_time) between ('05:00:00') and ('09:00:00')) then 'early'
	when (time(afw.mission_request.appt_time) between ('16:00:00') and ('24:00:00')) then 'late'
    when (time(afw.mission_request.appt_time) is null) then null
	else 'other' end as appt_time_type
from afw.mission_request),

companion_count as (SELECT m.id, mc.mission_id,count(companion_id)  as'companion_count'
FROM  mission m left join mission_companion mc 
on mc.mission_id = m.id
group by m.id ),

repeated_passenger as(SELECT m.passenger_id, MIN(m.mission_date) pax_first_mission_date
FROM mission_leg ml  
LEFT JOIN mission m on ml.mission_id = m.id
GROUP BY m.passenger_id),

pilot_info AS (SELECT pilot_id, 
		SUM(CASE WHEN cancelled = 'Pilot' THEN 1 ELSE 0 END) AS pilot_cancel_count, 
		(SUM(CASE WHEN cancelled = 'Pilot' THEN 1 ELSE 0 END))/COUNT(*) AS pilot_unreliable
FROM mission_leg ml
LEFT JOIN pilot p ON p.id = ml.pilot_id
GROUP BY ml.pilot_id)


############################ Select Variables #############################
SELECT ml.id as'mission_leg_id', 
case when ml.cancelled IS NULL then 0 else 1 end as 'cancelled',
ml.cancelled as 'type',

### passenger info ###
m.passenger_id as 'passenger_id',
FLOOR(datediff(mission_date, date_of_birth)/365) as'age', 
case when pax_first_mission_date = m.mission_date then 0 else 1 end as 'repeated_passenger',
pic.category_description AS 'illness',
companion_count, 
(ifnull(p.weight,0) + ifnull(cw.weight,0)+ ifnull(b_weight,0)) as 'total_weight',

### pilot info ###
pilot_id,
pilot_cancel_count, #the number missions that the pilot cancelled himself (cancelled = 'Pilot')
pilot_unreliable, #pilot_cancel_count/total number of missions that the pilot flew in the past


### mission_leg info ###
leg_count, 
appt.appt_time_type,
year(mission_date) as 'year',
mission_date, 
dayofweek(mission_date) as 'weekday_of_mission', #dayofweek sunday is 1
month(mission_date) as'month', 
datediff(mission_date, m.date_requested) as 'lead_time', 
case when month(mission_date) in (11,12,1,2,3,4) then 1 when month(mission_date) in (5,6,7,8,9,10) then 0  end as 'season', #winter is 1, summer is 0 
leg_distance, 
total_distance,

from_airport_id,
(select cluster from finalclusters_allairports where id = from_airport_id) as from_airport_cluster, 
(select runway_length from airport where id = from_airport_id) as from_runway_length, 
(select city from airport where id = from_airport_id) as 'f_city', 
(select latitude from airport where id = from_airport_id) as 'f_lat', 
(select longitude from airport where id = from_airport_id) as 'f_long', 
to_airport_id, 
(select cluster from finalclusters_allairports where id = to_airport_id) as to_airport_cluster, 
(select runway_length from airport where id = to_airport_id) as to_runway_length, 
(select city from airport where id = to_airport_id) as 't_city', 
(select latitude from airport where id = to_airport_id) as 't_lat', 
(select longitude from airport where id = to_airport_id) as 't_long', 


/*--------DEMAND/SUPPLY----*/
ifnull(xx.supply,0) as supply,
ifnull(xx.demand, 0) as demand,
#fill na as 9(should be infinite, but the largest ratio is 9, then 9 is reasonable)
ifnull(xx.supply/xx.demand, 9) as ratio


FROM mission_leg ml 
inner join mission m on m.id = ml.mission_id
left join pilot_info pi USING (pilot_id) 
left join leg_count lc on lc.mission_id = ml.mission_id
left join distance d on d.mission_leg_id = ml.id
left join passenger p on p.id = m.passenger_id
left join companion_weight cw on m.id = cw.mission_id
left join companion_count cc on m.id = cc.id
left join repeated_passenger rp on rp.passenger_id = p.id
left join passenger_illness_category pic on pic.id = p.passenger_illness_category_id
left join appt on appt.mission_request_id = m.request_id


/*--------DEMAND/SUPPLY----*/
#`0703demandsupply - 2019_apr-jun` is the name of SUPPLY/DEMAND table
LEFT JOIN `supplydemand201610-201909` xx ON xx.mission_leg_id = ml.id

#The following condition filter (1)mission_date (2)Normal or Compassion trips(exclude camp, etc) (3)exclude 'Data Entry Error'
#******************************************
where (mission_date between '2016-10-01' and '2019-09-30') 
#******************************************
and transportation = 'air_mission' and m.mission_type_id in (1,4)
AND ((cancelled <> 'Data Entry Error' AND cancelled <> 'Self') or cancelled is null); 


