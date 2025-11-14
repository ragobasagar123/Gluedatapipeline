# Assignment : Terraform + Glue + S3

This assignment implements a simple ETL data pipeline on AWS using Terraform and AWS Glue

**1) Flow of operations:**

1. A public dataset "GlobalLandTemperaturesByCity.csv" is uploaded to an S3 source bucket
2. An AWS Glue job reads the CSV file from the source bucket.
3. The Glue script:
   - drops rows with null temperature  
   - filters data for the period of 2000–2010  
   - keeps only rows where Country = "India"
4. The transformed data is written as a CSV file into a destination S3 bucket under the folder output/india_temperatures/
All infrastructure (S3 buckets, IAM role, Glue job) is provisioned with Terraform.



**2) Dataset:**
I used the Climate Change Earth Surface Temperature Data from Kaggle:

Link for the Dataset: https://www.kaggle.com/datasets/berkeleyearth/climate-change-earth-surface-temperature-data?select=GlobalLandTemperaturesByMajorCity.csv



**3) Configurations:**
  
**3.1) Bucket creation:**
In both main.tf and transform.py, the following bucket names are used:

SOURCE_BUCKET = "etl-source-bucket-sagarr"

DEST_BUCKET   = "etl-destination-bucket-sagarr"

In main.tf, S3 buckets creation:

Input Bucket:
resource "aws_s3_bucket" "source_bucket" {
  bucket        = "etl-source-bucket-sagarr"
}

Output Bucket:
resource "aws_s3_bucket" "destination_bucket" {
  bucket        = "etl-destination-bucket-sagarr"
}

If you change the bucket names in main.tf, you must update them in transform.py as well.




**3.2) Glue job Script:**
In main.tf, the Glue job references the ETL script stored in the source bucket:

script_location = "s3://${aws_s3_bucket.source_bucket.bucket}/scripts/transform.py"

This means the script must be uploaded to:

s3://etl-source-bucket-sagarr/scripts/transform.py




***3.3) Terraform Deployment Steps**
From Terraform project folder: C:\Users\ragoba\Terraform\etl_project

Run the following commands:
Initialize Terraform: ..\terraform.exe init

To review the plan: ..\terraform.exe plan

To apply the configuration: ..\terraform.exe apply

Terraform will create:

Source bucket: etl-source-bucket-sagarr

Destination bucket: etl-destination-bucket-sagarr

IAM role and policy for Glue

Glue job: etl_transform_job

Once the required infrastructure is provisioned, upload the Script and Dataset



**3.4) Upload transform.py script to source S3 bucket**
The Glue job runs the ETL script from S3

Upload the script to the scripts folder of the source bucket:

aws s3 cp transform.py s3://etl-source-bucket-sagarr/scripts/transform.py



**3.5) Upload dataset to source S3 bucket**
Upload the Kaggle CSV dataset GlobalLandTemperaturesByCity.csv 

Upload to the input folder of the source bucket: s3://etl-source-bucket-sagarr/input/GlobalLandTemperaturesByCity.csv




**3.6) Glue ETL Script Logic:**
The ETL logic in transform.py:

SOURCE_BUCKET = "etl-source-bucket-sagarr"

DEST_BUCKET   = "etl-destination-bucket-sagarr"

source_path = f"s3://{SOURCE_BUCKET}/input/GlobalLandTemperaturesByCity.csv"

dest_path   = f"s3://{DEST_BUCKET}/output/india_temperatures/"

#Read input CSV from the source bucket:

df = (
    spark.read
    .option("header", "true")
    .option("inferSchema", "true")
    .csv(source_path)
)
Drop rows with null AverageTemperature: df_clean = df.filter(df["AverageTemperatue].isNotNull())

Filter for years 2000–2010: df_clean = df_clean.filter((col("Year") >= 2000) & (col("Year") <= 2010))

Keep only rows where Country == "India": df_india = df_clean.filter(col("Country") == "India")

Write result as CSV to the destination bucket:

    df_india
    .coalesce(1)
    .write
    .mode("overwrite")
    .option("header", "true")
    .csv(dest_path)
job.commit()



**4) Result**: 
The pipeline produces India-specific temperature records between 2000 and 2010 and saves them under: s3://etl-destination-bucket-sagarr/output/india_temperatures/



**5) Running and Testing the Data Pipeline:**

Run the Glue Job from the console and wait until the job status becomes Succeeded.

If the job fails, check the CloudWatch Logs for details and troubleshoot.

If the job is successful, check the S3 Destination bucket: etl-destination-bucket-sagarr

Navigate to the folder output/india_temperatures/: You should see a part .csv file

Download that CSV file and verify: All rows have Country = "India" and "Year" is between 2000 and 2010, and "AverageTemperature" is not null.

This confirms that the created pipeline is working as expected.



**6) Cleanup**
To remove all infrastructure created by Terraform:

From your project folder, run the following command:

..\terraform.exe destroy
