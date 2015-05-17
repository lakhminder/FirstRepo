SET serveroutput on SIZE 1000000;
Declare
	ln_EQ_ATL_SEID			corp.TSR_BACKFILL_TEMP.EQ_ATL_SEID%type;
	ln_CPE_BTL_SEID   		corp.TSR_BACKFILL_TEMP.CPE_BTL_SEID%type;
	ln_IQ_ATL_SEID   		corp.TSR_BACKFILL_TEMP.IQ_ATL_SEID%type;
	ln_PORT_BTL_SEID  		corp.TSR_BACKFILL_TEMP.PORT_BTL_SEID%type;
	ln_TSR_BTL_SEID			corp.TSR_BACKFILL_TEMP.TSR_BTL_SEID%type;
	ln_port_id				port.port_id%type;
	ln_port_ver_no			port.port_version_no%type;
	ln_cpe_id				router.router_id%type;
	ln_cpe_ver_no			router.router_version_no%type;
	ln_tsr_id				service.service_id%type;
	ln_tsr_seid				service.service_element_id%type;
	ls_tsr_found_fg  		varchar2(1);
	ls_port_found_fg		varchar2(1);
	ls_cpe_found_fg			varchar2(1);
	ls_err_txt 		 		varchar2(300);
	ln_err_cd	        	NUMBER(10);
	lr_tsr_data				service%rowtype;
	lr_new_tsr_data			service%rowtype;
	lr_port_data			port%rowtype;
	lr_tsr_rel_port_data	port%rowtype;
	lr_cpe_data				router%rowtype;
	lr_direct_cpe_data 		router%rowtype;
	os_err_msg              VARCHAR2(300);
    on_return               NUMBER(10);
	
	Cursor lc_tsr_backfill_data is
		select * from corp.TSR_BACKFILL_TEMP where PROCESSED_IND is null;
		
	CURSOR	lc_cpe_seid_chk (in_cpe_seid router.service_element_id%type) IS 
		SELECT *
		FROM router r
		WHERE service_element_id = in_cpe_seid
		and service_element_id <> 0
        and router_version_no = (select max(router_version_no) from router where router_id = r.router_id)
		order by created_dt desc;
		
	CURSOR	lc_port_seid_chk (in_port_seid port.service_element_id%type) IS 
		SELECT *
		FROM port p
		WHERE service_element_id = in_port_seid
		and service_element_id <> 0
		and port_version_no = (select max(port_version_no) from port where port_id = p.port_id)
		order by created_dt desc;
		
	Cursor lc_cpe_to_tsr_data(in_cpe_id router.router_id%type, in_cpe_ver_no router.router_version_no%type) is
		select s.* from 
		router_entity_xref rxref, service s 
		where 
		rxref.router_id = in_cpe_id
		and rxref.router_version_no = in_cpe_ver_no
		and rxref.entity_nm = 'SERVICE'
		and rxref.xref_version_cd <> 'SP'
		and rxref.xref_version_no = (SELECT max(ver.xref_version_no) FROM router_entity_xref ver
									WHERE ver.router_id = rxref.router_id and ver.record_id = rxref.record_id and ver.router_version_no = rxref.router_version_no)
		and s.service_id = rxref.record_id 
		and s.service_version_no = rxref.record_version_no
		and s.record_type_Cd = 'TRANSPORT SERVICE RELATIONSHIP'
		and s.action_cd <> 'D';		
		
	Cursor lc_tsr_to_port_data(in_tsr_id service.service_id%type, in_tsr_ver_no service.service_version_no%type) is
		select p.*
		from
		service_entity_xref sxref, port p
		where
		sxref.service_id = in_tsr_id
		and sxref.service_version_no = in_tsr_ver_no
		and sxref.entity_nm = 'PORT'
		and sxref.xref_version_cd <> 'SP'
		and sxref.xref_version_no = (SELECT max(ver.xref_version_no) FROM service_entity_xref ver
									WHERE ver.service_id = sxref.service_id and ver.record_id = sxref.record_id and ver.service_version_no = sxref.service_version_no)
		and sxref.record_id = p.port_id
		and sxref.record_version_no = p.port_version_no
		and p.action_cd <> 'D';
		
	Cursor lc_port_to_tsr_data(in_port_id port.port_id%type, in_port_ver_no port.port_version_no%type) is
		select s.* 
		from port_entity_xref pxref, service s
		where
		pxref.port_id = in_port_id
		and pxref.port_version_no = in_port_ver_no
		and pxref.entity_nm = 'SERVICE'
		and pxref.xref_version_cd <> 'SP'
		and pxref.xref_version_no = (SELECT max(ver.xref_version_no) FROM port_entity_xref ver
									WHERE ver.port_id = pxref.port_id and ver.record_id = pxref.record_id and ver.port_version_no = pxref.port_version_no)
		and s.service_id = pxref.record_id
		and s.service_version_no = pxref.record_version_no
		and s.record_type_Cd = 'TRANSPORT SERVICE RELATIONSHIP'
		and s.action_cd <> 'D';

	Cursor lc_tsr_to_cpe_data(in_tsr_id service.service_id%type, in_tsr_ver_no service.service_version_no%type) is
		select r.*
		from
		service_entity_xref sxref, router r
		where
		sxref.service_id = in_tsr_id
		and sxref.service_version_no = in_tsr_ver_no
		and sxref.entity_nm = 'ROUTER'
		and sxref.xref_version_cd <> 'SP'
		and sxref.xref_version_no = (SELECT max(ver.xref_version_no) FROM service_entity_xref ver
									WHERE ver.service_id = sxref.service_id and ver.record_id = sxref.record_id and ver.service_version_no = sxref.service_version_no)
		and sxref.record_id = r.router_id
		and sxref.record_version_no = r.router_version_no
		and r.action_cd <> 'D';
		
	Cursor lc_port_cpe_xref_chk(in_port_id port.port_id%type, in_port_ver_no port.port_version_no%type) is
		select r.*
		from port_entity_xref pxref, router r
		where
		pxref.port_id = in_port_id
		and pxref.port_version_no = in_port_ver_no
		and pxref.entity_nm = 'ROUTER'
		and pxref.record_id = r.router_id
		and pxref.record_version_no = r.router_version_no
		and pxref.xref_version_no = (select max(ver.xref_version_no) from port_entity_xref ver
									 where ver.port_id = pxref.port_id and ver.record_id = pxref.record_id and ver.port_version_no = pxref.port_version_no)
		and r.action_cd <> 'D';

	--lr_cpe_seid_chk     lc_cpe_seid_chk%rowtype;
