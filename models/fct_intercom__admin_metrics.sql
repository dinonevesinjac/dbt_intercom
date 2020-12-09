with fct_conversation_metrics as (
  select *
  from {{ ref('fct_intercom__conversation_metrics') }}
  where conversation_assignee_type = 'admin'
),

admin_table as (
    select *
    from {{ ref('stg_intercom__admin') }}
),

admin_metrics as (
    select
        last_close_by_admin_id,
        sum(case when fct_conversation_metrics.conversation_state = 'closed' then 1 else 0 end) as total_conversations_closed,
        round(avg(fct_conversation_metrics.count_total_parts),2) as average_conversation_parts,
        avg(fct_conversation_metrics.conversation_rating) as average_conversation_rating
    from fct_conversation_metrics

    group by 1
),

median_metrics as (
    select distinct
        last_close_by_admin_id,
        round({{ fivetran_utils.median("fct_conversation_metrics.count_reopens", "last_close_by_admin_id") }}, 2) as median_conversations_reopened,
        round({{ fivetran_utils.median("fct_conversation_metrics.count_assignments", "last_close_by_admin_id") }}, 2) as median_conversation_assignments,
        round({{ fivetran_utils.median("fct_conversation_metrics.time_to_first_response", "last_close_by_admin_id") }}, 2) as median_time_to_first_response_time,
        round({{ fivetran_utils.median("fct_conversation_metrics.time_to_first_close", "last_close_by_admin_id") }}, 2) as median_time_to_first_close,
        round({{ fivetran_utils.median("fct_conversation_metrics.time_to_last_close", "last_close_by_admin_id") }}, 2) as median_time_to_last_close
    from fct_conversation_metrics
),

final as (
    select distinct
        admin_table.admin_id,
        admin_table.name as admin_name,
        admin_table.job_title,
        admin_metrics.total_conversations_closed,
        admin_metrics.average_conversation_parts,
        admin_metrics.average_conversation_rating,
        median_metrics.median_conversations_reopened,
        median_metrics.median_conversation_assignments,
        median_metrics.median_time_to_first_response_time,
        median_metrics.median_time_to_last_close
    from admin_table

    left join admin_metrics
        on admin_metrics.last_close_by_admin_id = admin_table.admin_id

    left join median_metrics
        on median_metrics.last_close_by_admin_id = admin_table.admin_id 
)

select * 
from final