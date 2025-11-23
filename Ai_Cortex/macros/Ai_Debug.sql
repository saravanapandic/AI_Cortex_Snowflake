{% macro Ai_Debug(model_name) %}
  {{ return(adapter.dispatch('Ai_Debug', 'cortex_ai')(model_name)) }}
{% endmacro %}

{% macro default__Ai_Debug(model_name) %}

  {% if execute %}

    {# Build node id: model.<project_name>.<model_name> #}
    {% set node_id = "model." ~ project_name ~ "." ~ model_name %}

    {% if node_id not in graph.nodes %}
      {{ exceptions.raise_compiler_error(
          "Model '" ~ model_name ~ "' not found in graph. Expected node_id: " ~ node_id
      ) }}
    {% endif %}

    {% set model_node = graph.nodes[node_id] %}
    {% set model_code = model_node.raw_code %}

    
    {% set Ai_return_model = Ai_Validate_Model(model_code) %}
    {% do return(model_code) %}

  {% endif %}

{% endmacro %}
