REM
REM     Script:        acquire_cocc.sql
REM     Author:        Quanwen Zhao
REM     Dated:         Oct 11, 2021
REM
REM     Last tested:
REM             11.2.0.4
REM             19.3.0.0
REM             21.3.0.0
REM
REM     Purpose:
REM       You can find out metric_name "Current Open Cursors Count" and metric_unit "Cursors" in the view "v$metric".
REM       Typically there saves the average value of "Current Open Cursors Count" in each of snap_id of the SDDV (Static Data
REM       Dictionary View), "DBA_HIST_SYSMETRIC_SUMMARY", (in which the value of its column "metric_name" is
REM       "Current Open Cursors Count" and "metric_unit" is "Cursors"), here we use the analytic function "LAG () OVER()"
REM       to get the prior snap_id from current snap_id for more clearly showing "Current Open Cursors Count" between these two snap_id.
REM
REM       SET LINESIZE 80
REM       DESC acquire_current_open_cursors_count
REM        Name                                      Null?    Type
REM        ----------------------------------------- -------- ----------------------------
REM        INSTANCE_NUMBER                           NOT NULL NUMBER
REM        FIRST_SNAP_ID                             NOT NULL NUMBER
REM        SECOND_SNAP_ID                            NOT NULL NUMBER
REM        BEGIN_TIME                                NOT NULL DATE
REM        END_TIME                                  NOT NULL DATE
REM        METRIC_NAME                               NOT NULL VARCHAR2(28)
REM        METRIC_UNIT                               NOT NULL VARCHAR2(12)
REM        COCC                                               NUMBER
REM
REM     References:
REM       https://docs.oracle.com/en/database/oracle/oracle-database/19/refrn/DBA_HIST_SYSMETRIC_SUMMARY.html#GUID-E6377E5F-1FFF-4563-850F-C361B9D85048
REM

SET LINESIZE 200
SET PAGESIZE 200

COLUMN metric_name FORMAT a28
COLUMN metric_unit FORMAT a12
COLUMN cocc        FORMAT 999,999,999

ALTER SESSION SET nls_date_format = 'yyyy-mm-dd hh24:mi:ss';

SELECT *
FROM (
       SELECT instance_number
            , LAG(snap_id, 1, 0) OVER(PARTITION BY dbid, instance_number ORDER BY snap_id) first_snap_id
            , snap_id second_snap_id
            , begin_time
            , end_time
            , metric_name
            , metric_unit
            , ROUND(average, 2) cocc
       FROM dba_hist_sysmetric_summary
       WHERE metric_name = 'Current Open Cursors Count'
       ORDER BY instance_number
              , first_snap_id
     )
WHERE first_snap_id <> 0
;
