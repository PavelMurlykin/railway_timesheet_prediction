
--1. Импорт таблиц "Дислокация" и "Факт отгрузки" был выполнен при помощи инструмента импорта MS SQL Server

--2. Добавление уникальных ключей в таблицы
/*
alter table dbo.dislocation add id int identity(1,1) not null
alter table dbo.dislocation add constraint dislocation_id primary key clustered (id)

alter table dbo.shipment add id int identity(1,1) not null
alter table dbo.shipment add constraint shipment_id primary key clustered (id)
*/

/*
--Выборки данных из импортированных таблиц "как есть"
select
		ds.AEDDTT [Дата Дислокации]
		,ds.AEDTMT [Время Дислокации]
		,ds.[OBJECT_ID] [Номер ТС]
		,ds.TU_ID [Внешний идентификатор ТЕ]
		,ds.ZZEXTTKTNR [Номер накладной (от НПЗ)]
		,ds.ZZDATE_TICKET [Дата накладной]
		,ds.ZZKNANF [Код Станции Отправления]
		,ds.ZZSTATION_OPER [Код Станции Операции]
		,ds.ZZKNEND [Код Станции Назначения]
		,ds.ZZKNANF_NAME [Станция отправления]
		,ds.ZZST_OPER_NAME [Станция Операции]
		,ds.ZZKNEND_NAME [Станция Назначения]
		,ds.ZZDATE_OPER [Дата Операции]
		,ds.ZZDATE_PROGN [Прогноз Прибытия]
		,ds.ZZDISTANCE [Расстояние До Станции Назначения]
		,ds.ZZ_DATE_TKT [Дата накладной]
	from dbo.dislocation ds

select
		sh.[№_Наклад] [Номер накладной (от НПЗ)]
		,sh.[№_цистер] [Номер ТC]
		,sh.Завод [Завод]
		,sh.[Наименование продукта] [Продукт (наименование)]
		,sh.ПкПогруз [Расшифровка пункта погрузки]
		,sh.Бал [Строка баланса код]
		,sh.Вес [Вес]
		,sh.[Дата накл#] [Дата накладной]
		,sh.ФакПриб#гр [Фактическая дата прибытия груза]
		,sh.ПланПриб#гр [Плановое прибытие груза]
		,sh.[Вид транспортного средства] [Вид транспортного средства]
		,sh.[Наим узла учета] [Наименование узла учета]
	from dbo.shipment sh
*/

--3. Столбец [Внешний идентификатор ТЕ] дублирует информацию из столбца [Номер ТС]
/*
select
		ds.[OBJECT_ID] [Номер ТС]
		,ds.TU_ID [Внешний идентификатор ТЕ]
	from dbo.dislocation ds
	where ds.[OBJECT_ID] <> ds.TU_ID
*/

--4. Проверка соответствия данных в таблицах по ключу "Номер накладной" + "Номер ТС"
/*
--В таблицах есть уникальные данные, остутствующие во второй таблице
select
		ds.ZZEXTTKTNR [Номер накладной (от НПЗ)]
		,ds.[OBJECT_ID] [Номер ТС]	
	from dbo.dislocation ds
	left join dbo.shipment sh on sh.[№_Наклад] = ds.ZZEXTTKTNR and sh.[№_цистер] = ds.[OBJECT_ID]
	where sh.id is null

select
		sh.[№_Наклад] [Номер накладной (от НПЗ)]
		,sh.[№_цистер] [Номер ТС]	
	from dbo.shipment sh
	left join dbo.dislocation ds on sh.[№_Наклад] = ds.ZZEXTTKTNR and sh.[№_цистер] = ds.[OBJECT_ID]
	where ds.id is null
*/

--5. Проверить уникальность номера накладной



-----
/*
Объединение таблиц по ключу "Номер накладной" + "Номер ТС".
Предварительный расчёт полей.
Приведение типов данных полей, содержащих дату.
*/
if object_id(N'TempDB..#transporting',N'U') is not null
	drop table #transporting