Begin
	DBMS_OUTPUT.PUT_LINE('Start Time =>' || TO_CHAR (SYSTIMESTAMP, 'dd-mm-yyyy hh24:mi:ss.FF'));
	For lr_tsr_backfill_data in lc_tsr_backfill_data 
	Loop
		ln_CPE_BTL_SEID := null;
		ln_PORT_BTL_SEID := null;
		ls_err_txt := null;
		ln_cpe_id := null;
		ln_cpe_ver_no := null;
		lr_cpe_data := null;
		ln_tsr_id := null;
		ln_tsr_seid := null;
		lr_port_data := null;
		lr_new_tsr_data := null;
		ln_port_id := null;
		ln_port_ver_no := null;
		ls_tsr_found_fg := null;
		ls_port_found_fg := null;
		ls_cpe_found_fg := null;
		os_err_msg := null;
		on_return := null;
		Begin
			
			OPEN lc_cpe_seid_chk(lr_tsr_backfill_data.CPE_BTL_SEID);
			FETCH lc_cpe_seid_chk INTO lr_cpe_data;
			--DBMS_OUTPUT.PUT_LINE(lc_cpe_seid_chk%rowcount);
			if lc_cpe_seid_chk%notfound then
				ls_err_txt := 'CPE SEID ' || lr_tsr_backfill_data.CPE_BTL_SEID || ' does not exists in LIMS';
			else 
				if lr_cpe_data.action_cd = 'D' then
					loop
						FETCH lc_cpe_seid_chk INTO lr_cpe_data;
						if lr_cpe_data.action_cd = 'A' then
							ls_cpe_found_fg := 'Y';
							exit;
						end if;
						exit when lc_cpe_seid_chk%notfound;
					end loop;
					if ls_cpe_found_fg is null then
						ls_err_txt := 'CPE SEID ' || lr_tsr_backfill_data.CPE_BTL_SEID || ' is disconnected in LIMS';
					end if;
								
				end if;
			end if;
			
			Close lc_cpe_seid_chk;
			OPEN lc_port_seid_chk(lr_tsr_backfill_data.PORT_BTL_SEID);
			FETCH lc_port_seid_chk INTO lr_port_data;
			
			/*if lr_tsr_backfill_data.CPE_BTL_SEID = 0 or lr_tsr_backfill_data.PORT_BTL_SEID = 0 then
				ls_err_txt := 'CPE SEID or Port SEID is not valid ';
			else if lc_cpe_seid_chk%not found or  lc_port_seid_chk%not found then
				ls_err_txt := '';*/
				
			
			if lc_port_seid_chk%notfound then
				ls_err_txt := ls_err_txt ||'PORT SEID ' || lr_tsr_backfill_data.PORT_BTL_SEID || ' does not exists in LIMS';
			else 
				if lr_port_data.action_cd = 'D' then
					loop
						FETCH lc_port_seid_chk INTO lr_port_data;
						if lr_port_data.action_cd = 'A' then
							ls_port_found_fg := 'Y';
							exit;
						end if;
						exit when lc_port_seid_chk%notfound;
					end loop;
					if ls_port_found_fg is null then
						ls_err_txt := ls_err_txt ||'PORT SEID ' || lr_tsr_backfill_data.PORT_BTL_SEID || ' is disconnected in LIMS';
					end if;
					
				end if;
			end if;
						
			Close lc_port_seid_chk;
			
			
			if ls_err_txt is null then
				--Check for Direct Xref and Archive it
				open lc_port_cpe_xref_chk(lr_port_data.port_id, lr_port_data.port_version_no);
				Loop
					fetch lc_port_cpe_xref_chk into lr_direct_cpe_data;
					Exit when lc_port_cpe_xref_chk%notfound;
					if lc_port_cpe_xref_chk%found then
						if lr_direct_cpe_data.router_id = lr_cpe_data.router_id and lr_direct_cpe_data.router_version_no = lr_cpe_data.router_version_no then
							insert into port_entity_xref_hist
							select * from port_entity_xref 
							where port_id = lr_port_data.port_id
							and port_version_no = lr_port_data.port_version_no
							and record_id = lr_cpe_data.router_id
							and record_version_no = lr_cpe_data.router_version_no;
							
							insert into router_entity_xref_hist
							select * from router_entity_xref
							where router_id = lr_cpe_data.router_id
							and router_version_no = lr_cpe_data.router_version_no
							and record_id = lr_port_data.port_id
							and record_version_no = lr_port_data.port_version_no;
							
							delete from port_entity_xref 
							where port_id = lr_port_data.port_id
							and port_version_no = lr_port_data.port_version_no
							and record_id = lr_cpe_data.router_id
							and record_version_no = lr_cpe_data.router_version_no;
							
							delete from router_entity_xref
							where router_id = lr_cpe_data.router_id
							and router_version_no = lr_cpe_data.router_version_no
							and record_id = lr_port_data.port_id
							and record_version_no = lr_port_data.port_version_no;
						else
							ls_err_txt := ls_err_txt || 'Port with SEID ' || lr_port_data.service_element_id || 
										'is directly related to different CPE with SEID' || lr_direct_cpe_data.service_element_id;
						end if;
					end if;
				End Loop;
				Close lc_port_cpe_xref_chk;
				--Check if CPE is related to TSR
				for lr_tsr_data in lc_cpe_to_tsr_data(lr_cpe_data.router_id, lr_cpe_data.router_version_no)
				Loop
					--fetch lc_cpe_to_tsr_data into lr_tsr_data;
					--DBMS_OUTPUT.PUT_LINE('lc_cpe_to_tsr_data.rowcount ' || lc_cpe_to_tsr_data%rowcount);
					--Exit when lc_cpe_to_tsr_data%notfound;
					--if lc_cpe_to_tsr_data%found then
					--DBMS_OUTPUT.PUT_LINE('lr_tsr_rel_port_data.service_element_id ' || lr_tsr_rel_port_data.service_element_id);
						open lc_tsr_to_port_data(lr_tsr_data.service_id, lr_tsr_data.service_version_no);
						fetch lc_tsr_to_port_data into lr_tsr_rel_port_data;
						if lc_tsr_to_port_data%found then
							--Check if same Port
							if lr_port_data.service_element_id = lr_tsr_rel_port_data.service_element_id then
								--update tsr_backfill set TSR_BTL_SEID = lr_tsr_data.service_element_id where PORT_BTL_SEID = lr_tsr_backfill_data.PORT_BTL_SEID;
								ls_err_txt := ls_err_txt || 'CPE Already related to port via TSR SEID ' || lr_tsr_data.service_element_id;
								lr_new_tsr_data := lr_tsr_data;
								ls_tsr_found_fg := 'Y';
								close lc_tsr_to_port_data;
								EXIT;
							--else 
								--ls_err_txt := ls_err_txt || 'CPE is related to different Port via TSR';
							end if;
						--else
							--Should never be reached though!!
							--ls_err_txt := 'TSR Found';
						end if;
						--DBMS_OUTPUT.PUT_LINE('Port SEID: ' || lr_tsr_rel_port_data.service_element_id);
						close lc_tsr_to_port_data;
					--end if;
				End Loop;
				--close lc_cpe_to_tsr_data;
				
				--Create TSR
				if ls_tsr_found_fg = 'Y' then
					--DBMS_OUTPUT.PUT_LINE('TSR Found: ' || lr_new_tsr_data.service_element_id);
					update corp.TSR_BACKFILL_TEMP set error_txt = ls_err_txt, PROCESSED_IND = 'N', PROCESSED_DT = sysdate where PORT_BTL_SEID = lr_port_data.service_element_id and CPE_BTL_SEID = lr_cpe_data.service_element_id;
					--update tsr_backfill set TSR_BTL_SEID = lr_new_tsr_data.service_element_id where PORT_BTL_SEID = lr_tsr_backfill_data.PORT_BTL_SEID;
				else
					--Create TSR and required XREF
					select S_GR_RECORD_ID.nextval into ln_tsr_id from dual; --3986247
					select S_SE_SERVICE_ELEMENT_SEQ.nextval into ln_tsr_seid from dual;  --20166927
					
					Insert into SERVICE
					   (SERVICE_ID, SERVICE_VERSION_NO, RECORD_VERSION_CD, RECORD_STATUS_CD,
					   RECORD_TYPE_CD, CREATED_DT, LAST_MODIFIED_USER_NM, LAST_MODIFIED_DT,
					   ENGINEERING_ORDER_ID, SALES_ORDER_ID, ACTION_CD, CUSTOMER_ACCT_ID,
					   SERVICE_ELEMENT_ID, COL_0_VAL, COL_3_VAL, COL_6_VAL,
					   SUBCLASS_NM, SOURCE_SYSTEM_NM, IP_VERSION_CD)
					 Values
					   (ln_tsr_id, 1, lr_cpe_data.RECORD_VERSION_CD, 'P',
					   'TRANSPORT SERVICE RELATIONSHIP', sysdate, 'TSR_BACKFILL', sysdate,
					   lr_cpe_data.ENGINEERING_ORDER_ID, lr_cpe_data.SALES_ORDER_ID, 'A', lr_cpe_data.CUSTOMER_ACCT_ID,
					   ln_tsr_seid, 'EXISTING', 'QWEST', 'CURR SVCI',
					   'Transport Service Relationship', 'OANS', '4');
					
					--Create TSR to PORT XREF
					Insert into SERVICE_ENTITY_XREF
					   (SERVICE_ID, SERVICE_VERSION_NO, RECORD_ID, RECORD_VERSION_NO,
					   XREF_VERSION_NO, ENTITY_NM, RECORD_TYPE_CD, XREF_VERSION_CD,
					   CREATED_DT, LAST_MODIFIED_USER_NM, LAST_MODIFIED_DT, ACTION_CD)
					 Values
					   (ln_tsr_id, 1, lr_port_data.port_id, lr_port_data.port_version_no,
					   1, 'PORT', 'PORT SERVICE XREF', lr_cpe_data.RECORD_VERSION_CD,
					   sysdate, 'TSR_BACKFILL', sysdate, 'A');
					   
					Insert into PORT_ENTITY_XREF
					   (PORT_ID, PORT_VERSION_NO, RECORD_ID, RECORD_VERSION_NO,
					   XREF_VERSION_NO, ENTITY_NM, RECORD_TYPE_CD, XREF_VERSION_CD,
					   CREATED_DT, LAST_MODIFIED_USER_NM, LAST_MODIFIED_DT, ACTION_CD)
					 Values
					   (lr_port_data.port_id, lr_port_data.port_version_no, ln_tsr_id, 1,
					   1, 'SERVICE', 'PORT SERVICE XREF', lr_cpe_data.RECORD_VERSION_CD,
					   sysdate, 'TSR_BACKFILL', sysdate, 'A');
					
					--Create TSR to CPE Xref
					Insert into SERVICE_ENTITY_XREF
					   (SERVICE_ID, SERVICE_VERSION_NO, RECORD_ID, RECORD_VERSION_NO,
					   XREF_VERSION_NO, ENTITY_NM, RECORD_TYPE_CD, XREF_VERSION_CD,
					   CREATED_DT, LAST_MODIFIED_USER_NM, LAST_MODIFIED_DT, ACTION_CD)
					 Values
					   (ln_tsr_id, 1, lr_cpe_data.router_id, lr_cpe_data.router_version_no,
					   1, 'ROUTER', 'ROUTER SERVICE XREF', lr_cpe_data.RECORD_VERSION_CD,
					   sysdate, 'TSR_BACKFILL', sysdate, 'A');
					
					Insert into ROUTER_ENTITY_XREF
					   (ROUTER_ID, ROUTER_VERSION_NO, RECORD_ID, RECORD_VERSION_NO,
					   XREF_VERSION_NO, ENTITY_NM, RECORD_TYPE_CD, XREF_VERSION_CD,
					   CREATED_DT, LAST_MODIFIED_USER_NM, LAST_MODIFIED_DT, ACTION_CD)
					 Values
					   (lr_cpe_data.router_id, lr_cpe_data.router_version_no, ln_tsr_id, 1,
					   1, 'SERVICE', 'ROUTER SERVICE XREF', lr_cpe_data.RECORD_VERSION_CD,
					   sysdate, 'TSR_BACKFILL', sysdate, 'A');
					
					--Insert into Overflow attribute
					Insert into OVERFLOW_ATTRIBUTE
					   (RECORD_ID, RECORD_VERSION_NO, ATTRIBUTE_NM, ENTITY_NM, ATTRIBUTE_VAL)
					 Values
					   (ln_tsr_id, 1, 'EQUIP_STATUS', 'SERVICE', 'EXISTING');
					
					--Call OES
					L_OES_LIMS.P_POPULATE_REL_TABLE(lr_tsr_backfill_data.EQ_ATL_SEID, ln_tsr_seid || ':Transport Service Relationship', os_err_msg, on_return);
					ls_err_txt := ls_err_txt || os_err_msg;
					if on_return = 0 then
					--insert into tsr_backfil
						update corp.TSR_BACKFILL_TEMP set TSR_BTL_SEID = ln_tsr_seid, error_txt = ls_err_txt, PROCESSED_IND = 'Y', PROCESSED_DT = sysdate where PORT_BTL_SEID = lr_port_data.service_element_id and CPE_BTL_SEID = lr_cpe_data.service_element_id;
					else
						update corp.TSR_BACKFILL_TEMP set TSR_BTL_SEID = ln_tsr_seid, error_txt = ls_err_txt, PROCESSED_IND = 'N', PROCESSED_DT = sysdate where PORT_BTL_SEID = lr_port_data.service_element_id and CPE_BTL_SEID = lr_cpe_data.service_element_id;
					end if;
				end if;
			else
				update corp.TSR_BACKFILL_TEMP set error_txt = ls_err_txt, PROCESSED_IND = 'N', PROCESSED_DT = sysdate where PORT_BTL_SEID = lr_tsr_backfill_data.PORT_BTL_SEID and CPE_BTL_SEID = lr_tsr_backfill_data.CPE_BTL_SEID;
				
			end if;
			
			
				
		commit;	
		--DBMS_OUTPUT.PUT_LINE('TXT: ' || ls_err_txt);
		EXCEPTION
			WHEN OTHERS THEN
				Rollback;
				ls_err_txt := ls_err_txt || SQLERRM;
				ln_err_cd := SQLCODE;
				DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
				update corp.TSR_BACKFILL_TEMP set error_txt = ls_err_txt,error_cd = ln_err_cd, PROCESSED_IND = 'N', PROCESSED_DT = sysdate where PORT_BTL_SEID = lr_tsr_backfill_data.PORT_BTL_SEID and CPE_BTL_SEID = lr_tsr_backfill_data.CPE_BTL_SEID;
				commit;
				
				IF lc_cpe_seid_chk%ISOPEN THEN
				CLOSE lc_cpe_seid_chk;
                END IF;
                
                IF lc_port_seid_chk%ISOPEN THEN
                CLOSE lc_port_seid_chk;
                END IF;
				
				IF lc_cpe_to_tsr_data%ISOPEN THEN
				CLOSE lc_cpe_to_tsr_data;
                END IF;
				
				IF lc_tsr_to_port_data%ISOPEN THEN
				CLOSE lc_tsr_to_port_data;
                END IF;
				
				IF lc_port_cpe_xref_chk%ISOPEN THEN
				CLOSE lc_port_cpe_xref_chk;
                END IF;
				
            
        End;
    
    End Loop;
    DBMS_OUTPUT.PUT_LINE('END Time =>' || TO_CHAR (SYSTIMESTAMP, 'dd-mm-yyyy hh24:mi:ss.FF'));
End;
/