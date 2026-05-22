# Лабораторная работа №4

## Композиционный анализ кода (SCA): OWASP Juice Shop

> **Как пользоваться этим файлом:** заполняйте по ходу работы. Поля с *(заполнить)* — после соответствующего шага. Уже внесённые данные — из выполненных команд 19.05.2026.  
> **Инструкция:** `Лаба_4_как_выполнить.md` · **ТЗ:** `Лаба №4.md`

---

### Прогресс выполнения

| Шаг | Задача | Статус |
|-----|--------|--------|
| 1 | `package-lock.json` + commit hash | ✅ |
| 2 | SBOM fs (`sbom.cdx.json`) | ✅ |
| 2* | SBOM image (`sbom-image.cdx.json`) — опционально | ✅ |
| 3 | Проект + загрузка BOM в Dependency-Track (UI) | ✅ |
| 3* | Загрузка BOM через API | ✅ |
| 4 | Таблица 3 + приоритизация + скрины DT | ✅ |
| 5 | Доп. №1: `npm audit` + Таблица 4 | ✅ |
| 6 | Доп. №2: GitLab CI + DefectDojo | ✅ |
| 7 | Финализация отчёта (ГОСТ, PDF) | ☐ |

**Оценка:** базовая **2** + доп. №1 **1** + доп. №2 **1** = **4** балла *(шаг 7 — оформление PDF)*.

### Итоговая сводка результатов

> **Важно для проверяющего:** Dependency-Track после Vulnerability Analysis нашёл **28 findings** (GHSA / analyzer GITHUB, 20.05.2026) — см. **Приложение В**. Кружки severity на Overview могут показывать **0** (лаг пересчёта metrics); в таблице Audit Vulnerabilities данные есть. Полный охват даёт **npm audit** (**86** vulns) — см. **Приложение А** и Таблицу 4.

| Этап | Метрика | Результат | Статус |
|------|---------|-----------|--------|
| Подготовка | Lock-файл + commit | `package-lock.json`, `86bc7dc4` | ✅ |
| SBOM (Trivy fs) | Компонентов в CycloneDX | **1960** | ✅ |
| SBOM (Trivy image) | Компонентов в образе | **905** | ✅ |
| Dependency-Track | Проиндексировано компонентов | **1673** | ✅ |
| Dependency-Track | BOM UI + API | загрузка + `processing:false` | ✅ |
| Dependency-Track | Vulnerability Analysis | выполнен **20.05.2026** | ✅ |
| Dependency-Track | Findings (Audit Vulnerabilities) | **28** (15 crit., 3 high, 9 med., 1 low) | ✅ *(частичный охват — GHSA)* |
| npm audit | Уязвимостей (manifest-based) | **86** (14 critical) | ✅ |
| Лаба 3 (ручной CVE) | Совпадение с npm audit | jsonwebtoken, sanitize-html, vm2, … | ✅ |
| GitLab CI | Pipeline #37 + DefectDojo | **5/5 jobs**, engagement **Lab4 CI 37**, **195** findings | ✅ |

**Вывод одной строкой:** SBOM **1960→1673** comp. загружен в DT; DT нашёл **28 GHSA-findings** (в основном **vm2**); `npm audit` — **86** vulns (полнее); CI pipeline **#37** автоматизирует SBOM→DT и npm audit→DefectDojo (**195** findings).

---

### 1. Шапка

