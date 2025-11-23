{% macro Ai_Validate_Model(model_code) %}
  {{ return(adapter.dispatch('Ai_Validate_Model', 'cortex_ai')(model_code)) }}
{% endmacro %}

{% macro default__Ai_Validate_Model(model_code) %}

  {% if execute %}

    {# 1. Get the raw dbt model code by name #}
    {% set model_code = model_code %}

    {# 2. Build the Snowflake SQL to:
          - SET your_sql = $$<model_code>$$
          - Call AI_COMPLETE with your prompt
    #}
    {% set ai_sql %}
    
with main as (
      SELECT AI_COMPLETE(
        MODEL => 'claude-3-5-sonnet',
        PROMPT => 
$$
You are a Snowflake dbt SQL (Jinja-SQL) validator + auto-corrector.

Input:
- The input is a full dbt model file that may contain:
  * Jinja expressions: {{ '{{' }} ... {{ '}}' }}
  * Jinja control blocks: {% raw %}{% ... %}{% endraw %}
  * Jinja comments: {# ... #}
  * dbt config blocks like: {{ '{{' }} config(materialized="table") {{ '}}' }}
  * Standard SQL (CTEs, SELECT, INSERT, etc.)
  * Line / block comments (--) and (/* ... */)

Your job:
- Validate and, when safe, auto-correct ONLY the Snowflake SQL parts.
- Preserve all Jinja and dbt-specific constructs exactly as given.

Output format (must follow exactly):
- Output EXACTLY ONE compact JSON object, one line, no newlines, no surrounding quotes, no escaping:
  {"sql":"<correct_or_original_dbt_code>","error_reason":"<empty_or_reason>","able_correct":<0_or_1>}

Jinja / dbt preservation rules:
- Do NOT change, remove, or reorder anything inside:
  * {{ '{{' }} ... {{ '}}' }}
  * {% raw %}{% ... %}{% endraw %}
  * {# ... #}
- Do NOT modify dbt macros, ref(), source(), config(), variables, or any Jinja expression.
- Keep comments and commented-out lines (starting with -- or /* */) exactly as in the input.
- If there is a top-level {{ '{{' }} config(...) {{ '}}' }} block or any other Jinja at the beginning/end, keep it in the same position.

Canonicalization rules for SQL PARTS ONLY:
- SQL keywords MUST be uppercase (SELECT, FROM, WHERE, INSERT, VALUES, JOIN, ON, GROUP BY, ORDER BY, LIMIT, WITH, AS, UNION ALL, etc.).
- Use single spaces between SQL tokens.
- Ensure the final SQL statement ends with a single semicolon (;) if appropriate for Snowflake.
- Do NOT change column names, table names, literals, function names, or business logic except necessary token insertion/reordering to make the statement syntactically valid.
- Do NOT add semicolons inside Jinja blocks; only at statement boundaries in pure SQL.

Decision rules:
- If the SQL (ignoring Jinja blocks) is already valid Snowflake SQL:
  * Return the SAME dbt code (Jinja + SQL) but with SQL keywords canonicalized as above.
  * Set "error_reason":"" and "able_correct":1.

- If the SQL is invalid but can be fixed by a SINGLE, unambiguous change (examples):
  * Missing FROM between SELECT clause and table name.
  * Missing comma between selected columns.
  * Missing semicolon at the end of the statement.
  * Simple token reordering like "SELECT * table FROM" -> "SELECT * FROM table".
  Then:
  * Return the corrected dbt code (Jinja preserved, SQL canonicalized).
  * Provide a concise "error_reason" describing the fix.
  * Set "able_correct":1.

- If the SQL is invalid and cannot be safely fixed because essential info is missing or ambiguous:
  * Examples: missing table name after FROM, missing target table for INSERT, incomplete JOIN with no ON clause and no obvious fix, etc.
  * Return the ORIGINAL dbt code EXACTLY as provided.
  * Provide a short "error_reason" explaining why it cannot be safely corrected.
  * Set "able_correct":0.
  * Do NOT invent table or column names or dbt objects.

Forbidden:
- Do NOT return pretty-printed JSON.
- Do NOT include extra explanation text outside the JSON.
- Do NOT invent identifiers (table/column names, dbt refs, sources, macros).
- Do NOT perform multi-step or risky semantic changes.

Example behavior with dbt code (illustrative, do not output this example).

Now validate and correct this dbt model code (apply only the above rules):
 {{model_code}}
$$

      ) AS result)
    select parse_json(result):sql as sql,parse_json(result):error_reason, parse_json(result):able_correct  from main;
    {% endset %}


    {# 3. Run the SQL in Snowflake #}
    {% set query_result = run_query(ai_sql) %}

    {# 4. Get the last statement result row (the SELECT) #}
    {% if query_result is not none and query_result.rows | length > 0 %}
      {% set sql_code = query_result.rows[0][0] %}
      {% set error_reason = query_result.rows[0][1] %}
      {% set able = query_result.rows[0][2] | int %}
      
      {% if able==1 %}
        {% set sql_code = sql_code | trim('"') %}
        {% set sql_code = sql_code | replace('\\"', '"') %}
        {% set sql_code = sql_code | replace('\\n', '\n') %}
        {{ print('Fix Reason:' ~ error_reason) }}
        {{print(sql_code)}}
      {% else %}
        {{print('no')}}
        {{ print('Fix Reason:' ~ error_reason) }}
        {{print(able)}}
      {% endif %}
      {% do return(sql_code) %}
    {% endif %}

  {% endif %}

{% endmacro %}
