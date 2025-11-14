import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from pyspark.context import SparkContext
from awsglue.job import Job
from pyspark.sql.functions import col, year, when, to_date

args = getResolvedOptions(sys.argv, ["JOB_NAME"])

sc = SparkContext()
glue_context = GlueContext(sc)
spark = glue_context.spark_session

job = Job(glue_context)
job.init(args["JOB_NAME"], args)

# update these to your actual bucket names
SOURCE_BUCKET = "etl-source-bucket-sagarr"
DEST_BUCKET = "etl-destination-bucket-sagarr"

source_path = f"s3://{SOURCE_BUCKET}/input/GlobalLandTemperaturesByCity.csv"
dest_path = f"s3://{DEST_BUCKET}/output/india_temperatures/"

df = (
    spark.read
    .option("header", "true")
    .option("inferSchema", "true")
    .csv(source_path)
)

# drop rows where temperature is null
df_clean = df.filter(df["AverageTemperature"].isNotNull())

df_clean = df_clean.withColumn("Year", year(to_date(col("dt"))))

# filter years 2000–2010
df_clean = df_clean.filter((col("Year") >= 2000) & (col("Year") <= 2010))

# keep only India
df_india = df_clean.filter(col("Country") == "India")

#write to destination bucket

(
    df_india
    .coalesce(1)
    .write
    .mode("overwrite")
    .option("header", "true")
    .csv(dest_path)
)

job.commit()
