*---------------------------------------------------------*
* 程序名称：客户主数据批导
* 程序名：  ZSDB011
* 开发日期：2020-02-25
* 创建者：   WEIXP
*---------------------------------------------------------*
* 概要说明
*---------------------------------------------------------*
*  客户主数据批导
*---------------------------------------------------------*
* 变更记录
*    日期     修改者    传输请求号    修改内容及原因
*---------------------------------------------------------*
* yyyy-mm-dd    张三     DEVK90000     因为.......所以修改了.....
* yyyy-mm-dd    李四     DEVK90010     因为.......所以修改了.....
*---------------------------------------------------------*

REPORT zsdb011.

*----------------------------------------------------------------------*
* TYPE-POOLS/定义类型池
*----------------------------------------------------------------------*
TYPE-POOLS:icon.
*----------------------------------------------------------------------*
* TABLES/声明数据库表
*----------------------------------------------------------------------*
TABLES: sscrfields. "选择屏幕自定义功能码用
*----------------------------------------------------------------------*
* TYPE/自定义类型
*----------------------------------------------------------------------*

TYPES:BEGIN OF ty_basisdata,
        grouping           TYPE bu_group,    "业务伙伴分组
        bu_role            TYPE bu_role,     "角色
        kunnr              TYPE  kunnr,      "客户
        name1              TYPE  bu_nameor1, "组织名称1
        name2              TYPE  bu_nameor2, "组织名称2
        searchterm1        TYPE  bu_sort1,   "业务伙伴的搜索词 1
        searchterm2        TYPE  bu_sort2,   "业务伙伴的搜索词 2
        street             TYPE  ad_street,  "街道
        postl_cod1         TYPE  ad_pstcd1,  "邮编
        city               TYPE  ad_city1,   "城市
        countryiso         TYPE  intca,      "国家
        region             TYPE  regio,      "地区
        languiso           TYPE  laiso,      "语言
        telephone          TYPE  ad_tlnmbr,  "电话号码
        authorizationgroup TYPE  bu_augrp,   "权限组
        taxnumxl           TYPE  bptaxnumxl, "税号
        taxkd              TYPE  takld,      "客户税分类
        zz_yhzh            TYPE  char255,    "银行账户及开户行
        zz_kpdz            TYPE  char255,    "开票地址及电话
        guid               TYPE  bu_partner_guid,
      END OF ty_basisdata.


TYPES:BEGIN OF ty_companydata,
        bu_role TYPE  bu_role,    "角色
        kunnr   TYPE  kunnr,      "客户
        bukrs   TYPE  bukrs,      "公司
        akont   TYPE  akont,      "统御科目
        wbrsl   TYPE  wbrsl,      "坏账计提
      END OF ty_companydata.


TYPES:BEGIN OF ty_salesdata,
*        BU_ROLE     TYPE  BU_ROLE,    "角色
        kunnr TYPE  kunnr,      "客户
        vkorg TYPE  vkorg,      "销售组织
        vtweg TYPE  vtweg,      "分销渠道
        spart TYPE  spart,      "产品组
        vkbur TYPE  vkbur,      "销售办事处
        kalks TYPE  kalks,      "定价过程
        vsbed TYPE  vsbed,      "装运条件
        inco1 TYPE  inco1,      "国际贸易条款（第 1 部分）
        ktgrd TYPE  ktgrd,      "账户分配组
*        pernr TYPE  pernr_d,    "销售雇员
      END OF ty_salesdata.

TYPES:BEGIN OF ty_log,
        icon    TYPE icon_d,
        message TYPE bapi_msg,
        kunnr   TYPE kunnr,      "客户
*        vkorg   TYPE vkorg,      "销售组织
*        vtweg   TYPE vtweg,      "分销渠道
*        spart   TYPE spart,      "产品组
*        bukrs   TYPE bukrs,      "公司
      END OF ty_log.
*----------------------------------------------------------------------*
* INTERNAL TABLE AND WORK AREA/定义内表和工作区及结构
*----------------------------------------------------------------------*
DATA: gt_basisdata   TYPE TABLE OF ty_basisdata , "WITH  UNIQUE SORTED KEY key1 COMPONENTS kunnr,
      gs_basisdata   TYPE ty_basisdata,

      gt_salesdata   TYPE TABLE OF ty_salesdata  WITH  NON-UNIQUE SORTED KEY key1 COMPONENTS kunnr,
      gs_salesdata   TYPE  ty_salesdata,

      gt_companydata TYPE TABLE OF ty_companydata WITH NON-UNIQUE SORTED KEY key1 COMPONENTS kunnr,
      gs_companydata TYPE  ty_companydata,

      gt_log         TYPE TABLE OF ty_log,
      gs_log         TYPE  ty_log,

      gv_percent     TYPE i,
      gv_text        TYPE string,

      gs_functxt     TYPE smp_dyntxt. "菜单制作器:动态文本的程序接口
*----------------------------------------------------------------------*
* VARIABLE/定义变量
*----------------------------------------------------------------------*

*----------------------------------------------------------------------*
* Constants/常量定义
*----------------------------------------------------------------------*

*----------------------------------------------------------------------*
* Define the Macros/定义宏
*----------------------------------------------------------------------*

*----------------------------------------------------------------------*
* SELECTION  SCREEN/定义屏幕
*----------------------------------------------------------------------*
SELECTION-SCREEN: FUNCTION KEY 1."在屏幕定义功能码
PARAMETERS p_path TYPE string  MEMORY ID filename. "使用memoryid
*PARAMETERS p_creat RADIOBUTTON GROUP g1 DEFAULT 'X'.
*PARAMETERS p_chang RADIOBUTTON GROUP g1 .

