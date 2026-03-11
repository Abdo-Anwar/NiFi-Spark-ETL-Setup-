# Data Engineering Sandbox 🛠️

A lightweight, fully containerized local data engineering environment. This repository provides a ready-to-use infrastructure stack to build, test, and benchmark ETL/ELT pipelines and OLAP workflows using MySQL, Apache NiFi, and Apache Spark.

**Note:** This repository provides the *infrastructure and tools* needed to build data pipelines, not the pipelines themselves. It is designed to be a clean slate for your data engineering experiments.

## 🏗️ Architecture & Stack

The environment spins up the following services via Docker Compose:

* **MySQL 8.0 (OLTP Source):** Acts as the relational database source for extracting raw transactional data.
* **Apache NiFi 2.0.0 (ETL Engine):** A powerful, scalable directed graph of data routing, transformation, and system mediation logic.
* **Apache Spark 3.5.6 (OLAP Engine):** A unified analytics engine for large-scale data processing, set up as a standalone cluster (1 Master, 1 Worker) with PySpark ready.

## ✨ Features (The "Under the Hood" Magic)

Setting up a distributed data stack locally often comes with dependency and permission headaches. This environment handles them automatically:

* **Zero-Config Parquet Support in NiFi 2.x:** Apache NiFi 2.x removed native Parquet processors to reduce build size. The setup script automatically injects the required `nifi-parquet-nar` and `hadoop-libraries` into the correct NiFi lib paths.
* **VS Code Dev-Container Ready:** The Spark cluster is pre-configured with the necessary rootless directory permissions (`/home/spark`), allowing seamless attachment of VS Code Dev Containers for interactive Jupyter Notebooks and PySpark development without `Permission Denied` errors.
* **Shared Volumes:** Seamless data sharing between NiFi (writers) and Spark (readers) through the `parquet-output` volume.

## 🚀 Quick Start

### Prerequisites
* [Docker](https://docs.docker.com/get-docker/) & Docker Compose installed
* Bash environment (Linux/macOS/WSL)

### Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/Abdo-Anwar/NiFi-Spark-ETL-Setup-.git
   cd NiFi-Spark-ETL-Setup-
   ```

2. Make the setup script executable and run it:
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

*The script will download the MySQL JDBC driver, inject NiFi Parquet dependencies, spin up the Docker containers, and fix VS Code attachment permissions.*

## 🌐 Accessing the Services

Once the setup script completes, the services will be available at:

| Service | Interface | URL | Credentials (User / Pass) |
|---------|-----------|-----|---------------------------|
| **MySQL** | TCP Port | `localhost:3306` | `root` / `root1234`<br>`tpch_user` / `tpch1234` |
| **Apache NiFi** | HTTPS Web UI | [https://localhost:8443/nifi](https://localhost:8443/nifi) | `admin` / `adminadminadmin` |
| **Spark Master** | Web UI | [http://localhost:8080](http://localhost:8080) | - |
| **Spark Worker** | Web UI | [http://localhost:8081](http://localhost:8081) | - |

*(Note: NiFi uses a self-signed certificate, so your browser will warn you. Proceed safely to the localhost.)*

## 📂 Project Structure & Volumes

The environment uses mounted volumes so you can easily drop files from your host machine into the containers:

| Host Directory | Container Mount Point | Purpose |
|----------------|----------------------|---------|
| `/init-scripts/` | `/docker-entrypoint-initdb.d/` (MySQL) | Drop SQL files here. MySQL automatically executes them on first boot (useful for DDLs) |
| `/nifi-drivers/` | `/opt/nifi/nifi-drivers/` (NiFi) | Where the MySQL JDBC driver (`.jar`) is stored for NiFi DBCPConnectionPools |
| `/parquet-output/` | `/opt/nifi/parquet-output/` (NiFi)<br>`/data/parquet/` (Spark) | The shared storage layer. NiFi writes `.parquet` files here, and Spark reads them from here |
| `/spark-jobs/` | `/opt/spark-jobs/` (Spark) | Drop your PySpark scripts (`.py`) or Jupyter Notebooks (`.ipynb`) here to execute them inside the Spark container |

## 👨‍💻 Workflow Example

1. **Populate MySQL** with your raw data using the init scripts.
2. **Build NiFi Pipeline:** Open NiFi UI, configure a `DBCPConnectionPool`, and build a flow to extract data from MySQL, transform it, and write it to the shared volume (`/opt/nifi/parquet-output/`) using `PutRecord` with a `ParquetRecordSetWriter`.
3. **Process with Spark:** Attach VS Code to the `spark-master` container, navigate to `/opt/spark-jobs/`, and run your PySpark benchmarks against the Parquet files located in `/data/parquet/`.

---

## 🔧 Troubleshooting

### Common Issues

**Issue: NiFi processors for Parquet not available**
- **Solution:** Run `./setup.sh` again. The script will re-inject the Parquet NAR files if missing.

**Issue: Permission denied when writing to Spark directories**
- **Solution:** The setup script automatically fixes permissions, but if issues persist, restart the containers:
  ```bash
  docker-compose down
  docker-compose up -d
  ```

**Issue: MySQL connection refused from NiFi**
- **Solution:** Ensure MySQL is fully initialized (especially if using init scripts). Check container logs:
  ```bash
  docker-compose logs mysql
  ```

---

*Built with simplicity and reusability in mind.*

---
