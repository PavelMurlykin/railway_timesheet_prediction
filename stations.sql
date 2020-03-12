/*
--‘ормирование таблицы станций
insert into dbo.stations (station_code, station_desc)
select distinct
		ds.ZZKNANF station_code
		,ds.ZZKNANF_NAME station_desc
	from dbo.dislocation ds

union

select distinct
		ds.ZZSTATION_OPER station_code
		,ds.ZZST_OPER_NAME station_desc
	from dbo.dislocation ds

union

select distinct
		ds.ZZKNEND station_code
		,ds.ZZKNEND_NAME station_desc
	from dbo.dislocation ds
	order by station_code
*/

/*
--ƒубли кодов с разными названи€ми отсутствуют
select st.station_code
	from dbo.stations st
	group by st.station_code
	having count(st.station_code) > 1
*/

/*
--Ѕольшое количество дублей в названии с разными кодами
select st.station_desc
	from dbo.stations st
	group by st.station_desc
	having count(st.station_desc) > 1
*/


select
		st.id
		,st.station_code
		,st.station_desc
	from dbo.stations st
	--where isnull(st.station_code, N'') = N''
	--	or isnull(st.station_desc, N'') = N''