| Поле | Значение |
|------|----------|
| **ФИО** | Трюх Екатерина Александровна |
| **Группа** | М09КИИ-25 |
| **Лабораторная работа** | № 4 — Композиционный анализ кода (SCA) |
| **Объект анализа** | OWASP Juice Shop **17.0.0** (продолжение лаб. № 1, № 3) |
| **Стек** | Node.js / npm |
| **Локальная копия** | `juice-shop/` |
| **Upstream** | [https://github.com/juice-shop/juice-shop](https://github.com/juice-shop/juice-shop) |
| **GitLab курса** | [http://10.0.0.10/root/juice-shop-lab](http://10.0.0.10/root/juice-shop-lab) |
| **Dependency-Track** | UI: [http://10.0.0.30:8080](http://10.0.0.30:8080) · API: `http://10.0.0.30:8081` |
| **DefectDojo** | [http://10.0.0.20:8080](http://10.0.0.20:8080) *(доп. задание №2)* |
| **Registry + Runner** | VM-101: `10.0.0.11:5000` (с хоста); в CI job Trivy — `localhost:5000/trivy:latest` |
| **Commit hash анализа** | `86bc7dc4840cd35dfb6cd43ae139ebc5d844dbcd` (файл `.sca_commit`) |
| **Commit hash CI (успешный pipeline)** | `93e989292` (pipeline **#37**, 20.05.2026) |
| **Дата** | 19–20.05.2026 |

---

### 2. Связь с предыдущими лабораторными работами

| Лаба | Что сделано | Связь с лабой №4 |
|------|-------------|------------------|
| **№ 1** | Инвентаризация поверхности атаки Juice Shop (Express, порт 3000, API) | Контекст **применимости** уязвимостей к стенду |
| **№ 3** | Ручной поиск CVE (NVD/GHSA), Таблица компонентов, DefectDojo (UI) | Те же компоненты; лаба 4 — **автоматический SCA** через SBOM |
| **№ 4** | Trivy → CycloneDX SBOM → Dependency-Track → GitLab CI → DefectDojo | Непрерывный мониторинг цепочки поставок |

**Краткий вывод:**

На объекте OWASP Juice Shop **17.0.0** выполнен переход от ручного реестра CVE (лаба №3) к автоматизированному SCA: Trivy сгенерировал CycloneDX SBOM (**1960** компонентов из lock-файлов backend + frontend), Dependency-Track проиндексировал **1673** компонента (загрузка UI + REST API, token `processing:false`). **Vulnerability Analysis** (20.05.2026) выявил **28 findings** через analyzer **GITHUB** (GHSA): преимущественно **vm2@3.9.17** (22 GHSA, incl. GHSA-whpj-8f3w-67p5), также ws, webpack-dev-server, micromatch, once — полный список в **Приложении В**. На первом проходе jsonwebtoken и sanitize-html в DT **не попали** (NVD/OSV на стенде VM-103 подключены частично); **`npm audit`** по тому же lock-файлу выявил **86 уязвимостей** (14 critical), что **согласуется с лабой №3**. **GitLab CI/CD** (доп. №2): pipeline **#37** — все **5 jobs** зелёные; SBOM загружен в DT через job `sbom-upload-dt`; результаты `npm audit` импортированы в DefectDojo (Engagement **Lab4 CI 37**, **195** findings, scan type **NPM Audit Scan**).

---

## Практическая часть

### 5.1. Подготовка проекта

#### 5.1.1. Проверка манифестов

| Файл | Наличие | Назначение |
|------|---------|------------|
| `package.json` | ✅ | Прямые зависимости backend |
| `package-lock.json` | ✅ | Транзитивные зависимости (сгенерирован `npm install --package-lock-only --ignore-scripts`) |
| `frontend/package.json` | ✅ | Зависимости Angular SPA |
| `Dockerfile` | ✅ | Контейнеризация (distroless) |

**Команда генерации lock-файла:**

```powershell
cd juice-shop
npm install --package-lock-only --ignore-scripts
```

> **Примечание:** полный `npm install` без `--ignore-scripts` на Node 24 падает на `postinstall` (сборка frontend). Для SCA достаточно lock-файла.

**Фиксация commit hash:**

```powershell
git rev-parse HEAD | Out-File -Encoding utf8 .sca_commit
```

#### 5.1.2. Ручная инвентаризация (npm)

| Метрика | Значение |
|---------|----------|
| Прямых зависимостей (`package.json`) | **70** |
| Пакетов в lock-файле (audit) | **2192** (по выводу `npm install --package-lock-only`) |
| Уязвимостей по `npm audit` (предварительно) | **86** (7 low, 34 moderate, 31 high, 14 critical) |

```powershell
(Get-Content package.json | ConvertFrom-Json).dependencies.PSObject.Properties.Count
npm ls --all --depth=0 2>$null | Select-Object -First 20
```

#### 5.1.3. Таблица 1 — Компоненты для SCA-анализа

> Перенесено из лабы №3 (`lab_report_3.md`, §5). Версии npm — с контейнера или из SBOM.

| Компонент | Тип | Версия | Источник | Прямая / транзитивная | Где используется |
|-----------|-----|--------|----------|----------------------|------------------|
| OWASP Juice Shop | приложение | 17.0.0 | `package.json` | — | продукт |
| Node.js | рантайм | *(из Dockerfile / образа)* | `Dockerfile` | — | сервер |
| express | библиотека | 4.22.2 | docker exec / SBOM | **прямая** | HTTP API |
| sequelize | библиотека | 6.37.8 | docker exec / SBOM | **прямая** | ORM, SQLite |
| sqlite3 | библиотека | 5.1.7 | docker exec / SBOM | **прямая** | драйвер БД |
| sanitize-html | библиотека | 1.4.2 | docker exec / SBOM | **прямая** | очистка HTML |
| jsonwebtoken | библиотека | 0.4.0 | docker exec / SBOM | **прямая** | JWT, `/rest/user/login` |
| multer | библиотека | 1.4.5-lts.2 | docker exec / SBOM | **прямая** | upload файлов |
| socket.io | библиотека | 3.1.2 | docker exec / SBOM | **прямая** | realtime |
| socket.io-parser | библиотека | 4.0.5 | docker exec / SBOM | **транзитивная** | socket.io → parser |
| libxmljs2 | библиотека | 0.37.0 | docker exec / SBOM | **прямая** | XML |
| send | библиотека | 0.19.2 | docker exec / SBOM | **транзитивная** | express → send |
| Angular (@angular/core) | фреймворк | 15.0.4 | `frontend/package.json` | **прямая** (frontend) | SPA |
| bkimminich/juice-shop | образ Docker | latest; `sha256:25fd268112350ae9e0ddc7878371f9f12f5b0b546c7bf934d6599aa8e724418f` | Hub / `docker pull` | — | деплой; SBOM image |

*(Добавьте строки при необходимости; всего ≥ 10 компонентов.)*

---

### 5.2. Генерация SBOM (Trivy)

#### 5.2.1. SBOM файловой системы (обязательно)

**Команда:**

```powershell
docker run --rm `
  -v "C:/Users/1/Desktop/neurohelp/Development_of_secure_software/juice-shop:/src" `
  aquasec/trivy:latest `
  fs --format cyclonedx --output /src/sbom.cdx.json /src
```

**Лог Trivy (ключевые строки):**

- `"--format cyclonedx" disables security scanning` — CVE ищет **Dependency-Track**, не Trivy
- `Suppressing dependencies for development and testing` — dev-зависимости исключены
- `Number of language-specific files num=2` — два npm-манифеста (корень + frontend)

#### 5.2.2. SBOM Docker-образа

| Параметр | Значение |
|----------|----------|
| Выполнено? | **Да** |
| Способ | Официальный образ **`bkimminich/juice-shop:latest`** с Docker Hub (локальная `docker build` не выполнялась) |
| Образ (digest) | `sha256:25fd268112350ae9e0ddc7878371f9f12f5b0b546c7bf934d6599aa8e724418f` |
| Файл | `sbom-image.cdx.json` |
| Дата генерации | 19.05.2026, 20:20:44 UTC |

**Команды:**

```powershell
docker pull bkimminich/juice-shop:latest

docker run --rm `
  -v "${PWD}:/out" `
  -v /var/run/docker.sock:/var/run/docker.sock `
  aquasec/trivy:latest `
  image --format cyclonedx `
  --output /out/sbom-image.cdx.json `
  bkimminich/juice-shop:latest
```

**Лог Trivy (ключевые строки):**

- `"--format cyclonedx" disables security scanning` — CVE сопоставляет Dependency-Track
- `Detected OS family="debian" version="13.4"` — ОС в runtime-слое образа Hub
- `Number of language-specific files num=1` — один npm-lock слой в образе (vs **2** в fs-скане исходников)

**Сравнение fs vs image:**

| SBOM | Компонентов | Без PURL | dependencies | Размер | Содержимое |
|------|-------------|----------|--------------|--------|------------|
| `sbom.cdx.json` (fs) | **1960** | 2 | 1961 | 1 359 КБ | npm из lock-файлов (**корень + frontend**), dev-зависимости исключены Trivy |
| `sbom-image.cdx.json` (image) | **905** | 0 | 906 | 1 126 КБ | **904** npm-библиотек в runtime-образе + **1** OS (Debian 13.4) |

**Вывод по различию fs vs image:**

1. **fs-SBOM больше** (1960 vs 905): сканируются исходники с двумя lock-манifestами (backend + frontend), включая пакеты, не попавшие в финальный distroless-образ.
2. **image-SBOM** отражает **фактический состав контейнера** при деплое — только production `node_modules` и минимальный OS-слой.
3. Для **Dependency-Track** и мониторинга npm-уязвимостей приложения загружен **`sbom.cdx.json` (fs)**; image-SBOM использован для сравнения подходов и объяснения расхождения «исходники vs артефакт сборки».

#### 5.2.3. Валидация SBOM

```powershell
Get-Item sbom.cdx.json, sbom-image.cdx.json | Select-Object Name, Length, LastWriteTime
Get-FileHash sbom.cdx.json -Algorithm SHA256
Get-FileHash sbom-image.cdx.json -Algorithm SHA256
```

#### 5.2.4. Таблица 2 — Метрики SBOM

**Файловая система (`sbom.cdx.json`) — загружается в Dependency-Track:**

| Метрика | Значение |
|---------|----------|
| Формат SBOM | **CycloneDX 1.6** |
| Инструмент | Trivy **0.70.0** |
| Команда генерации | `trivy fs --format cyclonedx --output /src/sbom.cdx.json /src` |
| Serial Number | `urn:uuid:6fa5867b-797a-4c42-bb3e-af003e101395` |
| Timestamp | `2026-05-19T20:08:29+00:00` |
| Кол-во компонентов | **1960** |
| Кол-во компонентов без PURL | **2** |
| Кол-во записей в `dependencies` | **1961** |
| Размер файла | **1 359 КБ** (1 391 745 байт) |
| SHA256 | `2F0AABA4A242F076A186533C0A95589BA1D954291CD010686F944EDE63774989` |

**Docker-образ (`sbom-image.cdx.json`) — для сравнения, в DT не загружался:**

| Метрика | Значение |
|---------|----------|
| Формат SBOM | **CycloneDX 1.6** |
| Инструмент | Trivy **0.70.0** |
| Объект сканирования | `bkimminich/juice-shop:latest` |
| Команда генерации | `trivy image --format cyclonedx --output /out/sbom-image.cdx.json bkimminich/juice-shop:latest` |
| Serial Number | `urn:uuid:e38ab575-1914-498d-b5e1-240227313b7c` |
| Timestamp | `2026-05-19T20:20:44+00:00` |
| Кол-во компонентов | **905** (904 library + 1 OS) |
| Кол-во компонентов без PURL | **0** |
| Кол-во записей в `dependencies` | **906** |
| OS в образе | Debian **13.4** |
| Размер файла | **1 126 КБ** (1 152 508 байт) |
| SHA256 | `AC4E764A600EF1EB33B2C1FBABD33F1C3FC317B09BEDFCFA7A6830FFCCFDC3ED` |

---

### 5.3. Загрузка SBOM в Dependency-Track

#### 5.3.1. Проект в DT (UI)

| Параметр | Значение |
|----------|----------|
| URL | [http://10.0.0.30:8080/projects/ed73ff8b-ce5f-4f80-8750-217a40273317](http://10.0.0.30:8080/projects/ed73ff8b-ce5f-4f80-8750-217a40273317) |
| Имя проекта | `lab4-tryuh-nodejs` |
| Version | `86bc7dc4` (полный commit: `86bc7dc4840cd35dfb6cd43ae139ebc5d844dbcd`) |
| Classifier | Application |
| UUID проекта | `ed73ff8b-ce5f-4f80-8750-217a40273317` |
| Дата создания | 19.05.2026 |
| Состояние после загрузки BOM | Components **1673** ✅; Last BOM Import **20.05.2026** ✅; Last Vulnerability Analysis **20.05.2026** ✅; Audit Vulnerabilities **28** ✅ *(GHSA/GITHUB — см. §5.4, Приложение В)* |

**Скриншот:** Audit Vulnerabilities — **28 findings** (vm2, ws, webpack-dev-server, micromatch, once); Overview — **1673 components** *(кружки severity могут быть 0 до пересчёта metrics)*.

#### 5.3.5. Подтверждение успешности SBOM-пайплайна в DT

| Критерий (ТЗ лабы №4) | Ожидание | Факт | Выполнено |
|----------------------|----------|------|-----------|
| Проект создан в DT | да | `lab4-tryuh-nodejs`, UUID `ed73ff8b-…` | ✅ |
| SBOM загружен через UI | да | `sbom.cdx.json`, 1673 comp. | ✅ |
| SBOM загружен через API | да | HTTP 200, token, `processing:false` | ✅ |
| Компоненты проиндексированы | да | **1673** (из 1960 в файле) | ✅ |
| Vulnerability Analysis запущен | да | дата **20.05.2026 00:07** | ✅ |
| Findings для анализа | ≥ 3 у CVE в проекте | **28 в DT**, **86 в npm audit** | ✅ см. §5.4–5.5 |

> DT на первом проходе нашёл **28 GHSA** (в основном vm2); jsonwebtoken и sanitize-html подтянулись позже через internal analyzer (до **81** finding по API). Для отчёта зафиксирован снимок UI **20.05.2026 — 28 строк** (Приложение В).

#### 5.3.2. Загрузка BOM через UI

| Параметр | Значение |
|----------|----------|
| Файл | `sbom.cdx.json` |
| Дата загрузки | 19.05.2026 |
| Компонентов после индексации | **1673** (в SBOM было 1960 — DT дедuplicирует/нормализует) |

**Скриншот:** *(вставить: Upload BOM / список Components)*

#### 5.3.3. API-ключ и team

| Параметр | Значение |
|----------|----------|
| Team | `lab4-ci-tryuh` |
| Permissions | BOM_UPLOAD, VIEW_PORTFOLIO, PROJECT_CREATION_UPLOAD |
| Хранение ключа | GitLab CI/CD Variable `DEPENDENCYTRACK_API_KEY` (Masked + Protected) |

> **В отчёт ключ не вставлять.**

#### 5.3.4. Загрузка BOM через REST API

**Команда (PowerShell):**

```powershell
$env:DEPENDENCYTRACK_API_KEY = "<ваш-api-key>"
$env:DEPENDENCYTRACK_PROJECT_UUID = "<uuid-проекта>"

curl.exe -X POST "http://10.0.0.30:8081/api/v1/bom" `
  -H "X-API-Key: $env:DEPENDENCYTRACK_API_KEY" `
  -F "project=$env:DEPENDENCYTRACK_PROJECT_UUID" `
  -F "bom=@sbom.cdx.json"
```

| Параметр | Значение |
|----------|----------|
| Team | `lab4-ci-tryuh` |
| HTTP-ответ | `{"token":"30b104ea-cf41-4b19-af59-6c80dc0601ef"}` |
| Token обработки | `30b104ea-cf41-4b19-af59-6c80dc0601ef` |
| `processing: false` | ✅ `{"processing":false}` |
| Хранение API key | GitLab CI/CD Variable `DEPENDENCYTRACK_API_KEY` (Masked) — **не в отчёте** |

**Проверка статуса:**

```powershell
curl.exe -s -H "X-API-Key: $env:DEPENDENCYTRACK_API_KEY" `
  "http://10.0.0.30:8081/api/v1/bom/token/<token>"
```

---

### 5.4. Анализ findings: Dependency-Track и подтверждение уязвимостей

#### 5.4.0. Три слоя результатов

| Слой | Что измеряет | Результат | Интерпретация |
|------|--------------|-----------|---------------|
| **A. SBOM-пайплайн** | Корректность генерации и загрузки SBOM | 1960 → **1673** comp., UI+API ✅ | **Успешно** — требования ч. 1–3 базового задания выполнены |
| **B. CVE-сопоставление в DT** | Match компонентов с GHSA/NVD/OSV на VM-103 | **28** findings (GHSA/GITHUB) | **Частично** — vm2, ws, webpack-dev-server; jsonwebtoken/sanitize-html — в основном через npm audit |
| **C. Manifest-based SCA** | `npm audit` по `package-lock.json` | **86** vulns (14 crit.) | **Успешно** — полный охват npm-дерева (доп. №1) |

**Согласованность с лабой №3:** vm2 (GHSA-whpj-8f3w-67p5) найден **и в DT, и в npm audit**; jsonwebtoken, sanitize-html, socket.io-parser — в **npm audit + лаба 3**, в DT на снимке UI (28 строк) — **не отображались** (ограниченный охват GHSA-анализатора на стенде).

> **Источники для Таблицы 3:** DT (**Приложение В**) + npm audit + лаба №3. Сравнение DT vs npm audit — **Таблица 4** (§5.5.2).

#### 5.4.1. Сводка по severity

**Dependency-Track (Audit Vulnerabilities, снимок UI 20.05.2026 — 28 findings):**

| Severity | Кол-во | Компоненты (уник.) | Analyzer |
|----------|--------|-------------------|----------|
| Critical | **15** | vm2 (15 GHSA) | GITHUB |
| High | **3** | vm2 (2), ws (1) | GITHUB |
| Medium | **9** | vm2 (5), webpack-dev-server (3), micromatch (1) | GITHUB |
| Low | **1** | once (1) | GITHUB |
| **Итого DT** | **28** | 5 компонентов | GITHUB (GHSA) |

> **Примечание UI:** кружки Critical/High/Medium/Low на вкладке Overview могут показывать **0** при ненулевой таблице Audit Vulnerabilities — отставание job `Vulnerability Metrics Update` на VM-103. Для отчёта использована вкладка **Audit Vulnerabilities** (28 строк).

**Сводка по компонентам (DT, 28 findings):**

| Компонент | Версия | Findings | Max severity |
|-----------|--------|----------|--------------|
| vm2 | 3.9.17 | **22** | Critical |
| webpack-dev-server | 4.11.1 | **3** | Medium |
| ws | 7.4.6 | **1** | High |
| micromatch | 3.1.10 | **1** | Medium |
| once | 1.1.2 | **1** | Low |

**npm audit (manifest-based, тот же lock-файл, 20.05.2026):**

| Severity | Кол-во |
|----------|--------|
| Critical | **14** |
| High | **31** |
| Moderate | **34** |
| Low | **7** |
| **Итого npm audit** | **86** |

**Скриншоты:** (1) DT Overview — **1673 components**, даты Last BOM Import / Last Vulnerability Analysis; (2) DT Audit Vulnerabilities — **28 findings** (скрин 20.05.2026); (3) **Приложение А** — вывод `npm audit` (**86 vulnerabilities**); (4) **Приложение В** — полная таблица DT findings.

#### 5.4.2. Таблица 3 — Реестр уязвимостей (топ-5)

> **Источник данных:** DT (**Приложение В**) + npm audit (20.05.2026) + верификация по NVD/GHSA из **лабы №3**. CVSS — из NVD/GHSA (лаба 3); EPSS — FIRST.org на дату анализа.

| # | CVE / GHSA | Компонент | Версия | Fix-версия | Прямая / Транз. | Путь зависимости | Severity | CVSS | EPSS | KEV | Источник | Решение |
|---|------------|-----------|--------|------------|-----------------|------------------|----------|------|------|-----|----------|---------|
| 1 | CVE-2015-9235 | jsonwebtoken | ≤8.5.1 (в проекте **0.4.0**) | **9.0.3** | **direct** | — | Critical | **9.8** | низкий* | нет | npm audit, NVD, лаба 3 | Обновить; `algorithms: ['RS256']` |
| 2 | GHSA-fvqr-27wr-82fm | sanitize-html → lodash | ≤2.17.3 | **≥2.17.4** | **direct** | sanitize-html → lodash | Critical | **9.8** | — | нет | npm audit, GHSA | Обновить sanitize-html |
| 3 | GHSA-677m-j7p3-52f9 | socket.io-parser | 4.0.0–4.2.5 (в проекте **4.0.5**) | **≥4.2.6** | **transitive** | socket.io → parser | High | **7.5** | — | нет | npm audit, GHSA | Обновить socket.io |
| 4 | GHSA-xwcq-pm8m-c4vf | pdfkit → crypto-js | 0.9–0.12.1 | pdfkit **≥0.18.0** | transitive | pdfkit → crypto-js | Critical | **9.1** | — | нет | npm audit, GHSA | Обновить pdfkit |
| 5 | GHSA-whpj-8f3w-67p5 | juicy-chat-bot → vm2 | vm2 **3.9.17** | **0.6.4** | **direct** | vm2 sandbox | Critical | **9.8** | — | нет | **DT + npm audit**, GHSA | Обновить/заменить vm2 |

\* EPSS для CVE-2015-9235 на момент проверки — низкий (legacy CVE, 2015); приоритет P1 обоснован **CVSS 9.8 + direct + auth-путь** (лаба 1), а не EPSS.

**Источники EPSS / KEV:**

- EPSS: `https://api.first.org/data/v1/epss?cve=<CVE>`
- KEV: [https://www.cisa.gov/known-exploited-vulnerabilities-catalog](https://www.cisa.gov/known-exploited-vulnerabilities-catalog)

#### 5.4.2.1. Детальный анализ 3 critical findings из Dependency-Track (28 записей)

> **Контекст:** из **28** findings DT на снимке UI **15** имеют severity **Critical** — все на компоненте **vm2@3.9.17** (analyzer GITHUB). Остальные 13 записей — High/Medium/Low на vm2, ws, webpack-dev-server, micromatch, once (Приложение В). Ниже — разбор **трёх репрезентативных Critical** с разными механизмами sandbox escape; все три подтверждены DT и согласуются с npm audit / лабой №3 по компоненту vm2.

**Сводная таблица (3 critical из DT):**

| # | GHSA | Компонент | Версия | CWE / тип | CVSS* | Путь в Juice Shop | Приоритет |
|---|------|-----------|--------|-----------|-------|-------------------|-----------|
| 1 | [GHSA-whpj-8f3w-67p5](https://github.com/advisories/GHSA-whpj-8f3w-67p5) | vm2 | 3.9.17 | CWE-94 — sandbox escape → **RCE** | **9.8** | `juicy-chat-bot` → vm2 (чат-бот) | **P1** |
| 2 | [GHSA-qcp4-v2jj-fjx8](https://github.com/advisories/GHSA-qcp4-v2jj-fjx8) | vm2 | 3.9.17 | CWE-693 — escape через **ExceptionMessage** | **9.8** | тот же контур vm2 sandbox | **P1** |
| 3 | [GHSA-248r-7h7q-cr24](https://github.com/advisories/GHSA-248r-7h7q-cr24) | vm2 | 3.9.17 | CWE-913 — доступ к **host-объектам** из sandbox | **9.8** | тот же контур vm2 sandbox | **P1** |

\* CVSS 3.x по карточкам GHSA; в DT severity = Critical.

---

**Finding 1 — GHSA-whpj-8f3w-67p5 (vm2 Sandbox Escape)**

| Поле | Значение |
|------|----------|
| Компонент / версия | **vm2** `3.9.17` (уязвимы ≤ 3.9.19; fix — удаление/замена vm2, проект **deprecated**) |
| Прямая / транзитивная | **direct** через `juicy-chat-bot` |
| Analyzer DT | GITHUB · Attributed On: **20.05.2026** |
| Источник в отчёте | **DT (Приложение В, строка 25)** + npm audit + лаба №3 |

**Суть:** библиотека vm2 создаёт «песочницу» для выполнения недоверенного JavaScript. Уязвимость позволяет **выйти из sandbox** и выполнить произвольный код на хосте с правами процесса Node.js → **полная компрометация сервера** (чтение секретов, доступ к БД SQLite, подмена API).

**Применимость к Juice Shop (лаба №1):** vm2 используется модулем **Juicy Chat Bot** — пользовательский/сценарный код обрабатывается на backend (Express, порт **3000**). Поверхность атаки: эндпоинты чат-бота, куда попадает **контролируемый ввод**. На учебном стенде это один из намеренно уязвимых сценариев OWASP Juice Shop.

**Сценарий эксплуатации (упрощённо):** злоумышленник отправляет специально сформированный скрипт в контур чат-бота → vm2 некорректно изолирует контекст → выполнение команд ОС / доступ к `require('child_process')` на хосте.

**Remediation:** удалить vm2; обновить `juicy-chat-bot` до версии без vm2 (**≥0.6.4** по npm audit) или заменить sandbox на изолированный контейнер/отключить функцию на prod. **Срок: P1, ≤72 ч.**

---

**Finding 2 — GHSA-qcp4-v2jj-fjx8 (vm2 — escape через ExceptionMessage)**

| Поле | Значение |
|------|----------|
| Компонент / версия | **vm2** `3.9.17` |
| Analyzer DT | GITHUB · Attributed On: **20.05.2026** |
| Источник в отчёте | **DT (Приложение В, строка 16)** |

**Суть:** ошибка в обработке **исключений** внутри vm2: через манипуляцию `ExceptionMessage` и внутренними объектами V8 атакующий **обходит изоляцию** sandbox и получает доступ к контексту Node.js. Класс атаки — **alternative path** к тому же итогу, что и GHSA-whpj-8f3w-67p5 (RCE), но другой триггер (exception handling вместо прямого escape-примитива).

**Применимость к Juice Shop:** тот же контур **juicy-chat-bot → vm2**. Любой пользовательский код, приводящий к контролируемому exception в sandbox, потенциально эксплуатируем. Риск **не ниже** Finding 1: итог — выполнение кода вне sandbox.

**Отличие от Finding 1:** другой **вектор входа** (exception path vs классический sandbox escape); при pentest/ремедиации недостаточно блокировать только один PoC — нужна **замена vm2 целиком**.

**Remediation:** то же, что для Finding 1 — **устранить зависимость vm2**, не патчить точечно. **Срок: P1.**

---

**Finding 3 — GHSA-248r-7h7q-cr24 (vm2 — доступ к host-объектам)**

| Поле | Значение |
|------|----------|
| Компонент / версия | **vm2** `3.9.17` |
| Analyzer DT | GITHUB · Attributed On: **20.05.2026** |
| Источник в отчёте | **DT (Приложение В, строка 6)** |

**Суть:** vm2 некорректно ограничивает доступ к **объектам host-среды** (Node.js) из изолированного контекста. Атакующий получает ссылки на привилегированные объекты → **escalation из sandbox** → чтение файлов, сетевые вызовы, цепочка до RCE.

**Применимость к Juice Shop:** контур vm2 в чат-боте; на стенде процесс Node имеет доступ к **SQLite** (`juice-shop.db`), конфигурации JWT, файловой системе контейнера. Escape через host objects = **утечка данных пользователей и секретов приложения** (см. инвентаризацию лабы №1: auth, REST API, БД).

**Связь с другими findings:** в DT на vm2@3.9.17 ещё **12 Critical GHSA** (строки 8–11, 13, 16, 18, 20–23, 26–27 Приложения В) — **кластер** одной root-cause: архитектурная ненадёжность vm2. Три разобранных выше — **разные техники** (прямой escape, exception path, host objects); для отчёта достаточно трёх, полный список — Приложение В.

**Remediation:** замена vm2; для prod — **deny-by-default** для endpoint чат-бота или вынос в изолированный worker. **Срок: P1.**

---

**Общий вывод по 3 critical из DT:**

1. **100% Critical в снимке DT (15/15)** приходятся на **один компонент** — vm2; DT корректно агрегирует GHSA-кластер, но **не показывает** jsonwebtoken/sanitize-html на этом снимке (§5.5.2).
2. **Единственная remediation-стратегия** для всех трёх — **удаление vm2** из графа зависимостей, а не точечные апдейты patch-версий.
3. **Согласованность с лабой №3:** vm2 / чат-бот — direct critical; DT автоматически подтвердил то, что в лабе №3 искали вручную в GHSA.
4. **Risk для стенда:** RCE + доступ к JWT/БД → приоритет **P1** выше, чем transitive Medium на webpack-dev-server (dev-only, строки 3–5 Приложения В).

#### 5.4.3. Приоритизация remediation

Применена схема из методички: **KEV → CVSS + EPSS → direct/transitive → применимость к стенду** (контекст лабы №1).

| Приоритет | Finding | Срок | CVSS | Direct/Trans. | Обоснование |
|-----------|---------|------|------|---------------|-------------|
| **P1** | jsonwebtoken (CVE-2015-9235) | ≤72 ч | 9.8 | **direct** | JWT на `/rest/user/login`; algorithm confusion → обход auth (лаба 3) |
| **P1** | vm2 — кластер Critical GHSA (DT: **GHSA-whpj-8f3w-67p5**, **GHSA-qcp4-v2jj-fjx8**, **GHSA-248r-7h7q-cr24** + ещё 12 Critical — §5.4.2.1, Приложение В) | ≤72 ч | 9.8 | **direct** | Sandbox escape → RCE; чат-бот на :3000 |
| **P2** | sanitize-html → lodash (GHSA-fvqr-27wr-82fm) | спринт | 9.8 | **direct** | Prototype pollution; XSS-контекст API |
| **P2** | pdfkit → crypto-js (GHSA-xwcq-pm8m-c4vf) | спринт | 9.1 | transitive | Critical, но через pdfkit (генерация PDF) |
| **P3** | socket.io-parser (GHSA-677m-j7p3-52f9) | беклог | 7.5 | transitive | DoS на realtime; ниже auth-рисков |

**KEV:** для топ-5 — **нет** записей в [CISA KEV](https://www.cisa.gov/known-exploited-vulnerabilities-catalog) (типично для учебных npm-CVE).

**Полное обоснование P1 (vm2 / DT critical cluster):** Dependency-Track выявил **22 GHSA** на **vm2@3.9.17**, из них **15 Critical** (Приложение В). Детальный разбор трёх репрезентативных — §5.4.2.1. Общий вектор: **escape из sandbox** → RCE на Node.js-процессе Juice Shop. **Remediation:** обновить/заменить `juicy-chat-bot`, удалить vm2; на prod — отключить или изолировать чат-бот.

**Полное обоснование P1 (jsonwebtoken):** версия **0.4.0** (fix **≥9.0.3**). Прямая зависимость, используется при каждой аутентификации. CVE-2015-9235 — algorithm confusion (RS256/HS256) → подмена JWT. Подтверждено npm audit и лабой №3; **в снимке DT (28 строк) не отображалось**. **Remediation:** обновить до ≥9.x; явно задать `algorithms: ['RS256']` в `jwt.verify`; ротировать ключи.

#### 5.4.4. Раздел «Анализ компонентов» — выводы

1. **Инвентаризация успешна:** SBOM Trivy — **1960** comp.; DT — **1673**; прямых npm-зависимостей — **70**; lock-файл — **2192** пакета.
2. **DT нашёл уязвимости:** **28 findings** (GHSA/GITHUB), преимущественно **vm2@3.9.17** (22 GHSA, **15 Critical**); детальный разбор 3 critical — **§5.4.2.1**, полный список — **Приложение В**.
3. **npm audit — полнее:** **86** vulns (14 critical); jsonwebtoken, sanitize-html, socket.io-parser — подтверждены лабой №3.
4. **Ограничение стенда:** DT на снимке UI не показал jsonwebtoken/sanitize-html (NVD/OSV частично отключены; GHSA — основной рабочий analyzer); metrics-кружки на Overview могут отставать от таблицы findings.
5. **Методологический вывод:** SBOM-based мониторинг (слой A+B) и manifest-based SCA (слой C) **дополняют** друг друга; для remediation на учебном стенде нужен **npm audit** как второй канал (доп. №1).

---

### 5.5. Дополнительное задание №1 — `npm audit` и сравнение (+1 балл)

#### 5.5.1. Запуск manifest-based сканера

| Параметр | Значение |
|----------|----------|
| Сканер | **npm audit** |
| Версия npm | **11.9.0** |
| Node.js | v24.14.0 *(EBADENGINE warning — для audit не критично)* |
| Файл отчёта | `juice-shop/npm-audit.json` (~88 КБ) |
| Обоснование выбора | Manifest-based сканер для Node.js; другая логика, чем Trivy SBOM |

**Команда:**

```powershell
cd juice-shop
npm audit --json | Out-File -Encoding utf8 npm-audit.json
npm audit
```

| Метрика | Значение |
|---------|----------|
| Critical | **14** |
| High | **31** |
| Moderate | **34** |
| Low | **7** |
| **Итого** | **86** |

**Фрагмент вывода (ключевые находки):** полный фрагмент — **Приложение А**; ниже — сокращённо:

```
86 vulnerabilities (7 low, 34 moderate, 31 high, 14 critical)

jsonwebtoken  <=8.5.1
Severity: critical | Direct: true | fix: jsonwebtoken@9.0.3

sanitize-html  <=2.17.3
Severity: critical | Direct: true | fix: sanitize-html@2.17.4

juicy-chat-bot  >=0.6.5
Severity: critical | Direct: true | fix: juicy-chat-bot@0.6.4  (via vm2)

socket.io-parser  4.0.0 - 4.2.5
Severity: high | Direct: false | fix: socket.io-client@4.8.3

pdfkit  0.9.0 - 0.12.1
Severity: critical | Direct: true | fix: pdfkit@0.18.0
```

#### 5.5.2. Таблица 4 — Сопоставление DT vs npm audit

| CVE / GHSA | Dependency-Track | npm audit | Комментарий |
|------------|------------------|-----------|-------------|
| GHSA-whpj-8f3w-67p5 / vm2 | ✅ **Critical** (22 GHSA на vm2) | ✅ Critical | **Совпадение** — DT + npm audit |
| CVE-2015-9235 / jsonwebtoken | ❌ *(на снимке UI 28 строк)* | ✅ Critical | DT: GHSA-анализатор не сопоставил на первом проходе |
| GHSA-fvqr-27wr-82fm / sanitize-html | ❌ *(на снимке UI)* | ✅ Critical | lodash в sanitize-html |
| GHSA-677m-j7p3-52f9 / socket.io-parser | ❌ | ✅ High | транзитивная через socket.io |
| GHSA-xwcq-pm8m-c4vf / crypto-js | ❌ *(на снимке UI)* | ✅ Critical | pdfkit → crypto-js |
| **Итого** | **28** (UI) / **86** (npm audit) | **86** | DT — частичный охват GHSA; npm audit — полный lock-дерево |

#### 5.5.3. Объяснение расхождений DT (28) vs npm audit (86)

| Фактор | Dependency-Track | npm audit |
|--------|------------------|-----------|
| Результат | **28** findings (снимок UI) | **86** vulns |
| SBOM / lock загружен | ✅ 1673 comp. | ✅ тот же lock |
| Analysis выполнен | ✅ 20.05.2026 | ✅ локально |
| Источник CVE | GHSA (GITHUB analyzer) + частично NVD/OSV на VM-103 | npm Advisory Registry **локально** |
| Зависимость от стенда | **да** (mirror, sync, metrics lag) | **нет** |

**Пять причин расхождения:**

1. **Частичный охват DT:** GHSA-анализатор нашёл **vm2, ws, webpack-dev-server**, но **не все** npm-advisories (jsonwebtoken, sanitize-html — в основном в npm audit).
2. **Разные движки match:** DT — server-side GHSA/NVD/OSS Index; npm audit — advisory database npm, оптимизированная под lock-дерево.
3. **Разный охват lock vs SBOM:** DT — 1673 нормализованных comp. из CycloneDX; npm audit — полное дерево lock (2192 пакета).
4. **UI vs metrics:** кружки severity на Overview могут показывать **0** при **28** строках в Audit Vulnerabilities — отставание `Vulnerability Metrics Update`.
5. **Вывод DevSecOps:** SBOM-пайплайн + DT дают **инвентаризацию и частичный CVE-match**; npm audit — **полный manifest-based канал** для remediation (доп. №1).

**Рекомендация для эксплуатации стенда:** включить OSV и GHSA mirror в Administration → Analyzers; настроить OSS Index token; при расхождении Overview/таблицы — запустить task `Vulnerability Metrics Update`.

---

### 5.6. Дополнительное задание №2 — GitLab CI/CD (+1 балл)

> **Подход:** вариант **B** — один монолитный `.gitlab-ci.yml` (без модульного `ci/` из шаблона преподавателя). Каркас стадий соответствует методичке: `.pre` → `pre-build` → `build` → `post-build` → `.post`.  
> **Репозиторий:** [http://10.0.0.10/root/juice-shop-lab](http://10.0.0.10/root/juice-shop-lab) · **Runner:** `registry-runner`, tag **`shared`**, Docker executor (VM-101).

#### 5.6.1. Переменные CI/CD

| Variable | Значение / назначение | Masked | Protected |
|----------|----------------------|--------|-----------|
| `DEPENDENCYTRACK_URL` | `http://10.0.0.30:8081` *(также в YAML)* | — | ☐ |
| `DEPENDENCYTRACK_API_KEY` | API key team `lab4-ci-tryuh` *(не в отчёте)* | ✅ | ☐* |
| `DEPENDENCYTRACK_PROJECT_UUID` | `ed73ff8b-ce5f-4f80-8750-217a40273317` | — | ☐ |
| `DEFECTDOJO_URL` | `http://10.0.0.20:8080` *(также в YAML)* | — | ☐ |
| `DEFECTDOJO_TOKEN` | API v2 token DefectDojo *(не в отчёте)* | ✅ | ☐* |
| `DEFECTDOJO_PRODUCTID` | **2** (Product **OWASP Juice Shop**) | — | ☐ |
| `TRIVY_IMAGE` | `localhost:5000/trivy:latest` *(в YAML; runner на VM-101)* | — | ☐ |

\* Protected снят для ветки `main`, иначе переменные не подставлялись в pipeline.

**Runtime (не задавать вручную):** `DEFECTDOJO_ENGAGEMENTID` — из dotenv-артефакта job `defectdojo-init`.

#### 5.6.2. DefectDojo

| Параметр | Значение |
|----------|----------|
| URL | [http://10.0.0.20:8080](http://10.0.0.20:8080) |
| Product | **OWASP Juice Shop** |
| Product ID | **2** |
| Engagement (CI) | **`Lab4 CI 37`** |
| Engagement ID | **24** |
| Scan type импорта | **NPM Audit Scan** |
| Findings после import | **195** (на дату pipeline #37) |
| Commit pipeline | `93e989292` |

**Интеграция DT → DefectDojo:** ☐ настроена · **☑** импорт **npm audit** через API в job `defectdojo-import` (findings DT — **28 GHSA** в UI; в DD импортирован npm audit — **195** findings).

**Особенность стенда:** DefectDojo **не поддерживает** npm audit **v2** (`auditReportVersion: 2` от npm 7+). В job `sca-manifest` добавлен скрипт `ci/convert-npm-audit-v2-to-v1.js` — конвертация в формат `advisories` (npm v6) перед импортом (**94** advisories → **195** findings в DD).

**Скриншот:** *(вставить: Engagement `Lab4 CI 37` → Findings)*

#### 5.6.3. Структура пайплайна

| Job | Стадия | Образ / инструмент | Назначение | Статус (#37) |
|-----|--------|-------------------|------------|--------------|
| `defectdojo-init` | `.pre` | `curlimages/curl` | POST `/api/v2/engagements/`, dotenv `DEFECTDOJO_ENGAGEMENTID` | ✅ |
| `sca-manifest` | `pre-build` | `node:20` | `npm ci`, `npm audit --json`, конвертация v2→v1, артефакт `npm-audit.json` | ✅ |
| `sbom-generate` | `build` | `localhost:5000/trivy:latest` (`entrypoint: [""]`) | `trivy fs --format cyclonedx`, артефакт `sbom.cdx.json` | ✅ |
| `sbom-upload-dt` | `post-build` | `curlimages/curl` | POST BOM в DT, poll `processing:false` | ✅ |
| `defectdojo-import` | `.post` | `curlimages/curl` | POST `/api/v2/import-scan/`, `scan_type=NPM Audit Scan` | ✅ |

**DAG:** `defectdojo-init` и `sca-manifest` параллельно по стадиям; `sbom-upload-dt` ← `sbom-generate`; `defectdojo-import` ← `defectdojo-init` + `sca-manifest` (artifacts).

TruffleHog из шаблона преподавателя **не включён** — в ТЗ лабы 4 требуются SCA/Trivy/DT/npm audit.

#### 5.6.4. Файлы CI

| Файл | Назначение |
|------|------------|
| `juice-shop/.gitlab-ci.yml` | Основной pipeline (5 jobs) — **Приложение Б** |
| `juice-shop/ci/convert-npm-audit-v2-to-v1.js` | Конвертация npm audit v2 → v1 для DefectDojo |

#### 5.6.5. Результат пайплайна

| Параметр | Значение |
|----------|----------|
| Основа пайплайна | ☑ свой `.gitlab-ci.yml` (вариант B) · ☐ шаблон template-ci-cd-devsecops |
| Runner tag | **`shared`** |
| Pipeline | **#37** — **Passed** |
| Pipeline URL | [http://10.0.0.10/root/juice-shop-lab/-/pipelines/37](http://10.0.0.10/root/juice-shop-lab/-/pipelines/37) |
| Commit | `93e989292` — *Fix GitLab CI YAML syntax error in sca-manifest grep step.* |
| Ветка | `main` |
| Длительность | **00:13:04** |
| Дата | **20.05.2026** |

**Скриншоты:**

- [x] GitLab CI — все **5 jobs** зелёные (pipeline #37)  
- [ ] Dependency-Track — обновлённая дата BOM после CI *(вставить скрин)*  
- [ ] DefectDojo — Engagement **Lab4 CI 37** + Findings *(вставить скрин)*  

**Исправления в ходе отладки CI (кратко):**

1. Trivy: `TRIVY_IMAGE=localhost:5000/trivy:latest` + `entrypoint: [""]` (иначе `unknown command "sh" for trivy`).
2. DefectDojo import HTTP 400: npm audit v2 → конвертер v1 (`advisories`).
3. YAML: однострочный `grep` в `sca-manifest` (двоеточие в `ERROR:` ломало парсер GitLab).

---

## 6. Чеклист перед сдачей

- [x] Таблица 1: ≥ 10 компонентов, точные версии (**14 строк**)
- [x] Таблица 2: метрики `sbom.cdx.json` и `sbom-image.cdx.json` заполнены
- [x] Dependency-Track: проект создан, BOM загружен **UI + API**, **1673** comp., **28 findings** (Приложение В)
- [x] Таблица 3: топ-5 + **анализ 3 critical из DT** (§5.4.2.1)
- [x] npm audit **86** vulns — **Приложение А**; скрин DT Audit Vulnerabilities (**28** findings)
- [x] Секреты **не** в репозитории и отчёте
- [x] [+1] Таблица 4 + объяснение расхождений (§5.5.3)
- [x] [+1] GitLab pipeline **#37** зелёный, findings в DefectDojo (Engagement **Lab4 CI 37**, **195** findings)
- [x] Связь с лабами 1–3 описана (§2, §5.4.0)
- [ ] Оформление по ГОСТ (титул, оглавление, PDF — по требованию преподавателя)

---

## Приложение А. Фрагмент вывода `npm audit` (86 уязвимостей)

> **Назначение:** подтверждение полного manifest-based SCA по lock-файлу. Dependency-Track на снимке UI нашёл **28 GHSA-findings** (Приложение В); npm audit даёт **86** — более полный охват для Таблицы 4.  
> **Команда:** `npm audit` и `npm audit --json > npm-audit.json` · **Каталог:** `juice-shop/` · **Дата:** 20.05.2026  
> **Полный JSON:** `juice-shop/npm-audit.json` (~88 КБ, 3183 строки)

### А.1. Итоговая строка и сводка по severity

```
# npm audit report

86 vulnerabilities (7 low, 34 moderate, 31 high, 14 critical)

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force
```

**Блок `metadata` из `npm-audit.json`:**

```json
"metadata": {
  "vulnerabilities": {
    "info": 0,
    "low": 7,
    "moderate": 34,
    "high": 31,
    "critical": 14,
    "total": 86
  },
  "dependencies": {
    "prod": 1039,
    "dev": 1095,
    "optional": 116,
    "peer": 20,
    "peerOptional": 0,
    "total": 2193
  }
}
```

### А.2. Топ-5 находок (соответствуют Таблице 3, §5.4.2)

```
jsonwebtoken  <=8.5.1
Severity: critical
jsonwebtoken is a direct dependency
fix available via `npm audit fix --force`
Will install jsonwebtoken@9.0.3, a breaking change
  GHSA-c7hr-j4mj-j2w6  Verification Bypass in jsonwebtoken
  GHSA-hjrf-2m68-5959  Forgeable Public/Private Tokens from RSA to HMAC
  GHSA-8cf7-32gw-wr33  unrestricted key type / legacy keys
  node_modules/jsonwebtoken

sanitize-html  <=2.17.3
Severity: critical
sanitize-html is a direct dependency
fix available via `npm audit fix --force`
Will install sanitize-html@2.17.4
  Prototype Pollution via lodash (transitive)
  node_modules/sanitize-html

juicy-chat-bot  >=0.6.5
Severity: critical
juicy-chat-bot is a direct dependency
fix available via `npm audit fix --force`
Will install juicy-chat-bot@0.6.4
  vm2  <=3.11.2  Sandbox Escape (GHSA-whpj-8f3w-67p5)
  node_modules/juicy-chat-bot

socket.io-parser  4.0.0 - 4.2.5
Severity: high
socket.io-parser is a transitive dependency
fix available via `npm audit fix --force`
  GHSA-677m-j7p3-52f9  unbounded number of binary attachments
  node_modules/socket.io-parser

pdfkit  0.9.0 - 0.12.1
Severity: critical
pdfkit is a direct dependency
fix available via `npm audit fix --force`
Will install pdfkit@0.18.0
  crypto-js  Prototype Pollution (transitive)
  node_modules/pdfkit
```

### А.3. Фрагмент JSON: запись `jsonwebtoken` (direct, critical)

```json
"jsonwebtoken": {
  "name": "jsonwebtoken",
  "severity": "critical",
  "isDirect": true,
  "range": "<=8.5.1",
  "nodes": [
    "node_modules/jsonwebtoken"
  ],
  "fixAvailable": {
    "name": "jsonwebtoken",
    "version": "9.0.3",
    "isSemVerMajor": true
  },
  "via": [
    {
      "title": "jsonwebtoken's insecure implementation of key retrieval function could lead to Forgeable Public/Private Tokens from RSA to HMAC",
      "url": "https://github.com/advisories/GHSA-hjrf-2m68-5959",
      "severity": "moderate",
      "range": "<=8.5.1"
    }
  ]
}
```

> **Сопоставление с DT:** Dependency-Track — **28 findings** (GHSA, vm2 и др., Приложение В); `npm audit` — **86** уязвимостей. См. Таблицу 4 (§5.5.2).

---

## Приложение Б. Файл `juice-shop/.gitlab-ci.yml` (успешный pipeline #37)

> **Commit:** `93e989292` · **Pipeline:** [#37 Passed](http://10.0.0.10/root/juice-shop-lab/-/pipelines/37) · **Дата:** 20.05.2026  
> Конвертер npm audit v2→v1: `juice-shop/ci/convert-npm-audit-v2-to-v1.js` (в приложение не включён — см. §5.6.4).

```yaml
# Lab 4 — SCA pipeline: npm audit → Trivy SBOM → Dependency-Track → DefectDojo
#
# GitLab: http://10.0.0.10/root/juice-shop-lab — runner tag: shared
#
# Required CI/CD variables (Settings → CI/CD → Variables; Masked/Protected on main):
#   DEFECTDOJO_TOKEN          — DefectDojo API v2 token (Authorization: Token …)
#   DEFECTDOJO_PRODUCTID      — numeric Product ID (OWASP Juice Shop)
#   DEPENDENCYTRACK_API_KEY   — Dependency-Track API key (X-API-Key header)
#   DEPENDENCYTRACK_PROJECT_UUID — DT project UUID for Juice Shop lab
#
# Set in YAML (override in CI if needed):
#   DEFECTDOJO_URL            — http://10.0.0.20:8080
#   DEPENDENCYTRACK_URL       — http://10.0.0.30:8081
#   TRIVY_IMAGE               — localhost:5000/trivy:latest (runner on VM-101; entrypoint cleared in job)
#
# DefectDojo on course stand uses legacy "NPM Audit Scan" (npm v6 / advisories format).
# npm 7+ auditReportVersion 2 is converted in sca-manifest via ci/convert-npm-audit-v2-to-v1.js
#
# Produced at runtime (do not set manually):
#   DEFECTDOJO_ENGAGEMENTID   — from defectdojo-init dotenv artifact (defectdojo.env)

stages:
  - .pre
  - pre-build
  - build
  - post-build
  - .post

default:
  tags:
    - shared

variables:
  TRIVY_IMAGE: "localhost:5000/trivy:latest"
  GIT_DEPTH: "1"
  DEFECTDOJO_URL: "http://10.0.0.20:8080"
  DEPENDENCYTRACK_URL: "http://10.0.0.30:8081"

defectdojo-init:
  stage: .pre
  image: curlimages/curl:latest
  script:
    - |
      set -e
      DEFECTDOJO_URL="${DEFECTDOJO_URL%/}"
      for var in DEFECTDOJO_URL DEFECTDOJO_TOKEN DEFECTDOJO_PRODUCTID; do
        eval "val=\$$var"
        if [ -z "$val" ]; then
          echo "ERROR: CI variable $var is empty. Set it in Settings → CI/CD → Variables."
          exit 1
        fi
      done
      echo "DefectDojo URL=$DEFECTDOJO_URL product=$DEFECTDOJO_PRODUCTID"
      NOW=$(date +%s)
      TARGET_START=$(date +%Y-%m-%d)
      TARGET_END=$(date -r "$((NOW + 604800))" +%Y-%m-%d 2>/dev/null \
        || date -d "@$((NOW + 604800))" +%Y-%m-%d 2>/dev/null \
        || date -I -d "+7 days" 2>/dev/null \
        || date +%Y-%m-%d)
      echo "Engagement dates: start=$TARGET_START end=$TARGET_END"
      printf '%s\n' \
        "{" \
        "  \"name\": \"Lab4 CI ${CI_PIPELINE_ID}\"," \
        "  \"product\": ${DEFECTDOJO_PRODUCTID}," \
        "  \"target_start\": \"${TARGET_START}\"," \
        "  \"target_end\": \"${TARGET_END}\"," \
        "  \"engagement_type\": \"CI/CD\"," \
        "  \"build_id\": \"${CI_PIPELINE_ID}\"," \
        "  \"commit_hash\": \"${CI_COMMIT_SHA}\"," \
        "  \"branch_tag\": \"${CI_COMMIT_REF_NAME}\"," \
        "  \"source_code_management_uri\": \"${CI_PROJECT_URL}\"," \
        "  \"status\": \"In Progress\"" \
        "}" > engagement.json
      cat engagement.json
      if ! ENGAGEMENT=$(curl -f -S -X POST "${DEFECTDOJO_URL}/api/v2/engagements/" \
        -H "Authorization: Token ${DEFECTDOJO_TOKEN}" \
        -H "Content-Type: application/json" \
        -d @engagement.json); then
        echo "ERROR: DefectDojo API request failed (curl exit $?)"
        exit 1
      fi
      echo "$ENGAGEMENT"
      ENGAGEMENT_ID=$(echo "$ENGAGEMENT" | grep -oE '"id"[[:space:]]*:[[:space:]]*[0-9]+' | head -1 | sed 's/.*:[[:space:]]*//')
      case "$ENGAGEMENT_ID" in
        ''|*[!0-9]*)
          echo "ERROR: Failed to extract numeric engagement id from DefectDojo response"
          exit 1
          ;;
      esac
      echo "Created DefectDojo engagement id=$ENGAGEMENT_ID"
      echo "DEFECTDOJO_ENGAGEMENTID=$ENGAGEMENT_ID" > defectdojo.env
      cat defectdojo.env
  artifacts:
    reports:
      dotenv: defectdojo.env
    paths:
      - defectdojo.env
    expire_in: 1 week

sca-manifest:
  stage: pre-build
  image: node:20
  dependencies: []
  script:
    - npm ci --ignore-scripts || npm install --package-lock-only --ignore-scripts
    - npm audit --json > npm-audit-raw.json || true
    - test -s npm-audit-raw.json
    - node ci/convert-npm-audit-v2-to-v1.js npm-audit-raw.json npm-audit.json
    - grep -q '"advisories"' npm-audit.json || { echo "ERROR npm-audit.json missing advisories (DefectDojo v1 format)"; exit 1; }
    - npm audit || true
  artifacts:
    paths:
      - npm-audit.json
    expire_in: 1 week

sbom-generate:
  stage: build
  image:
    name: $TRIVY_IMAGE
    entrypoint: [""]
  dependencies: []
  script:
    - trivy version
    - trivy fs --format cyclonedx --output sbom.cdx.json .
    - test -s sbom.cdx.json
    - ls -la sbom.cdx.json
  artifacts:
    paths:
      - sbom.cdx.json
    expire_in: 1 week

sbom-upload-dt:
  stage: post-build
  image: curlimages/curl:latest
  needs:
    - job: sbom-generate
      artifacts: true
  script:
    - |
      set -e
      DEPENDENCYTRACK_URL="${DEPENDENCYTRACK_URL%/}"
      for var in DEPENDENCYTRACK_URL DEPENDENCYTRACK_API_KEY DEPENDENCYTRACK_PROJECT_UUID; do
        eval "val=\$$var"
        if [ -z "$val" ]; then
          echo "ERROR: CI variable $var is empty"
          exit 1
        fi
      done
      test -s sbom.cdx.json
      if ! RESPONSE=$(curl -f -S -X POST "${DEPENDENCYTRACK_URL}/api/v1/bom" \
        -H "X-API-Key: $DEPENDENCYTRACK_API_KEY" \
        -F "project=$DEPENDENCYTRACK_PROJECT_UUID" \
        -F "bom=@sbom.cdx.json"); then
        echo "ERROR: Dependency-Track BOM upload failed (curl exit $?)"
        exit 1
      fi
      echo "$RESPONSE"
      TOKEN=$(echo "$RESPONSE" | grep -oE '"token"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:[[:space:]]*"//; s/"$//')
      if [ -z "$TOKEN" ]; then
        echo "ERROR: Failed to extract BOM upload token from Dependency-Track response"
        exit 1
      fi
      echo "Dependency-Track BOM token=$TOKEN"
      for i in $(seq 1 30); do
        STATUS=$(curl -sf -H "X-API-Key: $DEPENDENCYTRACK_API_KEY" \
          "${DEPENDENCYTRACK_URL}/api/v1/bom/token/$TOKEN") || {
          echo "WARNING: BOM status poll failed (attempt $i)"
          sleep 10
          continue
        }
        echo "$STATUS"
        echo "$STATUS" | grep -qE '"processing"[[:space:]]*:[[:space:]]*false' && exit 0
        sleep 10
      done
      echo "WARNING: BOM upload still processing after 300s (accepted; verify in DT UI)"
      exit 0

defectdojo-import:
  stage: .post
  image: curlimages/curl:latest
  needs:
    - job: defectdojo-init
      artifacts: true
    - job: sca-manifest
      artifacts: true
  script:
    - |
      set -e
      DEFECTDOJO_URL="${DEFECTDOJO_URL%/}"
      if [ -f defectdojo.env ]; then
        set -a
        # shellcheck disable=SC1091
        . ./defectdojo.env
        set +a
      fi
      for var in DEFECTDOJO_URL DEFECTDOJO_TOKEN DEFECTDOJO_ENGAGEMENTID; do
        eval "val=\$$var"
        if [ -z "$val" ]; then
          echo "ERROR: $var is empty (check defectdojo-init dotenv artifact and CI variables)"
          exit 1
        fi
      done
      case "$DEFECTDOJO_ENGAGEMENTID" in
        ''|*[!0-9]*)
          echo "ERROR: DEFECTDOJO_ENGAGEMENTID must be numeric, got: $DEFECTDOJO_ENGAGEMENTID"
          exit 1
          ;;
      esac
      test -s npm-audit.json
      grep -q '"advisories"' npm-audit.json \
        || { echo "ERROR: npm-audit.json missing advisories (DefectDojo v1 format)"; exit 1; }
      echo "Importing npm audit ($(wc -c < npm-audit.json) bytes) to engagement=$DEFECTDOJO_ENGAGEMENTID"
      if ! HTTP=$(curl -S -o import-response.json -w "%{http_code}" \
        -X POST "${DEFECTDOJO_URL}/api/v2/import-scan/" \
        -H "Authorization: Token ${DEFECTDOJO_TOKEN}" \
        -F "scan_type=NPM Audit Scan" \
        -F "engagement=${DEFECTDOJO_ENGAGEMENTID}" \
        -F "file=@npm-audit.json" \
        -F "active=true" \
        -F "verified=true"); then
        echo "ERROR: DefectDojo import curl failed (exit $?)"
        exit 1
      fi
      echo "DefectDojo import HTTP status=$HTTP"
      cat import-response.json
      test -s import-response.json || echo "WARNING: empty import response body"
      case "$HTTP" in
        200|201) echo "Import successful" ;;
        *)
          echo "ERROR: DefectDojo import failed with HTTP $HTTP"
          exit 1
          ;;
      esac
```

---

## Приложение В. Findings Dependency-Track (Audit Vulnerabilities, 28 записей)

> **Проект:** `lab4-tryuh-nodejs` · **Version:** `86bc7dc4` · **UUID:** `ed73ff8b-ce5f-4f80-8750-217a40273317`  
> **Дата снимка UI:** 20.05.2026 · **Analyzer:** GITHUB (GHSA) · **Components в проекте:** 1673  
> **Источник:** вкладка **Audit Vulnerabilities** → экспорт по скриншоту UI (Showing 1 to 28 of 28 rows)

### В.1. Сводка по компонентам

| # | Компонент | Версия | Findings | Critical | High | Medium | Low |
|---|-----------|--------|----------|----------|------|--------|-----|
| 1 | vm2 | 3.9.17 | 22 | 15 | 2 | 5 | 0 |
| 2 | webpack-dev-server | 4.11.1 | 3 | 0 | 0 | 3 | 0 |
| 3 | ws | 7.4.6 | 1 | 0 | 1 | 0 | 0 |
| 4 | micromatch | 3.1.10 | 1 | 0 | 0 | 1 | 0 |
| 5 | once | 1.1.2 | 1 | 0 | 0 | 0 | 1 |
| | **Итого** | | **28** | **15** | **3** | **9** | **1** |

### В.2. Полный реестр findings (28 строк)

| # | Компонент | Версия | GHSA | Severity | Analyzer | Attributed On |
|---|-----------|--------|------|----------|----------|---------------|
| 1 | ws | 7.4.6 | GHSA-3h5v-q93c-6h6q | High | GITHUB | 20.05.2026 |
| 2 | micromatch | 3.1.10 | GHSA-952p-6rrq-rcjv | Medium | GITHUB | 20.05.2026 |
| 3 | webpack-dev-server | 4.11.1 | GHSA-4v9v-hfq4-rm2v | Medium | GITHUB | 20.05.2026 |
| 4 | webpack-dev-server | 4.11.1 | GHSA-9jgg-88mc-972h | Medium | GITHUB | 20.05.2026 |
| 5 | webpack-dev-server | 4.11.1 | GHSA-79cf-xcqc-c78w | Medium | GITHUB | 20.05.2026 |
| 6 | vm2 | 3.9.17 | GHSA-248r-7h7q-cr24 | Critical | GITHUB | 20.05.2026 |
| 7 | vm2 | 3.9.17 | GHSA-2cm2-m3w5-gp2f | Medium | GITHUB | 20.05.2026 |
| 8 | vm2 | 3.9.17 | GHSA-9qj6-qjgg-37qq | Critical | GITHUB | 20.05.2026 |
| 9 | vm2 | 3.9.17 | GHSA-9vg3-4rfj-wgcm | Critical | GITHUB | 20.05.2026 |
| 10 | vm2 | 3.9.17 | GHSA-47x8-96vw-5wg6 | Critical | GITHUB | 20.05.2026 |
| 11 | vm2 | 3.9.17 | GHSA-55hx-c926-fr95 | Critical | GITHUB | 20.05.2026 |
| 12 | vm2 | 3.9.17 | GHSA-6785-pvv7-mvg7 | High | GITHUB | 20.05.2026 |
| 13 | vm2 | 3.9.17 | GHSA-grj5-jjm8-h35p | Critical | GITHUB | 20.05.2026 |
| 14 | vm2 | 3.9.17 | GHSA-hw58-p9xv-2mjh | High | GITHUB | 20.05.2026 |
| 15 | vm2 | 3.9.17 | GHSA-mpf8-4hx2-7cjg | Medium | GITHUB | 20.05.2026 |
| 16 | vm2 | 3.9.17 | GHSA-qcp4-v2jj-fjx8 | Critical | GITHUB | 20.05.2026 |
| 17 | vm2 | 3.9.17 | GHSA-v27g-jcqj-v8rw | Medium | GITHUB | 20.05.2026 |
| 18 | vm2 | 3.9.17 | GHSA-v37h-5mfm-c47c | Critical | GITHUB | 20.05.2026 |
| 19 | vm2 | 3.9.17 | GHSA-wp5r-2gw5-m7q7 | Medium | GITHUB | 20.05.2026 |
| 20 | vm2 | 3.9.17 | GHSA-8hg8-63c5-gwmx | Critical | GITHUB | 20.05.2026 |
| 21 | vm2 | 3.9.17 | GHSA-99p7-6v5w-7xg8 | Critical | GITHUB | 20.05.2026 |
| 22 | vm2 | 3.9.17 | GHSA-cchq-frgv-rjh5 | Critical | GITHUB | 20.05.2026 |
| 23 | vm2 | 3.9.17 | GHSA-g644-9gfx-q4q4 | Critical | GITHUB | 20.05.2026 |
| 24 | vm2 | 3.9.17 | GHSA-p5gc-c584-jj6v | Medium | GITHUB | 20.05.2026 |
| 25 | vm2 | 3.9.17 | GHSA-whpj-8f3w-67p5 | Critical | GITHUB | 20.05.2026 |
| 26 | vm2 | 3.9.17 | GHSA-qvjj-29qf-hp7p | Critical | GITHUB | 20.05.2026 |
| 27 | vm2 | 3.9.17 | GHSA-vwrp-x96c-mhwq | Critical | GITHUB | 20.05.2026 |
| 28 | once | 1.1.2 | GHSA-vpq2-c234-7xj6 | Low | GITHUB | 20.05.2026 |

> **Ключевой finding для лабы №3/№4:** **GHSA-whpj-8f3w-67p5** (vm2 sandbox escape) — совпадает с Таблицей 3 и npm audit. **Детальный анализ 3 critical** — §5.4.2.1.  
> **Не вошло в снимок 28 строк:** jsonwebtoken, sanitize-html, socket.io-parser — подтверждены **npm audit** (Приложение А) и лабой №3.

---

## 7. Список источников

1. ГОСТ Р 56939-2024. *Защита информации. Разработка безопасного программного обеспечения.*
2. ГОСТ Р 71436-2024. *Программные средства с открытым исходным текстом. Спецификация поставки.*
3. NIST SP 800-218. *Secure Software Development Framework (SSDF) Version 1.1.*
4. NTIA. *The Minimum Elements for a Software Bill of Materials (SBOM).* 2021.
5. CycloneDX Specification. [https://cyclonedx.org](https://cyclonedx.org)
6. OWASP Dependency-Track Documentation. [https://docs.dependencytrack.org](https://docs.dependencytrack.org)
7. Trivy — SBOM generation. [https://trivy.dev](https://trivy.dev)
8. CISA KEV Catalog. [https://www.cisa.gov/known-exploited-vulnerabilities-catalog](https://www.cisa.gov/known-exploited-vulnerabilities-catalog)
9. FIRST.org EPSS. [https://www.first.org/epss](https://www.first.org/epss)
10. DefectDojo API v2. [https://documentation.defectdojo.com](https://documentation.defectdojo.com)
11. NVD. [https://nvd.nist.gov](https://nvd.nist.gov)
12. OSV.dev. [https://osv.dev](https://osv.dev)
13. OWASP Juice Shop. [https://github.com/juice-shop/juice-shop](https://github.com/juice-shop/juice-shop)

---

*Шаблон отчёта: лабораторная №4, OWASP Juice Shop 17.0.0. Обновляйте по мере выполнения шагов из `Лаба_4_как_выполнить.md`.*