*----------------------------------------------------------------------*
* INITIALIZATION/初始事件
*----------------------------------------------------------------------*

INITIALIZATION.
  gs_functxt-icon_id   = icon_export.
  gs_functxt-quickinfo = '下载模板'.
  gs_functxt-icon_text = '下载模板'.
  sscrfields-functxt_01 = gs_functxt.
*----------------------------------------------------------------------*
* AT SELECTION-SCREEN/屏幕事件
*----------------------------------------------------------------------*
AT SELECTION-SCREEN.
  CASE sscrfields-ucomm.
    WHEN 'FC01'."系统预留的功能码
      "下载模板文件
      PERFORM download_excel.
    WHEN OTHERS.

  ENDCASE.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_path.
  PERFORM frm_get_path CHANGING p_path.
*----------------------------------------------------------------------*
* START-OF-SELECTION/开始选择事件
*----------------------------------------------------------------------*
START-OF-SELECTION.
* 权限检查
  PERFORM frm_auth_check.
  PERFORM frm_get_data_from_excel USING p_path.
  PERFORM frm_creat_customerdata.

*----------------------------------------------------------------------*
* End-of-selection/结束选择事件
*----------------------------------------------------------------------*
END-OF-SELECTION.

  PERFORM frm_display_log.


*&---------------------------------------------------------------------*
*&      Form  DOWNLOAD_EXCEL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM download_excel .
  DATA:
    lv_fullpath TYPE string,
    lv_path     TYPE string,
    lv_name     TYPE string.



* 用户选择保存路径
  PERFORM frm_get_fullpath CHANGING lv_fullpath lv_path lv_name.

* 路径为空则退出
  IF lv_fullpath IS INITIAL.
    MESSAGE '用户取消操作' TYPE 'S'.
    RETURN.
  ENDIF.

  "下载模板
  PERFORM frm_download_excel_from_server USING lv_fullpath.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  FRM_GET_FULLPATH
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM frm_get_fullpath  CHANGING cv_fullpath
                                cv_path
                                cv_name.

  DATA: lv_init_path  TYPE string,
        lv_init_fname TYPE string,
        lv_path       TYPE string,
        lv_filename   TYPE string,
        lv_fullpath   TYPE string.

* 初始名称(输出的文件名称)
  lv_init_fname = '客户主数据批导模板' && '.xlsx'.

* 获取桌面路径
  CALL METHOD cl_gui_frontend_services=>get_desktop_directory
    CHANGING
      desktop_directory    = lv_init_path
    EXCEPTIONS
      cntl_error           = 1
      error_no_gui         = 2
      not_supported_by_gui = 3
      OTHERS               = 4.
  CALL METHOD cl_gui_cfw=>flush( ).
  IF lv_init_path IS INITIAL.
    EXIT.
  ENDIF.
* 用户选择名称、路径
  CALL METHOD cl_gui_frontend_services=>file_save_dialog
    EXPORTING
*     window_title         = '指定保存文件名'
      default_extension    = 'XLSX'
      default_file_name    = lv_init_fname
      file_filter          = cl_gui_frontend_services=>filetype_excel "文件类型 all代表全部类型，但是下载输出时必须指明文件类型，不然是白的
      initial_directory    = lv_init_path
      prompt_on_overwrite  = 'X'
    CHANGING
      filename             = lv_filename
      path                 = lv_path
      fullpath             = lv_fullpath
