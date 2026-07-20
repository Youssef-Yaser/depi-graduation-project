-- =====================================================
-- STORED PROCEDURE: LOAD ZIPPED CSV INTO RAW TABLE
-- =====================================================
-- Extracts the first CSV file found inside a ZIP archive staged in
-- Snowflake and loads it into the target raw table as string columns
-- (BTS source data uses empty strings instead of NULLs, so columns
-- are loaded as VARCHAR and cast later in dbt staging models)

CREATE OR REPLACE PROCEDURE BTS_AIRLINE_DB.RAW.LOAD_ZIP_DATA(
    FILE_RELATIVE_PATH VARCHAR,
    TARGET_TABLE VARCHAR
)
RETURNS VARCHAR
LANGUAGE PYTHON
RUNTIME_VERSION = '3.8'
PACKAGES = ('snowflake-snowpark-python', 'pandas')
HANDLER = 'load_zipped_csv'
EXECUTE AS OWNER
AS
$$

import io
import zipfile
import pandas as pd

from snowflake.snowpark.files import SnowflakeFile


def load_zipped_csv(session, file_relative_path, target_table):

    with SnowflakeFile.open(file_relative_path, 'rb') as file:
        zip_content = file.read()

    with zipfile.ZipFile(io.BytesIO(zip_content)) as zip_file:

        csv_files = [
            file_name
            for file_name in zip_file.namelist()
            if file_name.endswith('.csv')
        ]

        if not csv_files:
            return "Error: No CSV file found inside ZIP archive."

        csv_file_name = csv_files[0]

        with zip_file.open(csv_file_name) as csv_file:
            df = pd.read_csv(
                csv_file,
                dtype=str,
                low_memory=False
            )

        df = df.fillna('')

    session.write_pandas(
        df,
        target_table.upper(),
        auto_create_table=True,
        overwrite=False
    )

    return (
        f"Success: File {csv_file_name} loaded successfully "
        f"into table {target_table}"
    )

$$