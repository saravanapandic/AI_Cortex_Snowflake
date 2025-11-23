# 🔮 AI Tools for dbt

A dbt package providing AI-powered utilities to inspect, debug, and (in future releases) validate or auto-correct dbt models using Snowflake Cortex AI.

This package is in early development.  
**`Ai_Debug` is the only stable feature today.**  
Additional AI-assisted features are currently in **beta**.

---

## ✅ Stable Feature (Production-Ready)

### `Ai_Debug`
Fetches and returns the **raw Jinja-SQL code** of any dbt model.

This includes:

- Jinja expressions  
- Config blocks  
- Comments  
- All SQL logic and CTEs  
- The exact content of the model file from your project

Useful for:

- Debugging model transformations  
- Passing model code to external systems (e.g., AI validation)  
- Running internal quality checks  
- CI/CD pipelines that inspect SQL

---


### `Ai_Debug_Model` *()*
Uses Snowflake Cortex AI to:

- Validate SQL inside dbt models  
- Auto-correct simple SQL issues (missing comma, missing FROM, etc.)
- Preserve all Jinja blocks exactly  
- Canonicalize SQL (uppercase keywords, spacing, semicolon)
- Return a JSON object containing:
  - `"sql"` – corrected SQL
  - `"error_reason"` – what was fixed
  - `"able_correct"` – flag indicating correction safety

### Planned Features (Upcoming)
- **Ai_AutoFix** — apply AI corrections back into model files  
- **Ai_Documentation_Generator** — generate doc blocks & column descriptions  
- **Ai_Test_Generator** — auto-create dbt tests  
- **Ai_Model_Refactor** — AI suggestions for breaking models into logical parts  

---

## 📦 Installation

Add the package to your `packages.yml`:

```yaml
packages:
  - package: saravanpandic/AI_Cortex_Snowflake
    version: ">=0.1.0"
```

## 🛠️ Prerequisites for Enabling Snowflake Cortex
Before using any AI features in this package (such as Ai_Validate_Model), Snowflake Cortex must be enabled at the account level.

Your Snowflake administrator must run:
```
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';

```
This enables Cortex usage across supported regions and activates the AI functions required by this package

-------


## Usage Ai_Debug

1️⃣ Fetch a model’s raw code (Stable)
```
dbt run-operation Ai_Debug --args '{"model_name": "my_first_dbt_model"}'
```
### Arguments:
- `model_name` (required): The model you wish to generate unit testing YAML for.
- `inline_columns` (optional, default=False): Whether you want all columns on the same line.

This prints the model exactly as stored in your /models/ directory.

