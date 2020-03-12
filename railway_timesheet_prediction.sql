
--1. ������ ������ "����������" � "���� ��������" ��� �������� ��� ������ ����������� ������� MS SQL Server

--2. ���������� ���������� ������ � �������
/*
alter table dbo.dislocation add id int identity(1,1) not null
alter table dbo.dislocation add constraint dislocation_id primary key clustered (id)

alter table dbo.shipment add id int identity(1,1) not null
alter table dbo.shipment add constraint shipment_id primary key clustered (id)
*/

/*
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

----select --top 500
----		ds.ZZEXTTKTNR [����� ��������� (�� ���)]
----		,ds.[OBJECT_ID] [����� ��]

----		--,ds.ZZKNANF [��� ������� �����������]
----		--,ds.ZZSTATION_OPER [��� ������� ��������]
----		--,ds.ZZKNEND [��� ������� ����������]
----		,ds.ZZKNANF_NAME [������� �����������]
----		,ds.ZZST_OPER_NAME [������� ��������]
----		,ds.ZZKNEND_NAME [������� ����������]

----		,left(ds.ZZDATE_TICKET, 10) [���� ���������]
----		--,ds.ZZ_DATE_TKT [���� ���������]
----		--,ds.AEDDTT [���� ����������]
----		--,ds.AEDTMT [����� ����������]
----		,convert(nvarchar(255), left(ds.AEDDTT, 10) + ' ' + ds.AEDTMT, 21) [���� � ����� ����������]
----		,left(ds.ZZDATE_OPER, 10) [���� ��������]	
----		,left(ds.ZZDATE_PROGN, 10) [������� ��������]
----		,ds.ZZDISTANCE [���������� �� ������� ����������]		
----	from dbo.dislocation ds
----	--where ds.ZZEXTTKTNR = N'��258563'
----	--	and ds.[OBJECT_ID] = N'50401355'
----	where ds.ZZEXTTKTNR = N'��238704'
----		--and ds.[OBJECT_ID] = N'51880961'
----	order by ds.ZZEXTTKTNR, ds.[OBJECT_ID], ds.AEDDTT, ds.AEDTMT


----select --top 500
----		sh.[�_������] [����� ��������� (�� ���)]
----		,sh.[�_������] [����� �C]
----		--,sh.����� [�����]		
----		,sh.�������� [����������� ������ ��������]
----		--,sh.��� [������ ������� ���]
----		,left(sh.[���� ����#], 10) [���� ���������]
----		,left(sh.�������#��, 10) [����������� ���� �������� �����]
----		,left(sh.��������#��, 10) [�������� �������� �����]
----		,sh.[������������ ��������] [������� (������������)]
----		,sh.��� [���]
----	from dbo.shipment sh
----	where sh.[�_������] = N'��238704'
----		--and sh.[�_������] = N'51880961'



if object_id(N'TempDB..#transporting',N'U') is not null
	drop table #transporting

select
		sh.[�_������] order_num
		,sh.[�_������] van_num
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
	from dbo.shipment sh
	join dbo.dislocation ds on sh.[�_������] = ds.ZZEXTTKTNR and sh.[�_������] = ds.[OBJECT_ID]
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
	where tr.order_num = N'��746235'
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
--1.1 ���� � ����� ������ �� ������� ���������� ������� ������ � ������ ������� ��������� � ����� �
--	� ���� � ����� ��������� ��� ���������� c ���� �� ������� ��������� � ����� B.
--	������� ������� �� ���� ��� ��� ������� ������.
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
1.2. ���� � ����� ������ ���������� ������� ������ � ������ ������� ��������� � ����� �,
	���� � ������ ���������� ������ � ���������� ������� ������ � ����� � -
	���� � ����� ������� ������� ���������� �� ������� ��������� ���������� ������� � ����������� ������� ������ � ������ ������� ���������.
	����� �� ���� � ������� (1.2) ���������� ���� � ����� (1.1). ����� ����������� ���������� ����� ��������� ��� ������� ������.
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
1.3. ���� ��� ������������ ������ �� ������� �������� �� ����� � � ����� C, �� � �������� �������� ���������� �������:
	(���������� ���� �������� �� ����� A � ����� C) / (��������� ��) ���������� �� ����� A �� ����� C * (�������� ��) ���������� �� ����� B �� ����� C.
*/



/*
1.4. ���� ��� ������������ ������ �� ������� �������� �� ����� � � ����� �, �� � �������� �������� ���������� ������� ������� �� ����������.
*/






if object_id(N'TempDB..#indicators_calc',N'U') is not null
	drop table #indicators_calc

if object_id(N'TempDB..#transporting',N'U') is not null
	drop table #transporting