*     USER_ACTION          =
*     FILE_ENCODING        =
    EXCEPTIONS
      cntl_error           = 1
      error_no_gui         = 2
      not_supported_by_gui = 3
      OTHERS               = 4.
  IF sy-subrc = 0.
    cv_fullpath = lv_fullpath.
    cv_path     = lv_path.
    cv_name = lv_filename.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  FRM_DOWNLOAD_EXCEL_FROM_SERVER
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM frm_download_excel_from_server  USING    p_filename.

  DATA: l_objdata     LIKE wwwdatatab,
        l_mime        LIKE w3mime,
        l_destination LIKE rlgrap-filename,
        l_objnam      TYPE string,
        l_rc          LIKE sy-subrc,
        l_errtxt      TYPE string.

  DATA: l_filename TYPE string,
        l_result,
        l_subrc    TYPE sy-subrc.

  DATA: l_objid TYPE wwwdatatab-objid .

  l_objid = 'ZSDB011'.  "上传的模版名称      需要下载的模板名称

  "查找文件是否存在。
  SELECT SINGLE relid objid
    FROM wwwdata
    INTO CORRESPONDING FIELDS OF l_objdata
    WHERE srtf2    = 0
    AND   relid    = 'MI'
    AND   objid    = l_objid.

  "判断模版不存在则报错
  IF sy-subrc NE 0 OR l_objdata-objid EQ space.
    CONCATENATE '模板文件：' l_objid '不存在，请用TCODE：SMW0进行加载'
    INTO l_errtxt.
    MESSAGE e000(su) WITH l_errtxt.
  ENDIF.

  l_filename = p_filename.

  "判断本地地址是否已经存在此文件。
  CALL METHOD cl_gui_frontend_services=>file_exist
    EXPORTING
      file                 = l_filename
    RECEIVING
      result               = l_result
    EXCEPTIONS
      cntl_error           = 1
      error_no_gui         = 2
      wrong_parameter      = 3
      not_supported_by_gui = 4
      OTHERS               = 5.
  IF l_result EQ 'X'.  "如果存在则删除原始文件，重新覆盖
    CALL METHOD cl_gui_frontend_services=>file_delete
      EXPORTING
        filename             = l_filename
      CHANGING
        rc                   = l_subrc
      EXCEPTIONS
        file_delete_failed   = 1
        cntl_error           = 2
        error_no_gui         = 3
        file_not_found       = 4
        access_denied        = 5
        unknown_error        = 6
        not_supported_by_gui = 7
        wrong_parameter      = 8
        OTHERS               = 9.
    IF l_subrc <> 0. "如果删除失败，则报错。
      CONCATENATE '同名EXCEL文件已打开' '请关闭该EXCEL后重试。'
      INTO l_errtxt.
      MESSAGE e000(su) WITH l_errtxt.
    ENDIF.
  ENDIF.

  l_destination   = p_filename.

  "下载模版。
  CALL FUNCTION 'DOWNLOAD_WEB_OBJECT'
    EXPORTING
      key         = l_objdata
      destination = l_destination
    IMPORTING
      rc          = l_rc.
  IF l_rc NE 0.
    CONCATENATE '模板文件' '下载失败' INTO l_errtxt.
    MESSAGE e000(su) WITH l_errtxt.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_get_data_from_excel
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_get_data_from_excel  USING   iv_path.

  DATA lt_exceltab TYPE TABLE OF zalsmex_tabline WITH HEADER LINE.

  DATA lv_filepath  TYPE rlgrap-filename   .
  gv_text = |上传基础数据...|.
  PERFORM frm_process_indicator USING gv_percent gv_text.
  lv_filepath = iv_path.
  CALL FUNCTION 'ZALSM_EXCEL_TO_INTERNAL_TABLE'
    EXPORTING
      filename                = lv_filepath
      sheet_name              = '基础数据批导模板'
      i_begin_col             = 1
      i_begin_row             = 3
      i_end_col               = 19
      i_end_row               = 10000
    TABLES
      intern                  = lt_exceltab
    EXCEPTIONS
      inconsistent_parameters = 1
      upload_ole              = 2
      OTHERS                  = 3.
  IF sy-subrc <> 0.
    MESSAGE '上传EXCEL失败!' TYPE 'S' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.

  LOOP AT lt_exceltab .

    CONDENSE lt_exceltab-value.
    ASSIGN COMPONENT lt_exceltab-col OF STRUCTURE gs_basisdata TO FIELD-SYMBOL(<lf_any>).  "将值修改为接受数据的內表和工作区

    IF sy-subrc EQ 0.
      <lf_any> = lt_exceltab-value.
    ENDIF.

    AT END OF row.

      APPEND gs_basisdata TO gt_basisdata.  "将值修改为接受数据的內表和工作区
      CLEAR gs_basisdata.             "将值修改为接受数据的內表和工作区
    ENDAT.
  ENDLOOP.


  REFRESH lt_exceltab.
  gv_text = |上传财务数据...|.
  PERFORM frm_process_indicator USING gv_percent gv_text.

  CALL FUNCTION 'ZALSM_EXCEL_TO_INTERNAL_TABLE'
    EXPORTING
      filename                = lv_filepath
      sheet_name              = '财务数据批导模板'
      i_begin_col             = 1
      i_begin_row             = 3
      i_end_col               = 5
      i_end_row               = 10000
    TABLES
      intern                  = lt_exceltab
    EXCEPTIONS
      inconsistent_parameters = 1
      upload_ole              = 2
      OTHERS                  = 3.
  IF sy-subrc <> 0.
    MESSAGE '上传EXCEL失败!' TYPE 'S' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.

  LOOP AT lt_exceltab .

    CONDENSE lt_exceltab-value.
    ASSIGN COMPONENT lt_exceltab-col OF STRUCTURE gs_companydata TO <lf_any>.  "将值修改为接受数据的內表和工作区

    IF sy-subrc EQ 0.
      <lf_any> = lt_exceltab-value.
    ENDIF.


    AT END OF row.

      APPEND gs_companydata TO gt_companydata.  "将值修改为接受数据的內表和工作区
      CLEAR gs_companydata.             "将值修改为接受数据的內表和工作区
    ENDAT.

  ENDLOOP.

  REFRESH lt_exceltab.
  gv_text = |上传销售数据...|.
  PERFORM frm_process_indicator USING gv_percent gv_text.
  CALL FUNCTION 'ZALSM_EXCEL_TO_INTERNAL_TABLE'
    EXPORTING
      filename                = lv_filepath
      sheet_name              = '销售数据批导模板'
      i_begin_col             = 1
      i_begin_row             = 3
      i_end_col               = 10
      i_end_row               = 10000
    TABLES
      intern                  = lt_exceltab
    EXCEPTIONS
      inconsistent_parameters = 1
      upload_ole              = 2
      OTHERS                  = 3.
  IF sy-subrc <> 0.
    MESSAGE '上传EXCEL失败!' TYPE 'S' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.

  LOOP AT lt_exceltab .

    CONDENSE lt_exceltab-value.
    ASSIGN COMPONENT lt_exceltab-col OF STRUCTURE gs_salesdata TO <lf_any>.  "将值修改为接受数据的內表和工作区

    IF sy-subrc EQ 0.
      <lf_any> = lt_exceltab-value.
    ENDIF.


    AT END OF row.

      APPEND gs_salesdata TO gt_salesdata.  "将值修改为接受数据的內表和工作区
      CLEAR gs_salesdata.                   "将值修改为接受数据的內表和工作区
    ENDAT.

  ENDLOOP.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_get_path
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- P_PATH
*&---------------------------------------------------------------------*
FORM frm_get_path  CHANGING cv_path.
  DATA lt_filetab TYPE filetable.
  DATA lv_rc TYPE i.
  CALL METHOD cl_gui_frontend_services=>file_open_dialog
    EXPORTING
      window_title            = '请选择要上传的文件'
      file_filter             = cl_gui_frontend_services=>filetype_excel
    CHANGING
      file_table              = lt_filetab
      rc                      = lv_rc
    EXCEPTIONS
      file_open_dialog_failed = 1
      cntl_error              = 2
      error_no_gui            = 3
      not_supported_by_gui    = 4
      OTHERS                  = 5.
  IF sy-subrc <> 0.
    MESSAGE '获取上传文件路径失败!' TYPE 'S' DISPLAY LIKE 'E'..
  ELSE.
    READ TABLE lt_filetab INTO DATA(ls_filetab) INDEX 1.
    cv_path = ls_filetab-filename.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_AUTH_CHECK
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_auth_check .

ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_display_log
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_display_log .
  DATA lr_columns TYPE REF TO cl_salv_columns_table.
  DATA lr_column  TYPE REF TO cl_salv_column.
  DATA lr_functions TYPE REF TO cl_salv_functions.

  TRY.
      CALL METHOD cl_salv_table=>factory
