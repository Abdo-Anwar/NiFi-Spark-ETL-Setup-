"""
spark-jobs/query.py
────────────────────────────────────────────────────────
Run the TPCH analytical query against the Star Schema Parquet files.

Usage (from inside spark-master container or spark-submit):
  spark-submit --master spark://spark-master:7077 /opt/spark-jobs/query.py

Parquet files are expected at /data/parquet/
  fact_lineitem.parquet
  dim_supplier.parquet
  dim_customer.parquet   (optional if denormalised into fact)
"""

import time
from pyspark.sql import SparkSession

PARQUET_BASE = "/data/parquet"

spark = (
    SparkSession.builder
    .appName("TPCH_StarSchema_Query")
    .getOrCreate()
)
spark.sparkContext.setLogLevel("WARN")

# ── Load tables ──────────────────────────────────────────────
fact   = spark.read.parquet(f"{PARQUET_BASE}/fact_lineitem.parquet")
# If you kept dim tables separate, load them too:
# dim_supplier = spark.read.parquet(f"{PARQUET_BASE}/dim_supplier.parquet")

fact.createOrReplaceTempView("fact_lineitem")

QUERY = """
SELECT
    n_name,
    s_name,
    SUM(l_quantity)                                      AS sum_qty,
    SUM(l_extendedprice)                                 AS sum_base_price,
    SUM(l_extendedprice * (1 - l_discount))              AS sum_disc_price,
    SUM(l_extendedprice * (1 - l_discount) * (1 + l_tax)) AS sum_charge,
    AVG(l_quantity)                                      AS avg_qty,
    AVG(l_extendedprice)                                 AS avg_price,
    AVG(l_discount)                                      AS avg_disc,
    COUNT(*)                                             AS count_order
FROM fact_lineitem
WHERE l_shipdate <= date '1998-09-02'
GROUP BY n_name, s_name
ORDER BY n_name, s_name
"""

times = []
for i in range(8):
    start = time.time()
    result = spark.sql(QUERY)
    result.count()          # force full execution
    elapsed = time.time() - start
    times.append(elapsed)
    print(f"Run {i+1}: {elapsed:.3f}s")

avg = sum(times) / len(times)
print(f"\n{'─'*40}")
print(f"All runs (s): {[round(t,3) for t in times]}")
print(f"Average     : {avg:.3f}s")
print(f"{'─'*40}")

spark.stop()
