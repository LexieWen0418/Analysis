
**************************************************************
**************************************************************
**************************************************************

- What month and year did they join Healthcasts?
- - first magic link clicked on docdx


SELECT month, count(*) FROM (
SELECT user_id, EXTRACT(MONTH FROM min(used_at)) as month FROM private.magic_link
WHERE used_at IS NOT NULL 
GROUP BY user_id ) A
GROUP BY month


**************************************************************
**************************************************************
**************************************************************

Since January 2019, how many users logged back into docdx 
or old app a second time after their first login by month?


Average number of monthly logins -use magic_link 

SELECT extract(month from used_at) as Month, spe.name spe, count(distinct m.user_id) FROM private.magic_link m
JOIN public."user_profile" up
ON m.user_id = up.user_id
JOIN specialty spe
ON spe.id = up.specialty_id
JOIN subspecialty sub
ON sub.id = up.subspecialty_id 
where m.used_at is not null 
group by Month, spe.name



SELECT extract(month from used_at) as Month, sub.name subspe, count(distinct m.user_id) FROM private.magic_link m
JOIN public."user_profile" up
ON m.user_id = up.user_id
JOIN specialty spe
ON spe.id = up.specialty_id
JOIN subspecialty sub
ON sub.id = up.subspecialty_id 
where m.used_at is not null 
group by Month, sub.name



**************************************************************
**************************************************************
**************************************************************

Average number of questions viewed

#not distinct case - spe 

select A.spe, round(avg(A.count),2) FROM
(SELECT t.user_id, spe.name spe, count(distinct t.topic_id) FROM topic_view t
JOIN public."user_profile" up
ON t.user_id = up.user_id
JOIN specialty spe
ON spe.id = up.specialty_id
JOIN subspecialty sub
ON sub.id = up.subspecialty_id 
group by t.user_id, spe.name) A
group by A.spe --, sub.name sub.name subspe, 


#distinct case - spe

select A.spe, round(avg(A.count),2) avg_tv FROM
(SELECT t.user_id, spe.name spe, count(t.topic_id) FROM topic_view t
JOIN public."user_profile" up
ON t.user_id = up.user_id
JOIN specialty spe
ON spe.id = up.specialty_id
JOIN subspecialty sub
ON sub.id = up.subspecialty_id 
group by t.user_id, spe.name) A
group by A.spe --, sub.name sub.name subspe, 
order by avg_tv desc 


**************************************************************
**************************************************************
**************************************************************


Average number of answers posted
- 1 cycle sun-sat


--spe version 
select spe, round(avg(avg_ans),2) avg_ans_spe from (
select created_by, spe, subspe, avg(count_ans) avg_ans from (	
select c.created_by, spe.name spe, sub.name subspe,
date_trunc('week', c.created_at::date)::date AS weekly,
count(c.topic_id) count_ans
from comment c
JOIN public."user_profile" up
ON c.created_by = up.user_id
JOIN specialty spe
ON spe.id = up.specialty_id
JOIN subspecialty sub
ON sub.id = up.subspecialty_id 
group by c.created_by, spe, subspe, weekly
order by created_by) A
group by created_by, spe, subspe ) B
group by spe 
order by avg_ans_spe desc


-- sub spe 
select subspe, round(avg(avg_ans),2) avg_ans_subspe from (
select created_by, spe, subspe, avg(count_ans) avg_ans from (	
select c.created_by, spe.name spe, sub.name subspe,
date_trunc('week', c.created_at::date)::date AS weekly,
count(c.topic_id) count_ans
from comment c
JOIN public."user_profile" up
ON c.created_by = up.user_id
JOIN specialty spe
ON spe.id = up.specialty_id
JOIN subspecialty sub
ON sub.id = up.subspecialty_id 
group by c.created_by, spe, subspe, weekly
order by created_by) A
group by created_by, spe, subspe
order by spe) B
group by subspe 
order by avg_ans_subspe desc


**************************************************************
**************************************************************
**************************************************************

What types of questions 
(eg. Questions about treatment, pharma drugs, illnesses, etc.) did they view and answer most frequently?

- by specialty 

--user_id/topic_spe/view_count
with user_topic_count as (select user_id, topic_spe, count(*) view_count from (
SELECT t.user_id, t.topic_id, spe.name topic_spe FROM topic_view t
join topic_specialty t_spe
on t_spe.topic_id = t.topic_id
join specialty spe
on spe.id = t_spe.specialty_id) A
group by user_id, topic_spe
order by user_id )

select user_spe, topic_spe, round(avg(view_count),2) from(
select uc.*, spe.name user_spe, sub.name user_sub_spe
	from user_topic_count uc
JOIN public."user_profile" up
ON uc.user_id = up.user_id
JOIN specialty spe
ON spe.id = up.specialty_id
JOIN subspecialty sub
ON sub.id = up.subspecialty_id) B
group by user_spe, topic_spe
order by user_spe, topic_spe


- by comment 

--user_id/topic_spe/view_count
with user_topic_count as (select user_id, topic_spe, count(*) ans_count from (
SELECT c.created_by user_id, c.topic_id, spe.name topic_spe FROM comment c
join topic_specialty t_spe
on t_spe.topic_id = c.topic_id
join specialty spe
on spe.id = t_spe.specialty_id) A
group by user_id, topic_spe
order by user_id )

select user_spe, topic_spe, round(avg(ans_count),2) from(
select uc.*, spe.name user_spe, sub.name user_sub_spe
	from user_topic_count uc
JOIN public."user_profile" up
ON uc.user_id = up.user_id
JOIN specialty spe
ON spe.id = up.specialty_id
JOIN subspecialty sub
ON sub.id = up.subspecialty_id) B
group by user_spe, topic_spe
order by user_spe, topic_spe


---user whoever comment/with their spe/subspe and npi 

select distinct c.created_by, spe.name, sub.name, up.npi
	from comment c
		JOIN public."user_profile" up
		ON c.created_by = up.user_id
		JOIN specialty spe
		ON spe.id = up.specialty_id
		JOIN subspecialty sub
		on sub.id = up.subspecialty_id



**************************************************************
**************************************************************
**************************************************************
 Average number of total clicks - what do you mean by click? - different functions/total three buttons 
 - view a question/submit an answer/clicked hidden answer button 


 ---after 2018.11 case /spe not subspe case 
 ---added hidden answer button 

 with all_click as (	
--comment view
select user_id, viewed_at::date, count(topic_view_id) num from comments_view
group by user_id, viewed_at::date

union all 
--comment
select created_by, created_at::date, count(topic_id) from "comment"
group by created_by, created_at::date

union all 
--topic_view
select user_id, viewed_at::date, count(topic_id) from topic_view
group by user_id, viewed_at::date)

--first version before 2018.11 no hidden answer(2 buttons function)
--get every user daily total click 
	
select spe.name spe, count(spe), sum(avg_click), round(avg(avg_click),2) avg_click_spe 
	from 
		(select user_id, round(sum(total_click)/count(user_id),2) avg_click
			from 
				(select user_id, viewed_at::date AS daily, sum(num) total_click
				from all_click
				where viewed_at::date >= '2018-11-01'
				group by user_id, daily
				order by user_id) A 
					group by user_id) uc
					
		JOIN public."user_profile" up
		ON uc.user_id = up.user_id
		JOIN specialty spe
		ON spe.id = up.specialty_id
		JOIN subspecialty sub
		on sub.id = up.subspecialty_id
	group by spe;