*    EXPORTING
*      LIST_DISPLAY   = IF_SALV_C_BOOL_SAP=>FALSE
*      R_CONTAINER    =
*      CONTAINER_NAME =
        IMPORTING
          r_salv_table = DATA(lr_salv)
        CHANGING
          t_table      = gt_log.


      lr_salv->get_functions_base( )->set_all( ).

      lr_columns = lr_salv->get_columns( ).
      lr_columns->set_optimize( 'X' ).



      lr_column = lr_columns->get_column( 'ICON' ).
      lr_column->set_long_text( '状态' ).
      lr_column->set_medium_text( '状态' ).
      lr_column->set_short_text( '状态' ).

      lr_salv->display( ).
    CATCH cx_root INTO DATA(lr_error).
  ENDTRY.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form frm_creat_customerdata
*&---------------------------------------------------------------------*
*&  "创建客户主数据
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_creat_customerdata .
  DATA lt_data TYPE cvis_ei_extern_t.
  DATA ls_data TYPE cvis_ei_extern.

  DATA lt_return TYPE bapiretm.
  DATA ls_return TYPE bapireti.

  DATA lv_guid TYPE bu_partner_guid.
  DATA lv_string TYPE string.

  gv_text = |检查数据...|.
  PERFORM frm_process_indicator USING gv_percent gv_text.

  LOOP AT gt_basisdata ASSIGNING FIELD-SYMBOL(<ls_basisdata>).

    IF <ls_basisdata>-kunnr IS INITIAL.
      gt_log = VALUE #( BASE gt_log (  kunnr = <ls_basisdata>-kunnr
                                     icon = icon_led_red  message = |基础数据第{ sy-tabix }行客户字段未输入!| ) ).
      DELETE gt_basisdata .
      CONTINUE.
    ELSE.
      <ls_basisdata>-kunnr = |{ <ls_basisdata>-kunnr ALPHA = IN }|.
    ENDIF.
  ENDLOOP.

  LOOP AT gt_salesdata ASSIGNING FIELD-SYMBOL(<ls_salesdata>).

    IF <ls_salesdata>-kunnr IS INITIAL OR <ls_salesdata>-vkorg IS INITIAL OR <ls_salesdata>-vtweg IS INITIAL OR <ls_salesdata>-spart IS INITIAL. .
      gt_log = VALUE #( BASE gt_log (  kunnr = <ls_basisdata>-kunnr
                                     icon = icon_led_red  message = |销售数据第{ sy-tabix }行主键缺失!| ) ).
      DELETE gt_salesdata .
      CONTINUE.
    ELSE.
      <ls_salesdata>-kunnr = |{ <ls_salesdata>-kunnr ALPHA = IN }|.
    ENDIF.

    CLEAR lv_string.
    lv_string = COND #( WHEN <ls_salesdata>-kalks IS INITIAL THEN '客户定价过程不允许空值!'
                        WHEN <ls_salesdata>-vsbed IS INITIAL THEN '装运条件不允许空值!'
                        WHEN <ls_salesdata>-ktgrd IS INITIAL THEN '账户分配组不允许空值!' ).
    IF lv_string IS NOT INITIAL.
      gt_log = VALUE #( BASE gt_log (  kunnr = <ls_basisdata>-kunnr
                                    icon = icon_led_red  message = |销售数据第{ sy-tabix }行{ lv_string }| ) ).
      DELETE gt_salesdata.
    ENDIF.

  ENDLOOP.

  LOOP AT gt_companydata ASSIGNING FIELD-SYMBOL(<ls_companydata>).

    IF <ls_companydata>-kunnr IS INITIAL OR <ls_companydata>-bukrs IS INITIAL  .
      gt_log = VALUE #( BASE gt_log (  kunnr = <ls_companydata>-kunnr
                                     icon = icon_led_red  message = |财务数据第{ sy-tabix }行主键缺失!| ) ).
      DELETE gt_companydata .
      CONTINUE.
    ELSE.
      <ls_companydata>-kunnr = |{ <ls_companydata>-kunnr ALPHA = IN }|.
    ENDIF.
  ENDLOOP.


  SORT gt_salesdata .
  DESCRIBE TABLE gt_basisdata LINES DATA(lv_lines).
  LOOP AT gt_basisdata ASSIGNING <ls_basisdata>.

    gv_text = |创建客户:{ sy-tabix }/{ lv_lines }.|.
    PERFORM frm_process_indicator USING gv_percent gv_text.

    CLEAR ls_data.

    ls_data-partner-header-object_task = 'I'.
    ls_data-partner-header-object_instance-bpartner = <ls_basisdata>-kunnr.
    TRY.
        <ls_basisdata>-guid =  cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_root.

    ENDTRY.
    ls_data-partner-header-object_instance-bpartnerguid = <ls_basisdata>-guid.
    "业务伙伴类别
    ls_data-partner-central_data-common-data-bp_control-category = '2'.
    "账户组
    ls_data-partner-central_data-common-data-bp_control-grouping = <ls_basisdata>-grouping.
    "角色
    ls_data-partner-central_data-role-roles = VALUE #( ( task = 'I' data_key = <ls_basisdata>-bu_role ) ).


    "名称1
    ls_data-partner-central_data-common-data-bp_organization-name1 = <ls_basisdata>-name1.
    ls_data-partner-central_data-common-datax-bp_organization-name1 = 'X'.
    "名称2
    ls_data-partner-central_data-common-data-bp_organization-name2 = <ls_basisdata>-name2.
    ls_data-partner-central_data-common-datax-bp_organization-name2 = 'X'.

    "索引1
    ls_data-partner-central_data-common-data-bp_centraldata-searchterm1 = <ls_basisdata>-searchterm1.
    ls_data-partner-central_data-common-datax-bp_centraldata-searchterm1 = 'X'.

    "索引2
    ls_data-partner-central_data-common-data-bp_centraldata-searchterm2 = <ls_basisdata>-searchterm2.
    ls_data-partner-central_data-common-datax-bp_centraldata-searchterm2 = 'X'.


    "地址
    DATA ls_address TYPE bus_ei_bupa_address.
    DATA ls_addr_usages TYPE bus_ei_bupa_addressusage.
    ls_address-data_key-guid = ls_data-partner-header-object_instance-bpartnerguid.
    ls_address-data_key-operation = 'XXDFLT'.
    ls_address-task = 'I'.

    "街道
    ls_address-data-postal-data-street = <ls_basisdata>-street.
    ls_address-data-postal-datax-street = 'X'.
    "邮编
    ls_address-data-postal-data-postl_cod1 = <ls_basisdata>-postl_cod1.
    ls_address-data-postal-datax-postl_cod1 = 'X'.
    "城市
    ls_address-data-postal-data-city = <ls_basisdata>-city.
    ls_address-data-postal-datax-city = 'X'.
    "国家
    ls_address-data-postal-data-countryiso = <ls_basisdata>-countryiso.
    ls_address-data-postal-datax-countryiso = 'X'.
    "地区
    ls_address-data-postal-data-region = <ls_basisdata>-region.
    ls_address-data-postal-datax-region = <ls_basisdata>-region.
    "语言
    ls_address-data-postal-data-languiso = <ls_basisdata>-languiso.
    ls_address-data-postal-datax-langu_iso = 'X'.

    "地址用途
    ls_addr_usages-task = 'I'.
    ls_addr_usages-data_key-addresstype = 'XXDEFAULT'.

    "电话
    DATA ls_phone TYPE bus_ei_bupa_telephone.
    ls_phone-contact-task = 'I'.
    ls_phone-contact-data-r_3_user = '3'.
    ls_phone-contact-data-telephone = <ls_basisdata>-telephone.
    ls_phone-contact-datax-r_3_user = 'X'.
    ls_phone-contact-datax-telephone = 'X'.
    APPEND ls_phone TO ls_address-data-communication-phone-phone.
    CLEAR ls_phone.

    APPEND ls_addr_usages TO  ls_address-data-addr_usage-addr_usages .
    APPEND ls_address TO ls_data-partner-central_data-address-addresses .
    CLEAR: ls_addr_usages,
          ls_address.

    "税号
    DATA ls_taxnumber TYPE bus_ei_bupa_taxnumber.
    IF <ls_basisdata>-taxnumxl IS NOT INITIAL.
      ls_taxnumber-data_key-taxtype = 'CN5'.
      ls_taxnumber-data_key-taxnumxl = <ls_basisdata>-taxnumxl.
      ls_taxnumber-data_key-taxnumber = <ls_basisdata>-taxnumxl.
      ls_taxnumber-task = 'I'.
      APPEND ls_taxnumber TO ls_data-partner-central_data-taxnumber-taxnumbers.
      CLEAR ls_taxnumber.
    ENDIF.

    "权限组
    ls_data-partner-central_data-common-data-bp_centraldata-authorizationgroup = <ls_basisdata>-authorizationgroup.
    ls_data-partner-central_data-common-datax-bp_centraldata-authorizationgroup = 'X'.

