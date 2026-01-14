# Docker-Images (Yolks) for Pelican Gamepanel and Pterodactyl

Docker Images for the Hosting Panel Pelican, Jexactyl & Pterodactyl created by gOOvER

A curated collection of core images that can be used with Pterodactyl's Egg system. Each image is rebuilt
periodically to ensure dependencies are always up-to-date.

[![Discord](https://img.shields.io/discord/1158000498952126464?label=Discord&logo=discord&logoColor=white)](https://discord.com/invite/RmqSeYBQ4y)
[![License](https://img.shields.io/github/license/gOOvER/pelican-ptero-images)](LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/gOOvER/pelican-ptero-images?style=flat&logo=github)](https://github.com/gOOvER/pelican-ptero-images/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/gOOvER/pelican-ptero-images?style=flat&logo=github)](https://github.com/gOOvER/pelican-ptero-images/network/members)
[![GitHub Issues](https://img.shields.io/github/issues/gOOvER/pelican-ptero-images)](https://github.com/gOOvER/pelican-ptero-images/issues)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/gOOvER/pelican-ptero-images)](https://github.com/gOOvER/pelican-ptero-images/commits)
[![Maintenance](https://img.shields.io/maintenance/yes/2025)](https://github.com/gOOvER/pelican-ptero-images)

---

## 📋 Table of Contents

- [Development Images](#development-images)
  - [NodeJS](#nodejs)
  - [Python](#python)
  - [Go](#go)
  - [Rust](#rust)
  - [DotNet](#dotnet)
  - [Bun](#bun)
  - [Dart](#dart)
  - [Elixir](#elixir)
- [Java Images](#java-images)
  - [Java Base (Temurin)](#java-base-temurin)
  - [Java GraalVM](#java-graalvm)
  - [Java Corretto](#java-corretto)
  - [Java Zulu](#java-zulu)
  - [Java Dragonwell](#java-dragonwell)
  - [Java Liberica](#java-liberica)
  - [Java Shenandoah](#java-shenandoah)
- [Database Images](#database-images)
  - [MariaDB](#mariadb)
  - [PostgreSQL](#postgresql)
  - [MongoDB](#mongodb)
  - [Redis](#redis)
  - [KeyDB](#keydb)
  - [Cassandra](#cassandra)
- [Game Server Images](#game-server-images)
  - [Steam](#steam)
  - [SteamCMD](#steamcmd)
  - [Wine](#wine)
  - [Game Specific](#game-specific)
- [Bot Images](#bot-images)
- [Application Images](#application-images)
- [Distribution Images](#distribution-images)
- [Installer Images](#installer-images)
- [Alpine Images](#alpine-images)
- [Voice Images](#voice-images)
- [Custom Images](#custom-images)

---

# <a name="development-images"></a>🛠️ Development Images

## <a name="nodejs"></a>➡️ NodeJS

| Image | Status | Description |
|-------|--------|-------------|
| `goover/nodejs` | [![build nodejs](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/dev-nodejs.yml/badge.svg)](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/dev-nodejs.yml) | NodeJS versions from `12` to `23` |

| Image | URI | AMD64 | ARM64 |
|-------|:---:|:-----:|:-----:|
| nodejs:12 | `ghcr.io/goover/nodejs:12` | ✅ | ✅ |
| nodejs:14 | `ghcr.io/goover/nodejs:14` | ✅ | ✅ |
| nodejs:16 | `ghcr.io/goover/nodejs:16` | ✅ | ✅ |
| nodejs:18 | `ghcr.io/goover/nodejs:18` | ✅ | ✅ |
| nodejs:20 | `ghcr.io/goover/nodejs:20` | ✅ | ✅ |
| nodejs:22 | `ghcr.io/goover/nodejs:22` | ✅ | ✅ |
| nodejs:24 | `ghcr.io/goover/nodejs:24` | ✅ | ✅ |

---

## <a name="python"></a>➡️ Python

| Image | Status | Description |
|-------|--------|-------------|
| `goover/python` | [![build python](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/dev-python.yml/badge.svg)](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/dev-python.yml) | Python versions from `3.7` to `3.13` |

| Image | URI | AMD64 | ARM64 |
|-------|:---:|:-----:|:-----:|
| python:3.7 | `ghcr.io/goover/python:3.7` | ✅ | ✅ |
| python:3.8 | `ghcr.io/goover/python:3.8` | ✅ | ✅ |
| python:3.9 | `ghcr.io/goover/python:3.9` | ✅ | ✅ |
| python:3.10 | `ghcr.io/goover/python:3.10` | ✅ | ✅ |
| python:3.11 | `ghcr.io/goover/python:3.11` | ✅ | ✅ |
| python:3.12 | `ghcr.io/goover/python:3.12` | ✅ | ✅ |
| python:3.13 | `ghcr.io/goover/python:3.13` | ✅ | ✅ |

---

## <a name="go"></a>➡️ GO

| Image | Status | Description |
|-------|--------|-------------|
| `goover/go` | [![build go](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/dev-go.yml/badge.svg)](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/dev-go.yml) | GO versions from `1.14` to `1.22` |

| Image | URI | AMD64 | ARM64 |
|-------|:---:|:-----:|:-----:|
| go:1.14 | `ghcr.io/goover/go:1.14` | ✅ | ✅ |
| go:1.15 | `ghcr.io/goover/go:1.15` | ✅ | ✅ |
| go:1.16 | `ghcr.io/goover/go:1.16` | ✅ | ✅ |
| go:1.17 | `ghcr.io/goover/go:1.17` | ✅ | ✅ |
| go:1.18 | `ghcr.io/goover/go:1.18` | ✅ | ✅ |
| go:1.19 | `ghcr.io/goover/go:1.19` | ✅ | ✅ |
| go:1.20 | `ghcr.io/goover/go:1.20` | ✅ | ✅ |
| go:1.21 | `ghcr.io/goover/go:1.21` | ✅ | ✅ |
| go:1.22 | `ghcr.io/goover/go:1.22` | ✅ | ✅ |
| go:1.23 | `ghcr.io/goover/go:1.23` | ✅ | ✅ |
| go:1.24 | `ghcr.io/goover/go:1.24` | ✅ | ✅ |
| go:1.25 | `ghcr.io/goover/go:1.25` | ✅ | ✅ |

---

## <a name="rust"></a>➡️ Rust

| Image | Status | Description |
|-------|--------|-------------|
| `goover/rust` | [![build rust](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/dev-rust.yml/badge.svg)](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/dev-rust.yml) | Rust latest |

| Image | URI | AMD64 | ARM64 |
|-------|:---:|:-----:|:-----:|
| rust:latest | `ghcr.io/goover/rust:latest` | ✅ | ✅ |

---

## <a name="dotnet"></a>➡️ DotNet

| Image | Status | Description |
|-------|--------|-------------|
| `goover/dotnet` | [![build dotnet](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/dev-dotnet.yml/badge.svg)](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/dev-dotnet.yml) | DotNet versions from `6` to `10` |

| Image | URI | AMD64 | ARM64 |
|-------|:---:|:-----:|:-----:|
| dotnet:3.1 | `ghcr.io/goover/dotnet:3.1` | ✅ | ❌ |
| dotnet:5 | `ghcr.io/goover/dotnet:5` | ✅ | ❌ |
| dotnet:6 | `ghcr.io/goover/dotnet:6` | ✅ | ❌ |
| dotnet:6-sdk | `ghcr.io/goover/dotnet:6-sdk` | ✅ | ❌ |
| dotnet:7 | `ghcr.io/goover/dotnet:7` | ✅ | ❌ |
| dotnet:7-sdk | `ghcr.io/goover/dotnet:7-sdk` | ✅ | ❌ |
| dotnet:8 | `ghcr.io/goover/dotnet:8` | ✅ | ❌ |
| dotnet:8-sdk | `ghcr.io/goover/dotnet:8-sdk` | ✅ | ❌ |
| dotnet:9 | `ghcr.io/goover/dotnet:9` | ✅ | ❌ |
| dotnet:9-sdk | `ghcr.io/goover/dotnet:9-sdk` | ✅ | ❌ |
| dotnet:10 | `ghcr.io/goover/dotnet:10` | ✅ | ❌ |

---

## <a name="bun"></a>➡️ Bun

| Image | Status | Description |
|-------|--------|-------------|
| `goover/bun` | [![build bun](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/dev-bun.yml/badge.svg)](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/dev-bun.yml) | Bun JavaScript runtime |

| Image | URI | AMD64 | ARM64 |
|-------|:---:|:-----:|:-----:|
| bun:latest | `ghcr.io/goover/bun:latest` | ✅ | ✅ |
| bun:canary | `ghcr.io/goover/bun:canary` | ✅ | ✅ |

---

## <a name="dart"></a>➡️ Dart

| Image | Status | Description |
|-------|--------|-------------|
| `goover/dart` | [![build dart](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/dev-dart.yml/badge.svg)](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/dev-dart.yml) | Dart SDK |

| Image | URI | AMD64 | ARM64 |
|-------|:---:|:-----:|:-----:|
| dart:stable | `ghcr.io/goover/dart:stable` | ✅ | ✅ |
| dart:stable-sdk | `ghcr.io/goover/dart:stable-sdk` | ✅ | ✅ |

---

## <a name="elixir"></a>➡️ Elixir

| Image | Status | Description |
|-------|--------|-------------|
| `goover/elixir` | [![build elixir](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/dev-elixir.yml/badge.svg)](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/dev-elixir.yml) | Elixir versions from `1.12` to `1.16` |

| Image | URI | AMD64 | ARM64 |
|-------|:---:|:-----:|:-----:|
| elixir:latest | `ghcr.io/goover/elixir:latest` | ✅ | ✅ |
| elixir:1.12 | `ghcr.io/goover/elixir:1.12` | ✅ | ✅ |
| elixir:1.13 | `ghcr.io/goover/elixir:1.13` | ✅ | ✅ |
| elixir:1.14 | `ghcr.io/goover/elixir:1.14` | ✅ | ✅ |
| elixir:1.15 | `ghcr.io/goover/elixir:1.15` | ✅ | ✅ |
| elixir:1.16 | `ghcr.io/goover/elixir:1.16` | ✅ | ✅ |

---

# <a name="java-images"></a>☕ Java Images

## <a name="java-base-temurin"></a>➡️ Java Base (Temurin)

| Image | Status | Description |
|-------|--------|-------------|
| `goover/java` | [![build java](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/java-base.yml/badge.svg)](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/java-base.yml) | Eclipse Temurin JDK |

| Image | URI | AMD64 | ARM64 |
|-------|:---:|:-----:|:-----:|
| java:8 | `ghcr.io/goover/java:8` | ✅ | ✅ |
| java:11 | `ghcr.io/goover/java:11` | ✅ | ✅ |
| java:16 | `ghcr.io/goover/java:16` | ✅ | ✅ |
| java:17 | `ghcr.io/goover/java:17` | ✅ | ✅ |
| java:18 | `ghcr.io/goover/java:18` | ✅ | ✅ |
| java:19 | `ghcr.io/goover/java:19` | ✅ | ✅ |
| java:20 | `ghcr.io/goover/java:20` | ✅ | ✅ |
| java:21 | `ghcr.io/goover/java:21` | ✅ | ✅ |
| java:22 | `ghcr.io/goover/java:22` | ✅ | ✅ |
| java:23 | `ghcr.io/goover/java:23` | ✅ | ✅ |
| java:24 | `ghcr.io/goover/java:24` | ✅ | ✅ |
| java:25 | `ghcr.io/goover/java:25` | ✅ | ✅ |

---

## <a name="java-graalvm"></a>➡️ Java GraalVM

| Image | Status | Description |
|-------|--------|-------------|
| `goover/java` | [![build java-graalvm](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/java-graalvm.yml/badge.svg)](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/java-graalvm.yml) | GraalVM Community Edition |

| Image | URI | AMD64 | ARM64 |
|-------|:---:|:-----:|:-----:|
| java:graalvm_17 | `ghcr.io/goover/java:graalvm_17` | ✅ | ✅ |
| java:graalvm_20 | `ghcr.io/goover/java:graalvm_20` | ✅ | ✅ |
| java:graalvm_21 | `ghcr.io/goover/java:graalvm_21` | ✅ | ✅ |
| java:graalvm_22 | `ghcr.io/goover/java:graalvm_22` | ✅ | ✅ |
| java:graalvm_23 | `ghcr.io/goover/java:graalvm_23` | ✅ | ✅ |
| java:graalvm_25 | `ghcr.io/goover/java:graalvm_25` | ✅ | ✅ |

---

## <a name="java-corretto"></a>➡️ Java Corretto

| Image | Status | Description |
|-------|--------|-------------|
| `goover/java` | [![build java-corretto](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/java-corretto.yml/badge.svg)](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/java-corretto.yml) | Amazon Corretto JDK |

| Image | URI | AMD64 | ARM64 |
|-------|:---:|:-----:|:-----:|
| java:corretto_8 | `ghcr.io/goover/java:corretto_8` | ✅ | ✅ |
| java:corretto_11 | `ghcr.io/goover/java:corretto_11` | ✅ | ✅ |
| java:corretto_17 | `ghcr.io/goover/java:corretto_17` | ✅ | ✅ |
| java:corretto_21 | `ghcr.io/goover/java:corretto_21` | ✅ | ✅ |
| java:corretto_23 | `ghcr.io/goover/java:corretto_23` | ✅ | ✅ |
| java:corretto_24 | `ghcr.io/goover/java:corretto_24` | ✅ | ✅ |
| java:corretto_25 | `ghcr.io/goover/java:corretto_25` | ✅ | ✅ |

---

## <a name="java-zulu"></a>➡️ Java Zulu

| Image | Status | Description |
|-------|--------|-------------|
| `goover/java` | [![build java-zulu](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/java-zulu.yml/badge.svg)](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/java-zulu.yml) | Azul Zulu JDK |

| Image | URI | AMD64 | ARM64 |
|-------|:---:|:-----:|:-----:|
| java:zulu_8 | `ghcr.io/goover/java:zulu_8` | ✅ | ✅ |
| java:zulu_11 | `ghcr.io/goover/java:zulu_11` | ✅ | ✅ |
| java:zulu_13 | `ghcr.io/goover/java:zulu_13` | ✅ | ✅ |
| java:zulu_15 | `ghcr.io/goover/java:zulu_15` | ✅ | ✅ |
| java:zulu_17 | `ghcr.io/goover/java:zulu_17` | ✅ | ✅ |
| java:zulu_18 | `ghcr.io/goover/java:zulu_18` | ✅ | ✅ |
| java:zulu_19 | `ghcr.io/goover/java:zulu_19` | ✅ | ✅ |
| java:zulu_20 | `ghcr.io/goover/java:zulu_20` | ✅ | ✅ |
| java:zulu_21 | `ghcr.io/goover/java:zulu_21` | ✅ | ✅ |
| java:zulu_22 | `ghcr.io/goover/java:zulu_22` | ✅ | ✅ |
| java:zulu_23 | `ghcr.io/goover/java:zulu_23` | ✅ | ✅ |
| java:zulu_24 | `ghcr.io/goover/java:zulu_24` | ✅ | ✅ |
| java:zulu_25 | `ghcr.io/goover/java:zulu_25` | ✅ | ✅ |

---

## <a name="java-dragonwell"></a>➡️ Java Dragonwell

| Image | Status | Description |
|-------|--------|-------------|
| `goover/java` | [![build java-dragonwell](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/java-dragonwell.yml/badge.svg)](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/java-dragonwell.yml) | Alibaba Dragonwell JDK |

| Image | URI | AMD64 | ARM64 |
|-------|:---:|:-----:|:-----:|
| java:dragonwell_8 | `ghcr.io/goover/java:dragonwell_8` | ✅ | ✅ |
| java:dragonwell_11 | `ghcr.io/goover/java:dragonwell_11` | ✅ | ✅ |
| java:dragonwell_17 | `ghcr.io/goover/java:dragonwell_17` | ✅ | ✅ |
| java:dragonwell_21 | `ghcr.io/goover/java:dragonwell_21` | ✅ | ✅ |

---

## <a name="java-liberica"></a>➡️ Java Liberica

| Image | Status | Description |
|-------|--------|-------------|
| `goover/java` | [![build java-liberica](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/java-liberica.yml/badge.svg)](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/java-liberica.yml) | BellSoft Liberica JDK |

| Image | URI | AMD64 | ARM64 |
|-------|:---:|:-----:|:-----:|
| java:liberica_8 | `ghcr.io/goover/java:liberica_8` | ✅ | ✅ |
| java:liberica_11 | `ghcr.io/goover/java:liberica_11` | ✅ | ✅ |
| java:liberica_17 | `ghcr.io/goover/java:liberica_17` | ✅ | ✅ |
| java:liberica_21 | `ghcr.io/goover/java:liberica_21` | ✅ | ✅ |
| java:liberica_23 | `ghcr.io/goover/java:liberica_23` | ✅ | ✅ |
| java:liberica_24 | `ghcr.io/goover/java:liberica_24` | ✅ | ✅ |
| java:liberica_25 | `ghcr.io/goover/java:liberica_25` | ✅ | ✅ |

---

## <a name="java-shenandoah"></a>➡️ Java Shenandoah

| Image | Status | Description |
|-------|--------|-------------|
| `goover/java` | [![build java-shenandoah](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/java-shenandoah.yml/badge.svg)](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/java-shenandoah.yml) | Shenandoah GC JDK |

| Image | URI | AMD64 | ARM64 |
|-------|:---:|:-----:|:-----:|
| java:shenandoah_8 | `ghcr.io/goover/java:shenandoah_8` | ✅ | ✅ |
| java:shenandoah_11 | `ghcr.io/goover/java:shenandoah_11` | ✅ | ✅ |
| java:shenandoah_17 | `ghcr.io/goover/java:shenandoah_17` | ✅ | ✅ |
| java:shenandoah_21 | `ghcr.io/goover/java:shenandoah_21` | ✅ | ✅ |
| java:shenandoah_25 | `ghcr.io/goover/java:shenandoah_25` | ✅ | ✅ |

---

# <a name="database-images"></a>🗄️ Database Images

## <a name="mariadb"></a>➡️ MariaDB

| Image | Status | Description |
|-------|--------|-------------|
| `goover/mariadb` | [![build mariadb](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/db-mariadb.yml/badge.svg)](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/db-mariadb.yml) | MariaDB Database Server |

| Image | URI | AMD64 | ARM64 |
|-------|:---:|:-----:|:-----:|
| mariadb:10.4 | `ghcr.io/goover/mariadb:10.4` | ✅ | ✅ |
| mariadb:10.5 | `ghcr.io/goover/mariadb:10.5` | ✅ | ✅ |
| mariadb:10.6 | `ghcr.io/goover/mariadb:10.6` | ✅ | ✅ |
| mariadb:10.10 | `ghcr.io/goover/mariadb:10.10` | ✅ | ✅ |
| mariadb:10.11 | `ghcr.io/goover/mariadb:10.11` | ✅ | ✅ |
| mariadb:11.0 | `ghcr.io/goover/mariadb:11.0` | ✅ | ✅ |
| mariadb:11.1 | `ghcr.io/goover/mariadb:11.1` | ✅ | ✅ |

---

## <a name="postgresql"></a>➡️ PostgreSQL

| Image | Status | Description |
|-------|--------|-------------|
| `goover/postgres` | [![build postgres](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/db-postgres.yml/badge.svg)](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/db-postgres.yml) | PostgreSQL Database Server |

| Image | URI | AMD64 | ARM64 |
|-------|:---:|:-----:|:-----:|
| postgres:11 | `ghcr.io/goover/postgres:11` | ✅ | ✅ |
| postgres:12 | `ghcr.io/goover/postgres:12` | ✅ | ✅ |
| postgres:13 | `ghcr.io/goover/postgres:13` | ✅ | ✅ |
| postgres:14 | `ghcr.io/goover/postgres:14` | ✅ | ✅ |
| postgres:15 | `ghcr.io/goover/postgres:15` | ✅ | ✅ |
| postgres:16 | `ghcr.io/goover/postgres:16` | ✅ | ✅ |
| postgres:17 | `ghcr.io/goover/postgres:17` | ✅ | ✅ |
| postgres:18 | `ghcr.io/goover/postgres:18` | ✅ | ✅ |

---

## <a name="mongodb"></a>➡️ MongoDB

| Image | Status | Description |
|-------|--------|-------------|
| `goover/mongodb` | [![build mongodb](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/db-mongodb.yml/badge.svg)](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/db-mongodb.yml) | MongoDB Database Server |

| Image | URI | AMD64 | ARM64 |
|-------|:---:|:-----:|:-----:|
| mongodb:5 | `ghcr.io/goover/mongodb:5` | ✅ | ✅ |
| mongodb:6 | `ghcr.io/goover/mongodb:6` | ✅ | ✅ |
| mongodb:7 | `ghcr.io/goover/mongodb:7` | ✅ | ✅ |

---

## <a name="redis"></a>➡️ Redis

| Image | Status | Description |
|-------|--------|-------------|
| `goover/redis` | [![build redis](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/db-redis.yml/badge.svg)](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/db-redis.yml) | Redis In-Memory Database |

| Image | URI | AMD64 | ARM64 |
|-------|:---:|:-----:|:-----:|
| redis:6 | `ghcr.io/goover/redis:6` | ✅ | ✅ |
| redis:7 | `ghcr.io/goover/redis:7` | ✅ | ✅ |
| redis:8 | `ghcr.io/goover/redis:8` | ✅ | ✅ |

---

## <a name="keydb"></a>➡️ KeyDB

| Image | Status | Description |
|-------|--------|-------------|
| `goover/keydb` | [![build keydb](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/db-keydb.yml/badge.svg)](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/db-keydb.yml) | KeyDB (Redis Fork) |

| Image | URI | AMD64 | ARM64 |
|-------|:---:|:-----:|:-----:|
| keydb:latest | `ghcr.io/goover/keydb:latest` | ✅ | ✅ |

---

## <a name="cassandra"></a>➡️ Cassandra

| Image | Status | Description |
|-------|--------|-------------|
| `goover/cassandra` | [![build cassandra](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/db-cassandra.yml/badge.svg)](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/db-cassandra.yml) | Apache Cassandra Database |

| Image | URI | AMD64 | ARM64 |
|-------|:---:|:-----:|:-----:|
| cassandra:java8_python2 | `ghcr.io/goover/cassandra:java8_python2` | ✅ | ✅ |
| cassandra:java11_python3 | `ghcr.io/goover/cassandra:java11_python3` | ✅ | ✅ |

---

# <a name="game-server-images"></a>🎮 Game Server Images

## <a name="steam"></a>➡️ Steam

| Image | Status | Description |
|-------|--------|-------------|
| `goover/steam` | [![build steam](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/steam.yml/badge.svg)](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/steam.yml) | Steam with Proton support |

| Image | URI | AMD64 | ARM64 |
|-------|:---:|:-----:|:-----:|
| steam:proton | `ghcr.io/goover/steam:proton` | ✅ | ❌ |
| steam:proton-ubuntu | `ghcr.io/goover/steam:proton-ubuntu` | ✅ | ❌ |

---

## <a name="steamcmd"></a>➡️ SteamCMD

| Image | Status | Description |
|-------|--------|-------------|
| `goover/steamcmd` | [![build steamcmd](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/steamcmd.yml/badge.svg)](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/steamcmd.yml) | SteamCMD for game servers |

| Image | URI | AMD64 | ARM64 |
|-------|:---:|:-----:|:-----:|
| steamcmd:debian | `ghcr.io/goover/steamcmd:debian` | ✅ | ❌ |
| steamcmd:ubuntu | `ghcr.io/goover/steamcmd:ubuntu` | ✅ | ❌ |
| steamcmd:mono | `ghcr.io/goover/steamcmd:mono` | ✅ | ❌ |

---

## <a name="wine"></a>➡️ Wine

| Image | Status | Description |
|-------|--------|-------------|
| `goover/wine` | [![build wine](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/emu-wine.yml/badge.svg)](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/emu-wine.yml) | Wine for Windows applications |

| Image | URI | AMD64 | ARM64 |
|-------|:---:|:-----:|:-----:|
| wine:stable | `ghcr.io/goover/wine:stable` | ✅ | ❌ |
| wine:staging | `ghcr.io/goover/wine:staging` | ✅ | ❌ |
| wine:devel | `ghcr.io/goover/wine:devel` | ✅ | ❌ |

---

## <a name="game-specific"></a>➡️ Game Specific

| Image | Status | Description |
|-------|--------|-------------|
| `goover/games` | [![build games](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/games.yml/badge.svg)](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/games.yml) | Game Server Images |

| Image | URI | AMD64 | ARM64 | Description |
|-------|:---:|:-----:|:-----:|-------------|
| games:aloft | `ghcr.io/goover/games:aloft` | ✅ | ❌ | Aloft Game Server |
| games:aloft-proton | `ghcr.io/goover/games:aloft-proton` | ✅ | ❌ | Aloft with Proton |
| games:arma3 | `ghcr.io/goover/games:arma3` | ✅ | ❌ | Arma 3 Server |
| games:interstellarrift | `ghcr.io/goover/games:interstellarrift` | ✅ | ❌ | Interstellar Rift |
| games:mtsa | `ghcr.io/goover/games:mtsa` | ✅ | ❌ | MTA:SA Server |
| games:pathoftitans | `ghcr.io/goover/games:pathoftitans` | ✅ | ❌ | Path of Titans |
| games:quakeliveqlx | `ghcr.io/goover/games:quakeliveqlx` | ✅ | ❌ | Quake Live QLX |
| games:screeps | `ghcr.io/goover/games:screeps` | ✅ | ✅ | Screeps Server |
| games:staxel | `ghcr.io/goover/games:staxel` | ✅ | ❌ | Staxel Server |
| games:thefront | `ghcr.io/goover/games:thefront` | ✅ | ❌ | The Front Server |
| games:wurm | `ghcr.io/goover/games:wurm` | ✅ | ❌ | Wurm Unlimited |
| games:hytale | `ghcr.io/goover/games:hytale` | ✅ | ❌ | Hytale Server |

---

# <a name="bot-images"></a>🤖 Bot Images

| Image | Status | Description |
|-------|--------|-------------|
| `goover/bots` | [![build bots](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/bots.yml/badge.svg)](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/bots.yml) | Discord/Twitch Bot Images |

| Image | URI | AMD64 | ARM64 | Description |
|-------|:---:|:-----:|:-----:|-------------|
| bots:nodemongo | `ghcr.io/goover/bots:nodemongo` | ✅ | ✅ | Node.js + MongoDB 8 |
| bots:nodemongo7 | `ghcr.io/goover/bots:nodemongo7` | ✅ | ✅ | Node.js + MongoDB 7 |
| bots:parkertron | `ghcr.io/goover/bots:parkertron` | ✅ | ✅ | Parkertron Bot |
| bots:sogebot | `ghcr.io/goover/bots:sogebot` | ✅ | ✅ | SogeBot |
| bots:nodemongo8 | `ghcr.io/goover/bots:nodemongo8` | ✅ | ❌ |

---

# <a name="application-images"></a>📱 Application Images

| Image | Status | Description |
|-------|--------|-------------|
| `goover/apps` | [![build apps](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/apps.yml/badge.svg)](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/apps.yml) | Application Images |

| Image | URI | AMD64 | ARM64 | Description |
|-------|:---:|:-----:|:-----:|-------------|
| apps:discordpush | `ghcr.io/goover/apps:discordpush` | ✅ | ✅ | Discord Push Notifications |
| apps:uptimekuma | `ghcr.io/goover/apps:uptimekuma` | ✅ | ✅ | Uptime Kuma Monitoring |

---

# <a name="distribution-images"></a>🐧 Distribution Images

## <a name="alpine-distro"></a>➡️ Alpine

| Image | Status | Description |
|-------|--------|-------------|
| `goover/distros` | [![build alpine](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/distros-alpine.yml/badge.svg)](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/distros-alpine.yml) | Alpine Linux Base Images |

| Image | URI | AMD64 | ARM64 |
|-------|:---:|:-----:|:-----:|
| distros:alpine_latest | `ghcr.io/goover/distros:alpine_latest` | ✅ | ✅ |
| distros:alpine_edge | `ghcr.io/goover/distros:alpine_edge` | ✅ | ✅ |

## <a name="debian-distro"></a>➡️ Debian

| Image | Status | Description |
|-------|--------|-------------|
| `goover/distros` | [![build debian](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/distros-debian.yml/badge.svg)](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/distros-debian.yml) | Debian Linux Base Images |

| Image | URI | AMD64 | ARM64 |
|-------|:---:|:-----:|:-----:|
| distros:debian_11 | `ghcr.io/goover/distros:debian_11` | ✅ | ✅ |
| distros:debian_12 | `ghcr.io/goover/distros:debian_12` | ✅ | ✅ |
| distros:debian_13 | `ghcr.io/goover/distros:debian_13` | ✅ | ✅ |

## <a name="ubuntu-distro"></a>➡️ Ubuntu

| Image | Status | Description |
|-------|--------|-------------|
| `goover/distros` | [![build ubuntu](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/distros-ubuntu.yml/badge.svg)](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/distros-ubuntu.yml) | Ubuntu Linux Base Images |

| Image | URI | AMD64 | ARM64 |
|-------|:---:|:-----:|:-----:|
| distros:ubuntu_18 | `ghcr.io/goover/distros:ubuntu_18` | ✅ | ✅ |
| distros:ubuntu_20 | `ghcr.io/goover/distros:ubuntu_20` | ✅ | ✅ |
| distros:ubuntu_22 | `ghcr.io/goover/distros:ubuntu_22` | ✅ | ✅ |
| distros:ubuntu_24 | `ghcr.io/goover/distros:ubuntu_24` | ✅ | ✅ |

---

# <a name="installer-images"></a>📦 Installer Images

| Image | Status | Description |
|-------|--------|-------------|
| `goover/installers` | [![build installers](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/installers.yml/badge.svg)](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/installers.yml) | Installer Images |

| Image | URI | AMD64 | ARM64 | Description |
|-------|:---:|:-----:|:-----:|-------------|
| installers:alpine | `ghcr.io/goover/installers:alpine` | ✅ | ✅ | Alpine Installer |
| installers:debian | `ghcr.io/goover/installers:debian` | ✅ | ✅ | Debian Installer |
| installers:ubuntu | `ghcr.io/goover/installers:ubuntu` | ✅ | ✅ | Ubuntu Installer |
| installers:nodejs | `ghcr.io/goover/installers:nodejs` | ✅ | ✅ | Node.js Installer |
| installers:nodejs16 | `ghcr.io/goover/installers:nodejs16` | ✅ | ✅ | Node.js 16 Installer |
| installers:python | `ghcr.io/goover/installers:python` | ✅ | ✅ | Python Installer |
| installers:python39 | `ghcr.io/goover/installers:python39` | ✅ | ✅ | Python 3.9 Installer |

---

# <a name="alpine-images"></a>🏔️ Alpine Images

| Image | Status | Description |
|-------|--------|-------------|
| `goover/alpine` | [![build alpine](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/emu-wine-alpine.yml/badge.svg)](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/emu-wine-alpine.yml) | Alpine Specialty Images |

| Image | URI | AMD64 | ARM64 | Description |
|-------|:---:|:-----:|:-----:|-------------|
| alpine:nodejs18 | `ghcr.io/goover/alpine:nodejs18` | ✅ | ✅ | Alpine + Node.js 18 |
| alpine:nodejs20 | `ghcr.io/goover/alpine:nodejs20` | ✅ | ✅ | Alpine + Node.js 20 |
| alpine:wine | `ghcr.io/goover/alpine:wine` | ✅ | ❌ | Alpine + Wine |

---

# <a name="voice-images"></a>🎙️ Voice Images

| Image | Status | Description |
|-------|--------|-------------|
| `goover/voice` | [![build voice](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/voice.yml/badge.svg)](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/voice.yml) | Voice Server Images |

| Image | URI | AMD64 | ARM64 | Description |
|-------|:---:|:-----:|:-----:|-------------|
| voice:teaspeak | `ghcr.io/goover/voice:teaspeak` | ✅ | ✅ | TeaSpeak Server |

---

# <a name="custom-images"></a>🔧 Custom Images

| Image | Status | Description |
|-------|--------|-------------|
| `goover/custom` | [![build custom](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/custom.yml/badge.svg)](https://github.com/gOOvER/pelican-ptero-images/actions/workflows/custom.yml) | Custom Specialty Images |

| Image | URI | AMD64 | ARM64 | Description |
|-------|:---:|:-----:|:-----:|-------------|
| custom:node16132 | `ghcr.io/goover/custom:node16132` | ✅ | ✅ | Node.js 16.13.2 |
| custom:rustserverredirect | `ghcr.io/goover/custom:rustserverredirect` | ✅ | ❌ | Rust Server Redirect |

---

## 📜 License

This project is licensed under the AGPL-3.0-or-later License - see the [LICENSE](LICENSE) file for details.

## 💬 Support

- Discord: [discord.com/invite/RmqSeYBQ4y](https://discord.com/invite/RmqSeYBQ4y)
- Issues: [GitHub Issues](https://github.com/gOOvER/pelican-ptero-images/issues)