select
		ds.ZZEXTTKTNR order_num
		,ds.[OBJECT_ID] van_num
		--
		--,sh.ПкПогруз [Расшифровка пункта погрузки]
		,ds.ZZKNANF A_loc
		--,ds.ZZKNANF_NAME A_loc
		,try_convert(datetime2, sh.[Дата накл#], 21) order_date_1
		,try_convert(datetime2, ds.ZZDATE_TICKET, 21) order_date_2
		,try_convert(datetime2, ds.ZZ_DATE_TKT, 21) order_date_3
		--
		,ds.ZZSTATION_OPER B_loc
		--,ds.ZZST_OPER_NAME B_loc
		,try_convert(datetime2, ds.ZZDATE_OPER, 21) operation_date
		,try_convert(datetime2, left(ds.AEDDTT, 10) + ' ' + ds.AEDTMT, 21) dislocation_date
		--
		,ds.ZZKNEND C_loc
		--,ds.ZZKNEND_NAME C_loc
		,try_convert(datetime2, sh.ФакПриб#гр, 21) real_arrival_date
		,try_convert(datetime2, sh.ПланПриб#гр, 21) A_to_C_plan_date
		,try_convert(datetime2, ds.ZZDATE_PROGN, 21) B_to_C_plan_date
		,ds.ZZDISTANCE B_to_C_distance
		--
		,sh.[Наименование продукта] prod_name
		,sh.Вес prod_weight		
into #transporting
	from dbo.dislocation ds
	left join dbo.shipment sh on sh.[№_Наклад] = ds.ZZEXTTKTNR and sh.[№_цистер] = ds.[OBJECT_ID]
	where isnull(ds.ZZEXTTKTNR, N'') <> N''
	order by ds.ZZEXTTKTNR, ds.[OBJECT_ID], ds.AEDDTT, ds.AEDTMT

create index idx__num on #transporting (order_num, van_num)


if object_id(N'TempDB..#indicators_calc',N'U') is not null
	drop table #indicators_calc

select
		tr.order_num
		,tr.van_num
		,tr.A_loc
		,coalesce(tr.order_date_1, tr.order_date_2, tr.order_date_3) order_date
		,tr.B_loc
		,tr.operation_date
		,row_number() over(partition by tr.order_num, tr.van_num order by tr.order_num, tr.van_num, tr.dislocation_date) dislocation_num
		,tr.dislocation_date
		,tr.C_loc
		,tr.real_arrival_date
		,tr.A_to_C_plan_date
		,tr.B_to_C_plan_date
		,tr.B_to_C_distance
		--,tr.prod_name
		--,tr.prod_weight
into #indicators_calc
	from #transporting tr

-----
/*
1.4. Если нет исторических данных по времени доставки из точки А в точку С, то в качестве прогноза необходимо принять прогноз из дислокации.
*/
if object_id(N'TempDB..#A_to_C_calc_plan_date',N'U') is not null
	drop table #A_to_C_calc_plan_date

select
		ic.order_num
		,ic.van_num
		,max(ic.dislocation_date) A_to_C_calc_plan_date
into #A_to_C_calc_plan_date
	from #indicators_calc ic
	where B_loc = C_loc
		and ic.A_to_C_plan_date is null
	group by ic.order_num, ic.van_num

create index idx__A_to_C_calc_plan_date on #A_to_C_calc_plan_date (order_num, van_num)

----Результат п.1.4
--select
--		acpd.order_num
--		,acpd.van_num
--		,acpd.A_to_C_calc_plan_date
--	from #A_to_C_calc_plan_date acpd

/*
1.3. Если нет исторических данных по времени доставки из точки В в точку C, то в качестве прогноза необходимо принять:
	 (прогнозный срок доставки из точки A в точку C) / (разделить на) расстояние от точки A до точки C * (умножить на) расстояние от точки B до точки C.
*/
if object_id(N'TempDB..#B_to_C_calc_plan_date',N'U') is not null
	drop table #B_to_C_calc_plan_date

select
		ic.order_num
		,ic.van_num
		--,ic.A_loc
		--,ic.B_loc
		--,ic.C_loc
		--,ac_dis.distance ac_distance
		--,bc_dis.distance bc_distance
		--,ic.order_date
		--,ic.operation_date
		,ic.dislocation_num
		--,ic.dislocation_date
		--,ic.A_to_C_plan_date
		--,ac_calc.A_to_C_calc_plan_date
		,dateadd(
			second
			,round((datediff(second, ic.order_date, coalesce(ic.A_to_C_plan_date, ac_calc.A_to_C_calc_plan_date)) * bc_dis.distance / ac_dis.distance), 0)
			,ic.dislocation_date
		) B_to_C_calc_plan_date
		,coalesce(ic.A_to_C_plan_date, ac_calc.A_to_C_calc_plan_date) A_to_C_plan_date
into #B_to_C_calc_plan_date
	from #indicators_calc ic
	left join dbo.distances ac_dis on ac_dis.station_start = ic.A_loc and ac_dis.station_end = ic.C_loc
	left join dbo.distances bc_dis on bc_dis.station_start = ic.B_loc and bc_dis.station_end = ic.C_loc
	left join #A_to_C_calc_plan_date ac_calc on ac_calc.order_num = ic.order_num and ac_calc.van_num = ic.van_num
	where ic.B_to_C_plan_date is null
		and isnull(ac_dis.distance, 0) <> 0

create index idx__B_to_C_calc_plan_date on #B_to_C_calc_plan_date (order_num, van_num)

----Результат п.1.3
--select
--		bcpd.order_num
--		,bcpd.van_num
--		,bcpd.dislocation_num
--		,bcpd.B_to_C_calc_plan_date
--	from #B_to_C_calc_plan_date bcpd

/*
1.1 Дата и время первой по времени дислокации данного вагона с данным номером накладной в точке В
	и дата и время последней его дислокации c этим же номером накладной в точке B.
	Берется среднее из этих дат для каждого вагона.
*/
if object_id(N'TempDB..#B_loc_mean_date',N'U') is not null
	drop table #B_loc_mean_date

select
		ic.order_num
		,ic.van_num
		--,min(ic.dislocation_num) min_num
		--,min(ic.dislocation_date) min_date
		--,max(ic.dislocation_num) max_num
		--,max(ic.dislocation_date) max_date
		,dateadd(
			second
			,datediff(second, min(ic.dislocation_date), max(ic.dislocation_date)) / 2
			,min(ic.dislocation_date)
		) B_loc_mean_date
into #B_loc_mean_date
	from #indicators_calc ic
	where A_loc <> B_loc
		and B_loc <> C_loc
	group by ic.order_num, ic.van_num

create index idx__B_loc_mean_date on #B_loc_mean_date (order_num, van_num)

----Результат п.1.1
--select
--		bmd.order_num
--		,bmd.van_num
--		,bmd.B_loc_mean_date
--	from #B_loc_mean_date bmd

/*
1.2. Дата и время первой дислокации данного вагона с данным номером накладной в точке С,
	 либо в случае отсутствия данных о дислокации данного вагона в точке С -
	 дата и время первого массива дислокации от данного оператора подвижного состава с отсутствием данного вагона с данным номером накладной.
	 Затем из даты и времени (1.2) вычитается дата и время (1.1). Затем выполняется усреднение таких разностей для каждого вагона.

Комментарий: неясен смысл формулировки "дата и время первого массива дислокации от данного оператора подвижного состава с отсутствием данного вагона с данным номером накладной", шаг пропущен в реализации.
*/
if object_id(N'TempDB..#C_loc_first_date',N'U') is not null
	drop table #C_loc_first_date

select
		ic.order_num
		,ic.van_num
		--,min(ic.dislocation_num) min_num
		,min(ic.dislocation_date) C_loc_first_date
into #C_loc_first_date
	from #indicators_calc ic
	where B_loc = C_loc
	group by ic.order_num, ic.van_num

create index idx__C_loc_first_date on #C_loc_first_date (order_num, van_num)

----Результат п.1.2
--select
--		cfd.order_num
--		,cfd.van_num
--		--,bmd.B_loc_mean_date
--		--,cfd.C_loc_first_date		
--		,dateadd(
--			second
--			,datediff(second, bmd.B_loc_mean_date, cfd.C_loc_first_date) / 2
--			,bmd.B_loc_mean_date
--		) mean_date
--	from #C_loc_first_date cfd
--	join #B_loc_mean_date bmd on bmd.order_num = cfd.order_num and bmd.van_num = cfd.van_num

/*
1. Прогнозный срок доставки груза из точки B в точку C определяется
	как среднее арифметическое продолжительности доставки с точностью до сотых долей суток
	доставки всех вагонов со всеми грузами ГПН из точки В в точку С согласно исторических данных дислокации.
*/
;with time_between_stations_by_vans as (
	select
			ic.B_loc
			,ic.C_loc
			,datediff(minute, ic.dislocation_date, coalesce(ic.B_to_C_plan_date, bcpd.B_to_C_calc_plan_date)) B_to_C_time
		from #indicators_calc ic
		join #B_to_C_calc_plan_date bcpd on bcpd.order_num = ic.order_num and bcpd.van_num = ic.van_num and bcpd.dislocation_num = ic.dislocation_num
		where ic.B_loc <> ic.C_loc
)
,days_between_stations as (
	select
			st.B_loc
			,st.C_loc
			,round((cast(avg(st.B_to_C_time) as float) / (60 * 24)), 2) days_between_B_and_C
		from time_between_stations_by_vans st
		where st.B_to_C_time is not null
		group by st.B_loc, st.C_loc
		--order by st.B_loc, st.C_loc
)
select
		dbst.B_loc [Код Станции Операции]
		,isnull(bst.station_desc, N'') [Станция Операции]
		,dbst.C_loc [Код Станции Назначения]
		,isnull(cst.station_desc, N'') [Станция Назначения]
		,dbst.days_between_B_and_C [Среднее время доставки, дн.]
	from days_between_stations dbst
	left join dbo.stations bst on bst.station_code = dbst.B_loc
	left join dbo.stations cst on cst.station_code = dbst.C_loc
	order by dbst.B_loc, dbst.C_loc


--Прогнозный срок доставки груза из точки A в точку C
;with time_between_stations_by_vans as (
	select distinct
			ic.order_num
			,ic.van_num
			,ic.A_loc
			,ic.C_loc
			,datediff(minute, ic.order_date, bcpd.A_to_C_plan_date) A_to_C_time
		from #indicators_calc ic
		join #B_to_C_calc_plan_date bcpd on bcpd.order_num = ic.order_num and bcpd.van_num = ic.van_num
		where ic.A_loc <> ic.C_loc
)
,days_between_stations as (
	select
			st.A_loc
			,st.C_loc
			,round((cast(avg(st.A_to_C_time) as float) / (60 * 24)), 2) days_between_A_and_C
		from time_between_stations_by_vans st
		where st.A_to_C_time is not null
		group by st.A_loc, st.C_loc
)
select
		dbst.A_loc [Код Станции Отправления]
		,isnull(ast.station_desc, N'') [Станция отправления]
		,dbst.C_loc [Код Станции Назначения]
		,isnull(cst.station_desc, N'') [Станция Назначения]
		,dbst.days_between_A_and_C [Среднее время доставки, дн.]
	from days_between_stations dbst
	left join dbo.stations ast on ast.station_code = dbst.A_loc
	left join dbo.stations cst on cst.station_code = dbst.C_loc
	order by dbst.A_loc, dbst.C_loc


-----
if object_id(N'TempDB..#A_to_C_calc_plan_date',N'U') is not null
	drop table #A_to_C_calc_plan_date

if object_id(N'TempDB..#B_to_C_calc_plan_date',N'U') is not null
	drop table #B_to_C_calc_plan_date

if object_id(N'TempDB..#B_loc_mean_date',N'U') is not null
	drop table #B_loc_mean_date

if object_id(N'TempDB..#C_loc_first_date',N'U') is not null
	drop table #C_loc_first_date
-----
if object_id(N'TempDB..#indicators_calc',N'U') is not null
	drop table #indicators_calc

if object_id(N'TempDB..#transporting',N'U') is not null
	drop table #transporting
-----