*客户数据---------------------------------------------------------------
    ls_data-customer-header-object_instance-kunnr = <ls_basisdata>-kunnr.
    ls_data-customer-header-object_task = 'I'.

    "CENTRAL_DATA:税收标识
    DATA ls_tax_ind TYPE cmds_ei_tax_ind.

    ls_tax_ind-task = 'I'.
    ls_tax_ind-data_key-aland = 'CN'.
    ls_tax_ind-data_key-tatyp = 'MWST'.
    ls_tax_ind-data-taxkd = '1'.
    ls_tax_ind-datax-taxkd = 'X'.
    APPEND ls_tax_ind TO ls_data-customer-central_data-tax_ind-tax_ind.
    CLEAR ls_tax_ind.

    "长文本
    DATA ls_text TYPE cvis_ei_text.

    ls_text-task = 'M'.
    ls_text-data_key-langu = sy-langu.
    ls_text-data_key-text_id = 'Z001'.
    ls_text-data = VALUE #( ( tdline = <ls_basisdata>-zz_yhzh ) ).
    APPEND ls_text TO ls_data-customer-central_data-text-texts.
    ls_text-task = 'M'.
    ls_text-data_key-langu = sy-langu.
    ls_text-data_key-text_id = 'Z002'.
    ls_text-data = VALUE #( ( tdline = <ls_basisdata>-zz_kpdz ) ).
    APPEND ls_text TO ls_data-customer-central_data-text-texts.

    CLEAR ls_text.

    "SALES_DATA
    DATA ls_sales TYPE cmds_ei_sales.
    DATA ls_functions TYPE cmds_ei_functions.

    LOOP AT gt_salesdata ASSIGNING <ls_salesdata>  WHERE kunnr = <ls_basisdata>-kunnr.



      ls_sales-task = 'M'.
      ls_sales-data_key-vkorg = <ls_salesdata>-vkorg.
      ls_sales-data_key-vtweg = <ls_salesdata>-vtweg.
      ls_sales-data_key-spart = <ls_salesdata>-spart.


      "销售办事处
      ls_sales-data-vkbur = <ls_salesdata>-vkbur.
      ls_sales-datax-vkbur = 'X'.

      "客户定价过程
      ls_sales-data-kalks = <ls_salesdata>-kalks.  "必输字段,否则不会报错,但也不会成功
      ls_sales-datax-kalks = 'X'.

      "装运条件
      ls_sales-data-vsbed = <ls_salesdata>-vsbed.  "必输字段,否则不会报错,但也不会成功
      ls_sales-datax-vsbed = 'X'.

      "国际贸易条款
      ls_sales-data-inco1 = <ls_salesdata>-inco1.
      ls_sales-datax-inco1 = 'X'.

      "账户分配组
      ls_sales-data-ktgrd =  <ls_salesdata>-ktgrd. "必输字段,否则不会报错,但也不会成功
      ls_sales-datax-ktgrd = 'X'.

      ls_sales-data-waers = 'CNY'.                 "必输字段,否则不会报错,但也不会成功
      ls_sales-datax-waers = 'X'.

