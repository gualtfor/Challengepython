
sql = {"query1": """select department, job,
	count(case cuarter when 1 then cuarter  end) as "Q1",
	count(case cuarter when 2 then cuarter  end) as "Q2",
	count(case cuarter when 3 then cuarter  end) as "Q3",
	count(case cuarter when 4 then cuarter  end) as "Q4"
	from
	(
		select d.department, j.job, extract (quarter from TO_TIMESTAMP(
		    e.datetime ,'YYYY-MM-DD TO:MI:SS')) as cuarter
		from "hired_employees" e
			inner join "departments" d
			on e.department_id = d.id
			inner join "jobs" j
			on e.job_id = j.id
			where substring(e.datetime,1,4) = '2021') as temp
	group by department, job""",

        "query2": """select e.department_id as id, d.department, count(*) as hired 
            from "hired_employees" e
                inner join "departments" d
                on e.department_id = d.id
                where substring(e.datetime,1,4) = '2021'
                group by e.department_id, d.department
                having count(*)> (select avg(t.poor) from (select e.department_id, count(*) as poor from "hired_employees" e
									inner join "jobs" j
									on e.job_id = j.id
									where substring(e.datetime,1,4) = '2021'
									group by e.department_id) t) """}
