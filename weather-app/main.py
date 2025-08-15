import os
import json
import logging
from flask import Flask, request
from google.cloud import bigquery, storage, error_reporting
from google.cloud.sql.connector import Connector, IPTypes
import sqlalchemy

# --- Logging Configuration ---
# Let's get this logging party started! ☕️
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Initialize clients
app = Flask(__name__)
logging.info(" brewing up the Flask app...")

# Initialize Google Cloud Error Reporting
try:
    error_client = error_reporting.Client()
    app.wsgi_app = error_reporting.WSGIApplication(app.wsgi_app, error_client)
    logging.info(" Error Reporting is ready to catch any spilled beans!")
except Exception as e:
    logging.error(f" Could not start the Error Reporting client. It's just a little steamed: {e}")

project_id = os.environ.get("PROJECT_ID")
if not project_id:
    logging.warning(" a decaf start: PROJECT_ID environment variable not set.")

logging.info(" grinding the beans for our Google Cloud clients...")
storage_client = storage.Client(project=project_id)
bigquery_client = bigquery.Client(project=project_id)
connector = Connector()
logging.info(" clients are ready to brew!")

# Database connection pool
db = None
db_initialized = False

def getconn():
    """Establishes a connection to the Cloud SQL database."""
    logging.info(" a fresh pot of database connection is being brewed...")
    try:
        conn = connector.connect(
            os.environ["INSTANCE_CONNECTION_NAME"],
            "pg8000",
            user=os.environ["DB_USER"],
            password=os.environ["DB_PASS"],
            db=os.environ["DB_NAME"],
            ip_type=IPTypes.PUBLIC,
        )
        logging.info(" a successful pour! Database connection is ready.")
        return conn
    except Exception as e:
        logging.error(f" bitter brew! Could not connect to the database: {e}")
        raise

def init_db():
    """Initializes the database connection and creates tables."""
    global db, db_initialized
    if db is None:
        logging.info(" creating the global database connection pool. It's like a coffee thermos, always ready!")
        db = sqlalchemy.create_engine("postgresql+pg8000://", creator=getconn)
    
    if not db_initialized:
        logging.info(" checking if the 'weather_results' table exists. Don't want to spill any data!")
        try:
            with db.connect() as conn:
                conn.execute(
                    sqlalchemy.text(
                        """
                        CREATE TABLE IF NOT EXISTS weather_results (
                            id SERIAL PRIMARY KEY,
                            year INT NOT NULL,
                            total_precipitation FLOAT NOT NULL,
                            recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
                        );
                        """
                    )
                )
                conn.commit()
            logging.info(" table is ready to be served!")
            db_initialized = True
        except Exception as e:
            logging.error(f" spilled the beans! Could not create the table: {e}")

@app.before_request
def log_request_info():
    """Logs information about the incoming request."""
    logging.info(f" a new customer has arrived! Request: {request.method} {request.path}")

@app.route("/", methods=["GET"])
def index():
    """A simple hello page to let you know the app is running."""
    logging.info(" someone's at the counter! Serving up a fresh 'Hello, Coffee!'")
    return "<h1>Hello, Coffee!</h1><p>Your weather app is brewing nicely.</p>", 200

@app.route("/past/<int:year>", methods=["GET"])
def process_weather_data(year):
    """Main endpoint to fetch, store, and upload weather data."""
    logging.info(f" a new order is in! Processing weather data for the year {year}.")
    
    init_db()

    # 1. Query BigQuery
    logging.info(f" sending our order to BigQuery. One query, extra foamy, for the year {year}!")
    query = """
        SELECT SUM(prcp) as total_precipitation
        FROM `bigquery-public-data.samples.gsod`
        WHERE year = @year AND prcp < 99.99
    """
    job_config = bigquery.QueryJobConfig(
        query_parameters=[bigquery.ScalarQueryParameter("year", "INT64", year)]
    )
    try:
        query_job = bigquery_client.query(query, job_config=job_config)
        results = query_job.result()
        logging.info(" BigQuery has served our results. They're hot and fresh!")
    except Exception as e:
        logging.error(f" our BigQuery order got lost! {e}")
        return "Error querying BigQuery", 500

    total_precipitation = 0
    for row in results:
        total_precipitation = row.total_precipitation

    if total_precipitation is None:
        logging.warning(f" empty cup! No precipitation data found for {year}.")
        return f"No precipitation data found for the year {year}.", 404

    result_data = {
        "year": year,
        "total_precipitation_inches": round(total_precipitation, 2)
    }
    logging.info(f" data processed: {result_data}")

    # 2. Save to Cloud SQL
    logging.info(" pouring the results into our Cloud SQL database...")
    try:
        stmt = sqlalchemy.text(
            "INSERT INTO weather_results (year, total_precipitation) VALUES (:year, :total_precipitation)"
        )
        with db.connect() as conn:
            conn.execute(stmt, parameters={"year": year, "total_precipitation": result_data["total_precipitation_inches"]})
            conn.commit()
        logging.info(" successfully saved to Cloud SQL. That's a good brew!")
    except Exception as e:
        logging.error(f" oops, we spilled the data on the way to the database! {e}")
        return f"Error connecting or inserting into database: {e}", 500

    # 3. Save to Cloud Storage
    logging.info(" time to store a backup in Cloud Storage. It's like getting a coffee to go!")
    try:
        bucket_name = os.environ["BUCKET_NAME"]
        bucket = storage_client.bucket(bucket_name)
        blob = bucket.blob(f"results/{year}-precipitation.json")
        blob.upload_from_string(
            json.dumps(result_data, indent=2),
            content_type="application/json",
        )
        logging.info(f" successfully uploaded to Cloud Storage. Another satisfied customer!")
    except Exception as e:
        logging.error(f" dropped our to-go order! Could not upload to Cloud Storage: {e}")
        return f"Error uploading to Cloud Storage: {e}", 500

    return f"Successfully processed and stored data for year {year}. Precipitation: {result_data['total_precipitation_inches']} inches.", 200

if __name__ == "__main__":
    logging.info(" the coffee shop is open for business!")
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))