*       <ls_salesdata>-pernr = |{ <ls_salesdata>-pernr ALPHA = IN }|.
*      ls_functions-task = 'M'.
*      ls_functions-data_key-parvw = 'VE'.
**      ls_functions-data_key-parza = '000'.
*      ls_functions-data-partner = <ls_salesdata>-pernr.
*      ls_functions-datax-partner  = 'X'.
*      APPEND ls_functions TO ls_sales-functions-functions.
*      CLEAR ls_functions.


      ls_functions-task = 'M'.
      ls_functions-data_key-parvw = 'AG'.
      ls_functions-data_key-parza = '000'.
      ls_functions-data-partner = <ls_salesdata>-kunnr.
      ls_functions-datax-partner  = 'X'.

      APPEND ls_functions TO ls_sales-functions-functions.

      ls_functions-task = 'M'.
      ls_functions-data_key-parvw = 'RE'.
      ls_functions-data_key-parza = '000'.
      ls_functions-data-partner = <ls_salesdata>-kunnr.
      ls_functions-datax-partner  = 'X'.

      APPEND ls_functions TO ls_sales-functions-functions.

      ls_functions-task = 'M'.
      ls_functions-data_key-parvw = 'RG'.
      ls_functions-data_key-parza = '000'.
      ls_functions-data-partner = <ls_salesdata>-kunnr.
      ls_functions-datax-partner  = 'X'.
      APPEND ls_functions TO ls_sales-functions-functions.

      ls_functions-task = 'M'.
      ls_functions-data_key-parvw = 'WE'.
      ls_functions-data_key-parza = '000'.
      ls_functions-data-partner = <ls_salesdata>-kunnr.
      ls_functions-datax-partner  = 'X'.
      APPEND ls_functions TO ls_sales-functions-functions.
      APPEND ls_sales TO ls_data-customer-sales_data-sales.
      CLEAR: ls_functions,
             ls_sales.

      DELETE gt_salesdata.
    ENDLOOP.

    DATA ls_company TYPE cmds_ei_company.

    LOOP AT gt_companydata ASSIGNING <ls_companydata> WHERE kunnr = <ls_basisdata>-kunnr.
      "角色

      ls_data-partner-central_data-role-roles = VALUE #( BASE ls_data-partner-central_data-role-roles
                                                          ( task = 'I' data_key = <ls_companydata>-bu_role ) ).

      ls_company-task = 'I'.
      ls_company-data_key-bukrs = <ls_companydata>-bukrs.
      ls_company-data-akont = <ls_companydata>-akont.
      ls_company-data-wbrsl = <ls_companydata>-wbrsl.
      ls_company-datax-akont = 'X'.
      ls_company-datax-wbrsl = 'X'.
      APPEND ls_company TO ls_data-customer-company_data-company.
      CLEAR ls_company.
      DELETE gt_companydata.
    ENDLOOP.
    SORT ls_data-partner-central_data-role-roles.
    DELETE ADJACENT DUPLICATES FROM ls_data-partner-central_data-role-roles .


    APPEND ls_data TO lt_data.
    CLEAR ls_data.
    CLEAR lt_return.
    CALL METHOD cl_md_bp_maintain=>maintain
      EXPORTING
        i_data   = lt_data
