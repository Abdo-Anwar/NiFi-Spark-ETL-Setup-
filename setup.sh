#!/usr/bin/env bash
# ============================================================
#  OLAP Lab – Quick-start script
# ============================================================

set -e

echo "📁  Creating required local folders..."
mkdir -p init-scripts      # MySQL DDL / seed files go here
mkdir -p nifi-drivers      # MySQL JDBC jar goes here
mkdir -p parquet-output    # NiFi writes Parquet files here
mkdir -p spark-jobs        # PySpark query scripts go here
mkdir -p nifi-extensions   # NiFi NAR files go here

# ─────────────────────────────────────────────────────────────
# 1. Download MySQL JDBC driver
# ─────────────────────────────────────────────────────────────
JDBC_JAR="mysql-connector-j-8.0.33.jar"
JDBC_URL="https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/8.0.33/${JDBC_JAR}"

if [ ! -f "nifi-drivers/${JDBC_JAR}" ]; then
    echo "⬇️   Downloading MySQL JDBC driver..."
    curl -L "${JDBC_URL}" -o "nifi-drivers/${JDBC_JAR}"
else
    echo "✅  JDBC driver already present."
fi

# ─────────────────────────────────────────────────────────────
# 2. Download NiFi Parquet NARs
# ─────────────────────────────────────────────────────────────
if [ ! -f "nifi-extensions/nifi-parquet-nar-2.0.0.nar" ]; then
    echo "⬇️   Downloading NiFi Parquet NARs..."
    wget -q -P nifi-extensions https://repo1.maven.org/maven2/org/apache/nifi/nifi-parquet-nar/2.0.0/nifi-parquet-nar-2.0.0.nar
    wget -q -P nifi-extensions https://repo1.maven.org/maven2/org/apache/nifi/nifi-hadoop-libraries-nar/2.0.0/nifi-hadoop-libraries-nar-2.0.0.nar
else
    echo "✅  NiFi NARs already present."
fi

# ─────────────────────────────────────────────────────────────
# 3. Spin up the containers
# ─────────────────────────────────────────────────────────────
echo "🚀  Starting containers..."
docker compose up -d

echo "⏳  Waiting 15 seconds for containers to initialize before applying patches..."
sleep 15

# ─────────────────────────────────────────────────────────────
# 4. Apply Fixes (NiFi Parquet & Spark VS Code)
# ─────────────────────────────────────────────────────────────
echo "🔧  Applying NiFi Parquet patch..."
docker cp ./nifi-extensions/nifi-parquet-nar-2.0.0.nar tpch_nifi:/opt/nifi/nifi-current/lib/
docker cp ./nifi-extensions/nifi-hadoop-libraries-nar-2.0.0.nar tpch_nifi:/opt/nifi/nifi-current/lib/
docker exec -u 0 tpch_nifi chown nifi:nifi /opt/nifi/nifi-current/lib/nifi-parquet-nar-2.0.0.nar
docker exec -u 0 tpch_nifi chown nifi:nifi /opt/nifi/nifi-current/lib/nifi-hadoop-libraries-nar-2.0.0.nar
docker restart tpch_nifi

echo "🔧  Applying Spark VS Code Dev-Container patch..."
docker exec -u 0 tpch_spark_master mkdir -p /home/spark
docker exec -u 0 tpch_spark_master chown -R spark:spark /home/spark

echo ""
echo "🎉  All done! Environment is ready."
echo ""
echo "Services:"
echo "  MySQL      → localhost:3306  (user: tpch_user / tpch1234)"
echo "  NiFi UI    → https://localhost:8443/nifi  (admin / adminadminadmin)"
echo "  Spark UI   → http://localhost:8080"