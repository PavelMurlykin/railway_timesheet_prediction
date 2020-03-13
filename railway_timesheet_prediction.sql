
--1. ������ ������ "����������" � "���� ��������" ��� �������� ��� ������ ����������� ������� MS SQL Server

--2. ���������� ���������� ������ � �������
/*
alter table dbo.dislocation add id int identity(1,1) not null
alter table dbo.dislocation add constraint dislocation_id primary key clustered (id)

alter table dbo.shipment add id int identity(1,1) not null
alter table dbo.shipment add constraint shipment_id primary key clustered (id)
*/

/*
--������� ������ �� ��������������� ������ "��� ����"
select
		ds.AEDDTT [���� ����������]
		,ds.AEDTMT [����� ����������]
		,ds.[OBJECT_ID] [����� ��]
		,ds.TU_ID [������� ������������� ��]
		,ds.ZZEXTTKTNR [����� ��������� (�� ���)]
		,ds.ZZDATE_TICKET [���� ���������]
		,ds.ZZKNANF [��� ������� �����������]
		,ds.ZZSTATION_OPER [��� ������� ��������]
		,ds.ZZKNEND [��� ������� ����������]
		,ds.ZZKNANF_NAME [������� �����������]
		,ds.ZZST_OPER_NAME [������� ��������]
		,ds.ZZKNEND_NAME [������� ����������]
		,ds.ZZDATE_OPER [���� ��������]
		,ds.ZZDATE_PROGN [������� ��������]
		,ds.ZZDISTANCE [���������� �� ������� ����������]
		,ds.ZZ_DATE_TKT [���� ���������]
	from dbo.dislocation ds

select
		sh.[�_������] [����� ��������� (�� ���)]
		,sh.[�_������] [����� �C]
		,sh.����� [�����]
		,sh.[������������ ��������] [������� (������������)]
		,sh.�������� [����������� ������ ��������]
		,sh.��� [������ ������� ���]
		,sh.��� [���]
		,sh.[���� ����#] [���� ���������]
		,sh.�������#�� [����������� ���� �������� �����]
		,sh.��������#�� [�������� �������� �����]
		,sh.[��� ������������� ��������] [��� ������������� ��������]
		,sh.[���� ���� �����] [������������ ���� �����]
	from dbo.shipment sh
*/

--3. ������� [������� ������������� ��] ��������� ���������� �� ������� [����� ��]
/*
select
		ds.[OBJECT_ID] [����� ��]
		,ds.TU_ID [������� ������������� ��]
	from dbo.dislocation ds
	where ds.[OBJECT_ID] <> ds.TU_ID
*/

--4. �������� ������������ ������ � �������� �� ����� "����� ���������" + "����� ��"
/*
--� �������� ���� ���������� ������, ������������� �� ������ �������
select
		ds.ZZEXTTKTNR [����� ��������� (�� ���)]
		,ds.[OBJECT_ID] [����� ��]	
	from dbo.dislocation ds
	left join dbo.shipment sh on sh.[�_������] = ds.ZZEXTTKTNR and sh.[�_������] = ds.[OBJECT_ID]
	where sh.id is null

select
		sh.[�_������] [����� ��������� (�� ���)]
		,sh.[�_������] [����� ��]	
	from dbo.shipment sh
	left join dbo.dislocation ds on sh.[�_������] = ds.ZZEXTTKTNR and sh.[�_������] = ds.[OBJECT_ID]
	where ds.id is null
*/

--5. ��������� ������������ ������ ���������



-----
/*
����������� ������ �� ����� "����� ���������" + "����� ��".
��������������� ������ �����.
���������� ����� ������ �����, ���������� ����.
*/
if object_id(N'TempDB..#transporting',N'U') is not null
	drop table #transporting

