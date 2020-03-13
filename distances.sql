
/*
--Формирование таблицы расстояний
insert into dbo.distances(station_start, station_end, distance)
select distinct
		ds.ZZSTATION_OPER
		,ds.ZZKNEND
		,try_cast(ds.ZZDISTANCE as float)
	from dbo.dislocation ds
	order by ds.ZZSTATION_OPER, ds.ZZKNEND
*/

/*
--Несколько расстояний на одном маршруте
;with duplicates as (
	select
			d.id
			,d.station_start
			,d.station_end
			,row_number() over (partition by d.station_start, d.station_end order by d.station_start, d.distance desc) distance_order
			,d.distance
		from dbo.distances d
		join (
			select d.station_start, d.station_end
				from dbo.distances d
				group by d.station_start, d.station_end
				having count(*) > 1
			) dup on dup.station_start = d.station_start and dup.station_end = d.station_end
)
--При наличии нескольких значений расстояний по одному маршруту оставляем только максимальное
--select
--		d.id
--		,d.station_start
--		,d.station_end
--		,d.distance
delete d
	from duplicates dup
	join dbo.distances d on d.id = dup.id
	where dup.distance_order <> 1
*/


select
		d.id
		,d.station_start
		,d.station_end
		,d.distance
	from dbo.distances d
