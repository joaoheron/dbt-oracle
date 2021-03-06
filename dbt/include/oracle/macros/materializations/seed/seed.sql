{% macro basic_load_csv_rows_oracle(model, batch_size, agate_table) %}
    {% set cols_sql = get_seed_column_quoted_csv(model, agate_table.column_names) %}
    {% set bindings = [] %}

    {% set statements = [] %}

    {% for chunk in agate_table.rows | batch(batch_size) %}
        {% set bindings = [] %}

        {% set sql %}
            insert into {{ this.render() }} ({{ cols_sql }})
            {% for row in chunk -%}
                select
                {%- for column in agate_table.column_names -%}
                    {{" '" + row[loop.index - 1] + "' " }}
                    {%- if not loop.last%},{%- endif %}
                {%- endfor -%}
                from dual {{" "}}
                {%- if not loop.last%} union all {{" "}} {%- endif %}
            {%- endfor %}
        {% endset %}

        {% do adapter.add_query(sql, bindings=bindings, abridge_sql_log=True) %}

        {% if loop.index0 == 0 %}
            {% do statements.append(sql) %}
        {% endif %}
    {% endfor %}

    {# Return SQL so we can render it out into the compiled files #}
    {{ return(statements[0]) }}
{% endmacro %}

{% macro oracle__load_csv_rows(model, agate_table) %}
  {{ return(basic_load_csv_rows_oracle(model, 10000, agate_table) )}}
{% endmacro %}
