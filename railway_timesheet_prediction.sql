
--1. Импорт таблиц "Дислокация" и "Факт отгрузки" был выполнен при помощи инструмента импорта MS SQL Server

--2. Добавление уникальных ключей в таблицы
/*
alter table dbo.dislocation add id int identity(1,1) not null
alter table dbo.dislocation add constraint dislocation_id primary key clustered (id)

alter table dbo.shipment add id int identity(1,1) not null
alter table dbo.shipment add constraint shipment_id primary key clustered (id)
*/

/*
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

----select --top 500
----		ds.ZZEXTTKTNR [Номер накладной (от НПЗ)]
----		,ds.[OBJECT_ID] [Номер ТС]

----		--,ds.ZZKNANF [Код Станции Отправления]
----		--,ds.ZZSTATION_OPER [Код Станции Операции]
----		--,ds.ZZKNEND [Код Станции Назначения]
----		,ds.ZZKNANF_NAME [Станция отправления]
----		,ds.ZZST_OPER_NAME [Станция Операции]
----		,ds.ZZKNEND_NAME [Станция Назначения]

----		,left(ds.ZZDATE_TICKET, 10) [Дата накладной]
----		--,ds.ZZ_DATE_TKT [Дата накладной]
----		--,ds.AEDDTT [Дата Дислокации]
----		--,ds.AEDTMT [Время Дислокации]
----		,convert(nvarchar(255), left(ds.AEDDTT, 10) + ' ' + ds.AEDTMT, 21) [Дата и время дислокации]
----		,left(ds.ZZDATE_OPER, 10) [Дата Операции]	
----		,left(ds.ZZDATE_PROGN, 10) [Прогноз Прибытия]
----		,ds.ZZDISTANCE [Расстояние До Станции Назначения]		
----	from dbo.dislocation ds
----	--where ds.ZZEXTTKTNR = N'ЭЙ258563'
----	--	and ds.[OBJECT_ID] = N'50401355'
----	where ds.ZZEXTTKTNR = N'ЭЙ238704'
----		--and ds.[OBJECT_ID] = N'51880961'
----	order by ds.ZZEXTTKTNR, ds.[OBJECT_ID], ds.AEDDTT, ds.AEDTMT


----select --top 500
----		sh.[№_Наклад] [Номер накладной (от НПЗ)]
----		,sh.[№_цистер] [Номер ТC]
----		--,sh.Завод [Завод]		
----		,sh.ПкПогруз [Расшифровка пункта погрузки]
----		--,sh.Бал [Строка баланса код]
----		,left(sh.[Дата накл#], 10) [Дата накладной]
----		,left(sh.ФакПриб#гр, 10) [Фактическая дата прибытия груза]
----		,left(sh.ПланПриб#гр, 10) [Плановое прибытие груза]
----		,sh.[Наименование продукта] [Продукт (наименование)]
----		,sh.Вес [Вес]
----	from dbo.shipment sh
----	where sh.[№_Наклад] = N'ЭЙ238704'
----		--and sh.[№_цистер] = N'51880961'



if object_id(N'TempDB..#transporting',N'U') is not null
	drop table #transporting

select
		sh.[№_Наклад] order_num
		,sh.[№_цистер] van_num
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
	from dbo.shipment sh
	join dbo.dislocation ds on sh.[№_Наклад] = ds.ZZEXTTKTNR and sh.[№_цистер] = ds.[OBJECT_ID]
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
		--,datediff(second, tr.dislocation_date, tr.B_to_C_plan_date) B_to_C_dis_seconds
		--,datediff(second, tr.operation_date, tr.B_to_C_plan_date) B_to_C_seconds
		--,datediff(second, coalesce(tr.order_date_1, tr.order_date_2, tr.order_date_3), tr.A_to_C_plan_date) A_to_C_seconds
into #indicators_calc
	from #transporting tr
	where tr.order_num = N'ЭЙ746235'
		and tr.van_num = N'50377613'
	--order by tr.dislocation_date

select
		ic.order_num
		,ic.van_num
		,ic.A_loc
		,ic.order_date
		,ic.B_loc
		,ic.operation_date
		,ic.dislocation_num
		,ic.dislocation_date
		,ic.C_loc
		,ic.real_arrival_date
		,ic.A_to_C_plan_date
		,ic.B_to_C_plan_date
		,ic.B_to_C_distance
	from #indicators_calc ic

--/*
--1.1 Дата и время первой по времени дислокации данного вагона с данным номером накладной в точке В
--	и дата и время последней его дислокации c этим же номером накладной в точке B.
--	Берется среднее из этих дат для каждого вагона.
--*/
--select
--		ic.order_num
--		,ic.van_num
--		--,min(ic.dislocation_num) min_num
--		--,min(ic.dislocation_date) min_date
--		--,max(ic.dislocation_num) max_num
--		--,max(ic.dislocation_date) max_date
--		,datediff(second, min(ic.dislocation_date), max(ic.dislocation_date))/2 B_loc_mean_date
--	from #indicators_calc ic
--	where A_loc <> B_loc
--		and B_loc <> C_loc
--	group by ic.order_num, ic.van_num

/*
1.2. Дата и время первой дислокации данного вагона с данным номером накладной в точке С,
	либо в случае отсутствия данных о дислокации данного вагона в точке С -
	дата и время первого массива дислокации от данного оператора подвижного состава с отсутствием данного вагона с данным номером накладной.
	Затем из даты и времени (1.2) вычитается дата и время (1.1). Затем выполняется усреднение таких разностей для каждого вагона.
*/
select
		ic.order_num
		,ic.van_num
		,min(ic.dislocation_num) min_num
		,min(ic.dislocation_date) min_date
	from #indicators_calc ic
	where B_loc = C_loc
	group by ic.order_num, ic.van_num

/*
1.3. Если нет исторических данных по времени доставки из точки В в точку C, то в качестве прогноза необходимо принять:
	(прогнозный срок доставки из точки A в точку C) / (разделить на) расстояние от точки A до точки C * (умножить на) расстояние от точки B до точки C.
*/



/*
1.4. Если нет исторических данных по времени доставки из точки А в точку С, то в качестве прогноза необходимо принять прогноз из дислокации.
*/






if object_id(N'TempDB..#indicators_calc',N'U') is not null
	drop table #indicators_calc

if object_id(N'TempDB..#transporting',N'U') is not null
	drop table #transporting