*       i_test_run =
      IMPORTING
        e_return = lt_return.
    .
    IF lt_return IS NOT INITIAL.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      CLEAR lv_string.
      LOOP AT lt_return[ 1 ]-object_msg INTO DATA(ls_msg) WHERE type = 'E' OR type = 'A'.
        CONCATENATE lv_string ls_msg-message INTO lv_string.
      ENDLOOP.
      gt_log = VALUE #( BASE gt_log (  kunnr = <ls_basisdata>-kunnr
                                     icon = icon_led_red  message = |创建客户失败:{ lv_string }| ) ).
    ELSE.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait = 'X'.

      gt_log = VALUE #( BASE gt_log (  kunnr = <ls_basisdata>-kunnr
                                       icon = icon_led_green  message = |创建客户成功!| ) ).
    ENDIF.
    CLEAR: lt_data.
  ENDLOOP.


  "扩展销售视图
  IF gt_salesdata IS NOT INITIAL.
    SELECT
      partner,
      partner_guid
      INTO TABLE @DATA(lt_but000)
      FROM but000
      FOR ALL ENTRIES IN @gt_salesdata
      WHERE partner = @gt_salesdata-kunnr.
    SELECT
      kunnr,
      vkorg,
      vtweg,
      spart
      INTO TABLE @DATA(lt_knvv)
      FROM knvv
      FOR ALL ENTRIES IN @gt_salesdata
      WHERE kunnr = @gt_salesdata-kunnr.

  ENDIF.

  DESCRIBE TABLE gt_salesdata LINES lv_lines.
  SORT gt_salesdata .
  LOOP AT gt_salesdata ASSIGNING <ls_salesdata>  .
    gv_text = |扩展维护销售视图:{ sy-tabix }/{ lv_lines }.|.
    PERFORM frm_process_indicator USING gv_percent gv_text.

    READ TABLE lt_knvv WITH KEY kunnr = <ls_salesdata>-kunnr vkorg = <ls_salesdata>-vkorg spart = <ls_salesdata>-spart
                      TRANSPORTING NO FIELDS.
    IF sy-subrc = 0.
      gt_log = VALUE #( BASE gt_log (  kunnr = <ls_salesdata>-kunnr
                                    icon = icon_led_red  message = |扩展维护客户销售视图失败:销售组织已存在!| ) ).
      CONTINUE.
    ENDIF.



    ls_data-partner-header-object_task = 'U'.
    ls_data-partner-header-object_instance-bpartner = <ls_salesdata>-kunnr.
    READ TABLE lt_but000 INTO DATA(ls_but000) WITH KEY partner = <ls_salesdata>-kunnr.
    ls_data-partner-header-object_instance-bpartnerguid = ls_but000-partner_guid.

    ls_data-customer-header-object_instance-kunnr = <ls_salesdata>-kunnr.
    ls_data-customer-header-object_task = 'U'.

    ls_sales-task = 'I'.
    ls_sales-data_key-vkorg = <ls_salesdata>-vkorg.
    ls_sales-data_key-vtweg = <ls_salesdata>-vtweg.
    ls_sales-data_key-spart = <ls_salesdata>-spart.
*    DELETE gt_salesdata .

    "销售办事处
    IF <ls_salesdata>-vkbur IS NOT INITIAL.
      ls_sales-data-vkbur = <ls_salesdata>-vkbur.
      ls_sales-datax-vkbur = 'X'.
    ENDIF.

    "客户定价过程
    IF <ls_salesdata>-kalks IS NOT INITIAL.
      ls_sales-data-kalks = <ls_salesdata>-kalks.
      ls_sales-datax-kalks = 'X'.
    ENDIF.
    "装运条件
    IF <ls_salesdata>-vsbed IS NOT INITIAL.
      ls_sales-data-vsbed = <ls_salesdata>-vsbed.
      ls_sales-datax-vsbed = 'X'.
    ENDIF.
    "国际贸易条款
    IF <ls_salesdata>-inco1 IS NOT INITIAL.
      ls_sales-data-inco1 = <ls_salesdata>-inco1.
      ls_sales-datax-inco1 = 'X'.
    ENDIF.

    "账户分配组
    IF <ls_salesdata>-ktgrd IS NOT INITIAL.
      ls_sales-data-ktgrd =  <ls_salesdata>-ktgrd.
      ls_sales-datax-ktgrd = 'X'.
    ENDIF.

    ls_sales-data-waers = 'CNY'.                 "必输字段,否则不会报错,但也不会成功
    ls_sales-datax-waers = 'X'.