select
		ds.ZZEXTTKTNR order_num
		,ds.[OBJECT_ID] van_num
		--
		--,sh.�������� [����������� ������ ��������]
		,ds.ZZKNANF A_loc
		--,ds.ZZKNANF_NAME A_loc
		,try_convert(datetime2, sh.[���� ����#], 21) order_date_1
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
		,try_convert(datetime2, sh.�������#��, 21) real_arrival_date
		,try_convert(datetime2, sh.��������#��, 21) A_to_C_plan_date
		,try_convert(datetime2, ds.ZZDATE_PROGN, 21) B_to_C_plan_date
		,ds.ZZDISTANCE B_to_C_distance
		--
		,sh.[������������ ��������] prod_name
		,sh.��� prod_weight		
into #transporting
	from dbo.dislocation ds
	left join dbo.shipment sh on sh.[�_������] = ds.ZZEXTTKTNR and sh.[�_������] = ds.[OBJECT_ID]
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
1.4. ���� ��� ������������ ������ �� ������� �������� �� ����� � � ����� �, �� � �������� �������� ���������� ������� ������� �� ����������.
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

----��������� �.1.4
--select
--		acpd.order_num
--		,acpd.van_num
--		,acpd.A_to_C_calc_plan_date
--	from #A_to_C_calc_plan_date acpd

/*
1.3. ���� ��� ������������ ������ �� ������� �������� �� ����� � � ����� C, �� � �������� �������� ���������� �������:
	 (���������� ���� �������� �� ����� A � ����� C) / (��������� ��) ���������� �� ����� A �� ����� C * (�������� ��) ���������� �� ����� B �� ����� C.
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

----��������� �.1.3
--select
--		bcpd.order_num
--		,bcpd.van_num
--		,bcpd.dislocation_num
--		,bcpd.B_to_C_calc_plan_date
--	from #B_to_C_calc_plan_date bcpd

/*
1.1 ���� � ����� ������ �� ������� ���������� ������� ������ � ������ ������� ��������� � ����� �
	� ���� � ����� ��������� ��� ���������� c ���� �� ������� ��������� � ����� B.
	������� ������� �� ���� ��� ��� ������� ������.
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

----��������� �.1.1
--select
--		bmd.order_num
--		,bmd.van_num
--		,bmd.B_loc_mean_date
--	from #B_loc_mean_date bmd

/*
1.2. ���� � ����� ������ ���������� ������� ������ � ������ ������� ��������� � ����� �,
	 ���� � ������ ���������� ������ � ���������� ������� ������ � ����� � -
	 ���� � ����� ������� ������� ���������� �� ������� ��������� ���������� ������� � ����������� ������� ������ � ������ ������� ���������.
	 ����� �� ���� � ������� (1.2) ���������� ���� � ����� (1.1). ����� ����������� ���������� ����� ��������� ��� ������� ������.

�����������: ������ ����� ������������ "���� � ����� ������� ������� ���������� �� ������� ��������� ���������� ������� � ����������� ������� ������ � ������ ������� ���������", ��� �������� � ����������.
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

----��������� �.1.2
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
1. ���������� ���� �������� ����� �� ����� B � ����� C ������������
	��� ������� �������������� ����������������� �������� � ��������� �� ����� ����� �����
	�������� ���� ������� �� ����� ������� ��� �� ����� � � ����� � �������� ������������ ������ ����������.
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
		dbst.B_loc [��� ������� ��������]
		,isnull(bst.station_desc, N'') [������� ��������]
		,dbst.C_loc [��� ������� ����������]
		,isnull(cst.station_desc, N'') [������� ����������]
		,dbst.days_between_B_and_C [������� ����� ��������, ��.]
	from days_between_stations dbst
	left join dbo.stations bst on bst.station_code = dbst.B_loc
	left join dbo.stations cst on cst.station_code = dbst.C_loc
	order by dbst.B_loc, dbst.C_loc


--���������� ���� �������� ����� �� ����� A � ����� C
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
		dbst.A_loc [��� ������� �����������]
		,isnull(ast.station_desc, N'') [������� �����������]
		,dbst.C_loc [��� ������� ����������]
		,isnull(cst.station_desc, N'') [������� ����������]
		,dbst.days_between_A_and_C [������� ����� ��������, ��.]
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