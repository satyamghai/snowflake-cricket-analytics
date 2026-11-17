# Snowflake Cricket Analytics

## Project Overview

An end-to-end Cricket Analytics Data Engineering project designed to ingest, transform, model, and analyze structured and semi-structured cricket match data using Snowflake SQL and Power BI.

The project implements a multi-layer data architecture to process raw JSON data into analytics-ready datasets, enabling match-level insights and performance analysis.

## Technology Stack

- **Cloud Data Warehouse:** Snowflake
- **Query Language:** SQL
- **Data Format:** JSON
- **Data Ingestion:** Snowflake Stages and COPY INTO
- **Change Data Capture:** Snowflake Streams
- **Workflow Orchestration:** Snowflake Tasks
- **Data Transformation:** SQL, LATERAL FLATTEN
- **Data Modelling:** Fact and Dimension Tables
- **Data Visualization:** Microsoft Power BI

## Data Architecture

The project follows a multi-layer data architecture implemented in Snowflake:

1. **LAND Layer:** Serves as the staging and ingestion layer, storing source JSON files in Snowflake stages and maintaining file format configurations for data loading.
2. **RAW Layer:** Ingests semi-structured cricket match data into Snowflake using COPY INTO and VARIANT data types, preserving the source data structure.
3. **CLEAN Layer:** Performs JSON parsing, nested data extraction using LATERAL FLATTEN, data type conversions, and data cleansing to produce structured datasets.
4. **CONSUMPTION Layer:** Implements analytical data modelling through fact and dimension tables, providing curated datasets for downstream reporting and business intelligence.

The processed datasets are connected to Microsoft Power BI for analytical reporting and visualization.

## Key Engineering Implementations

- Configured automated JSON ingestion using Snowflake stages and COPY INTO.
- Leveraged VARIANT data types and LATERAL FLATTEN to process nested JSON structures.
- Implemented incremental data processing using append-only Snowflake Streams.
- Automated dependent data transformation workflows using Snowflake Tasks.
- Designed fact and dimension tables to support analytical queries.
- Developed a Power BI dashboard for cricket match analysis.

## Analytics & Reporting

The Power BI dashboard provides:
- Overall cricket match statistics.
- Team-level performance analysis.
- Match-specific score analysis.
- Runs-per-over and cumulative scoring trends.

## Project Objectives

- Demonstrate end-to-end data ingestion and transformation workflows.
- Explore automated incremental processing in Snowflake.
- Apply dimensional modelling concepts.
- Convert semi-structured sports data into analytics-ready datasets.

## Repository Structure

```text
snowflake-cricket-analytics/
│
├── README.md
├── SQL/
│   ├── raw_zone.sql
│   ├── clean_zone.sql
│   ├── data_pipeline.sql
│   ├── dimension_tables.sql
│   └── fact_tables.sql
│
├── PowerBI/
│   └── cricket_analytics.pbix
│
└── Screenshots/
    ├── cricket_overview.png
    └── match_analysis.png
```

*Note: Repository structure and filenames will be aligned with the actual uploaded files.*