*    "处理销售雇员
*    <ls_salesdata>-pernr = |{ <ls_salesdata>-pernr ALPHA = IN }|.
*    ls_functions-task = 'I'.
*    ls_functions-data_key-parvw = 'VE'.
**      ls_functions-data_key-parza = '000'.
*    ls_functions-data-partner = <ls_salesdata>-pernr.
*    ls_functions-datax-partner  = 'X'.
*    APPEND ls_functions TO ls_sales-functions-functions.
*    CLEAR ls_functions.

    ls_functions-task = 'M'.
    ls_functions-data_key-parvw = 'AG'.
    ls_functions-data_key-parza = '000'.
    ls_functions-data-partner = <ls_salesdata>-kunnr.
    ls_functions-datax-partner  = 'X'.

    APPEND ls_functions TO ls_sales-functions-functions.

    ls_functions-task = 'M'.
    ls_functions-data_key-parvw = 'RE'.
    ls_functions-data_key-parza = '000'.
    ls_functions-data-partner = <ls_salesdata>-kunnr.
    ls_functions-datax-partner  = 'X'.

    APPEND ls_functions TO ls_sales-functions-functions.

    ls_functions-task = 'M'.
    ls_functions-data_key-parvw = 'RG'.
    ls_functions-data_key-parza = '000'.
    ls_functions-data-partner = <ls_salesdata>-kunnr.
    ls_functions-datax-partner  = 'X'.
    APPEND ls_functions TO ls_sales-functions-functions.

    ls_functions-task = 'M'.
    ls_functions-data_key-parvw = 'WE'.
    ls_functions-data_key-parza = '000'.
    ls_functions-data-partner = <ls_salesdata>-kunnr.
    ls_functions-datax-partner  = 'X'.
    APPEND ls_functions TO ls_sales-functions-functions.
    APPEND ls_sales TO ls_data-customer-sales_data-sales.
    CLEAR: ls_functions,
           ls_sales.

    AT END OF kunnr.

      APPEND ls_data TO lt_data.
      CLEAR ls_data.
      CLEAR lt_return.
      CALL METHOD cl_md_bp_maintain=>maintain
        EXPORTING
          i_data   = lt_data
*         i_test_run =
        IMPORTING
          e_return = lt_return.
      .
      IF lt_return IS NOT INITIAL.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
        CLEAR lv_string.
        LOOP AT lt_return[ 1 ]-object_msg INTO ls_msg WHERE type = 'E' OR type = 'A'.
          CONCATENATE lv_string ls_msg-message INTO lv_string.
        ENDLOOP.
        gt_log = VALUE #( BASE gt_log (  kunnr = <ls_salesdata>-kunnr
                                       icon = icon_led_red  message = |扩展维护客户销售视图失败:{ lv_string }| ) ).
      ELSE.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING
            wait = 'X'.
        gt_log = VALUE #( BASE gt_log (  kunnr = <ls_salesdata>-kunnr
                                         icon = icon_led_green  message = |扩展维护客户销售视图成功!| ) ).
      ENDIF.
      CLEAR lt_data.

    ENDAT.

  ENDLOOP.


  "扩展公司视图
  IF gt_companydata IS NOT INITIAL.
    CLEAR lt_but000.
    SELECT
      partner,
      partner_guid
      INTO TABLE @lt_but000
      FROM but000
      FOR ALL ENTRIES IN @gt_companydata
      WHERE partner = @gt_companydata-kunnr.
  ENDIF.

  DESCRIBE TABLE gt_companydata LINES lv_lines.
  SORT gt_companydata BY kunnr.
  LOOP AT gt_companydata ASSIGNING <ls_companydata> .
    gv_text = |扩展公司视图:{ sy-tabix }/{ lv_lines }.|.
    PERFORM frm_process_indicator USING gv_percent gv_text.

    ls_data-partner-header-object_task = 'U'.
    ls_data-partner-header-object_instance-bpartner = <ls_companydata>-kunnr.
    READ TABLE lt_but000 INTO ls_but000 WITH KEY partner = <ls_companydata>-kunnr.
    ls_data-partner-header-object_instance-bpartnerguid = ls_but000-partner_guid.

    ls_data-customer-header-object_instance-kunnr = <ls_companydata>-kunnr.
    ls_data-customer-header-object_task = 'U'.

    "角色
    ls_data-partner-central_data-role-roles = VALUE #( BASE ls_data-partner-central_data-role-roles
                                                        ( task = 'M' data_key = <ls_companydata>-bu_role ) ).
    ls_company-task = 'I'.
    ls_company-data_key-bukrs = <ls_companydata>-bukrs.
    ls_company-data-akont = <ls_companydata>-akont.
    ls_company-data-wbrsl = <ls_companydata>-wbrsl.
    ls_company-datax-akont = 'X'.
    ls_company-datax-wbrsl = 'X'.
    APPEND ls_company TO ls_data-customer-company_data-company.
    CLEAR ls_company.

    AT END OF kunnr.
      SORT ls_data-partner-central_data-role-roles.
      DELETE ADJACENT DUPLICATES FROM ls_data-partner-central_data-role-roles .
      APPEND ls_data TO lt_data.
      CLEAR ls_data.
      CLEAR lt_return.
      CALL METHOD cl_md_bp_maintain=>maintain
        EXPORTING
          i_data   = lt_data
*         i_test_run =
        IMPORTING
          e_return = lt_return.
      .
      IF lt_return IS NOT INITIAL.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK' .
        CLEAR lv_string.
        LOOP AT lt_return[ 1 ]-object_msg INTO ls_msg WHERE type = 'E' OR type = 'A'.
          CONCATENATE lv_string ls_msg-message INTO lv_string.
        ENDLOOP.
        gt_log = VALUE #( BASE gt_log (  kunnr = <ls_companydata>-kunnr
                                       icon = icon_led_red  message = |扩展客户公司视图失败:{ lv_string }| ) ).
      ELSE.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING
            wait = 'X'
*         IMPORTING
*           RETURN        =
          .

        gt_log = VALUE #( BASE gt_log (  kunnr = <ls_companydata>-kunnr
                                         icon = icon_led_green  message = |扩展客户公司视图成功!| ) ).
      ENDIF.
      CLEAR lt_data.

    ENDAT.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form frm_process_indicator
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_process_indicator USING iv_percent iv_text.
  CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
    EXPORTING
      percentage = iv_percent
      text       = iv_text.

ENDFORM.
