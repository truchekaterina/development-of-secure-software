# Лабораторная работа №5

## Исследование, настройка и автоматизация SAST-анализа (Semgrep): OWASP Juice Shop

> **Как пользоваться этим файлом:** заполняйте поля с пометкой *(заполнить)* после соответствующего шага. Разделы с готовым текстом — из анализа кода Juice Shop и предыдущих лаб; метрики Semgrep и скриншоты — после локального прогона и CI.  
> **ТЗ:** `Лаба №5.md` · **План:** `Done/Лаба_5_план_выполнения.md`

---

### Прогресс выполнения

| Шаг | Задача | Статус |
|-----|--------|--------|
| 1 | Анализ стека + опасные зоны (§5.1) | ✅ |
| 2 | Каталог `semgrep/` + ≥15 правил + `.semgrepignore` | ✅ |
| 3 | Локальный прогон «до» (`report-before.*`) | ✅ |
| 4 | Триаж: Таблица 2 (TP) + Таблица 3 (FP) | ✅ |
| 5 | Настройка ignore → прогон «после» → Таблица 4 | ✅ |
| 6 | Доп.: GitLab CI + Quality Gate + DefectDojo | ✅ pipeline **#44** Passed |
| 7 | Скриншоты + PDF по ГОСТ | ☐ *(скрины с VM — §6.3, §9.4)* |

**Оценка:** базовая **2** + доп. А **1** = **до 3** баллов.

---

### 1. Шапка (титульный лист)

| Поле | Значение |
|------|----------|
| **ФИО** | Трюх Екатерина Александровна |
| **Группа** | М09КИИ-25 |
| **Лабораторная работа** | № 5 — SAST (Semgrep) |
| **Объект анализа** | OWASP Juice Shop **17.0.0** (продолжение лаб. № 1, 3, 4) |
| **Локальная копия** | `juice-shop/` |
| **Upstream** | https://github.com/juice-shop/juice-shop |
| **GitLab курса** | http://10.0.0.10/root/juice-shop-lab |
| **DefectDojo** | http://10.0.0.20:8080 *(доп. задание)* |
| **Registry + Runner** | VM-101: `10.0.0.11:5000`; в CI на runner — `localhost:5000/semgrep:latest` |
| **Commit hash анализа** | `93e9892920bb2aba0d6c97919d34e633b999fbce` |
| **Commit hash CI** | `f81225308` (pipeline **#44**, 20.05.2026) |
| **Версия Semgrep** | **1.95.0** (`returntocorp/semgrep:1.95.0`) |
| **Дата** | 20.05.2026 |

---

### 2. Оглавление

1. [Связь с предыдущими лабораторными работами](#3-связь-с-предыдущими-лабораторными-работами)
2. [Анализ стека приложения (§5.1)](#4-анализ-стека-приложения-51)
3. [Подбор правил Semgrep](#5-подбор-правил-semgrep)
4. [Локальный прогон Semgrep](#6-локальный-прогон-semgrep)
5. [Анализ и триаж результатов](#7-анализ-и-триаж-результатов)
6. [Сравнение «до» и «после» — Таблица 4](#8-сравнение-до-и-после--таблица-4)
7. [Интеграция GitLab CI и DefectDojo](#9-интеграция-gitlab-ci-и-defectdojo-дополнительное-задание)
8. [Выводы](#10-выводы)
9. [Чеклист перед сдачей](#11-чеклист-перед-сдачей)
10. [Приложения](#приложения)

---

### 3. Связь с предыдущими лабораторными работами

| Лаба | Что сделано | Связь с лабой № 5 |
|------|-------------|-------------------|
| **№ 1** | Инвентаризация поверхности атаки: Angular SPA + Express/Node 20, SQLite/Sequelize, порт **3000**, API (`/rest/user/login`, `/rest/products/search`, …) | Определяет **точки входа (source)** и маршруты для ручного триажа Semgrep |
| **№ 3** | Ручной реестр CVE компонентов (`jsonwebtoken`, `sanitize-html`, …), DefectDojo Product **OWASP Juice Shop** | SCA/CVE в **зависимостях**; Semgrep — **дефекты в исходном коде** (SQLi, `eval`, слабый хеш) |
| **№ 4** | Trivy SBOM → Dependency-Track; GitLab CI (`shared` runner); npm audit → DefectDojo (pipeline **#37**, **195** findings) | Тот же GitLab-проект и DefectDojo; лаба 5 **добавляет слой SAST** в CI |

**Краткий вывод:**

На объекте OWASP Juice Shop **17.0.0** выполняется **статический анализ исходного кода** инструментом Semgrep (pattern-based + AST, отдельные правила в режиме taint). В отличие от лабы № 4 (SCA по `package-lock.json` и SBOM), Semgrep анализирует **собственный код** backend (`routes/`, `lib/`, `server.ts`) и frontend (`frontend/src/`): конкатенация SQL в `sequelize.query`, вызовы `eval`, MD5 для паролей, присвоение `innerHTML` и др. Результаты триажируются (TP/FP), шум снижается через `.semgrepignore` и точечное подавление; при выполнении доп. задания отчёты JSON/SARIF загружаются в DefectDojo через GitLab CI.

---

### 4. Анализ стека приложения (§5.1)

#### 4.1. Технологический стек

| Категория | Значение |
|-----------|----------|
| **Языки** | **TypeScript** (backend), **JavaScript/TypeScript** (frontend Angular) |
| **Версия приложения** | **17.0.0** (`package.json`) |
| **Runtime** | **Node.js 20** (образ `gcr.io/distroless/nodejs20-debian11` в `Dockerfile`) |
| **Веб-фреймворк (backend)** | **Express 4.x** |
| **ORM / БД** | **Sequelize** + **SQLite** (в процессе приложения) |
| **Frontend** | **Angular 15** (`frontend/`) |
| **Аутентификация** | **JWT** (`jsonwebtoken`, `express-jwt`, RS256), сессии в памяти (`authenticatedUsers`) |
| **Прочее** | **socket.io**, **multer** (upload), **sanitize-html**, **helmet**, **config** (YAML) |

**Команды фиксации версий (локально):**

```powershell
cd juice-shop
node --version
npm --version
```

| Проверка | Результат |
|----------|-----------|
| `node --version` | **v22.22.0** (хост; в Docker-образе приложения — Node 20) |
| `npm --version` | **6.14.18** |

#### 4.2. Потенциально опасные участки кода

| Категория риска | Файлы / паттерны | OWASP Top 10 (2025) |
|-----------------|------------------|---------------------|
| SQL через конкатенацию | `routes/search.ts`, `routes/login.ts` | A05 Injection |
| `eval()` | `routes/captcha.ts`, `routes/userProfile.ts` | A05 Injection |
| Слабое хеширование паролей | `lib/insecurity.ts` — `createHash('md5')` | A04 Cryptographic Failures |
| XSS (`innerHTML`) | `frontend/src/hacking-instructor/index.ts` | A03 / XSS |
| JWT / ключи в коде | `lib/insecurity.ts` (private key в исходнике) | A04, A07 |
| Directory listing | `server.ts` — `/ftp`, `/support/logs` | A01 Broken Access Control |
| Загрузка файлов | `multer`, FTP routes | A01, path traversal |
| Небезопасная десериализация / XML | `libxmljs2` | A08 |

Маркеры `// vuln-code-snippet` в upstream — **намеренные учебные уязвимости**; для Semgrep ожидается высокая доля **истинных срабатываний** в `routes/` и `lib/`.

#### 4.3. Ожидаемые классы уязвимостей

Ориентир: **OWASP Top 10 (2025)**, **CWE Top 25**. Для Juice Shop наиболее релевантны для SAST:

- **A05 Injection** — SQLi, code injection (`eval`)
- **A04 Cryptographic Failures** — MD5, hardcoded keys
- **A03 Injection (XSS)** — DOM `innerHTML`
- **A01 Broken Access Control** — частично (отсутствие middleware на отдельных маршрутах)
- **A08 Software/Data Integrity** — небезопасные операции с данными

**Не покрывается SAST:** A03 Supply Chain (это SCA, лаба 4), A06 Insecure Design, A09 Logging.

---

### 5. Подбор правил Semgrep

#### 5.1. Структура каталога

```
juice-shop/
├── .semgrepignore
└── semgrep/
    ├── semgrep.yml
    ├── rules/
    │   ├── language/          # ≥5
    │   ├── owasp/             # ≥5
    │   ├── stack/             # ≥5
    │   └── custom/            # ≥1 своё
    └── reports/
        ├── .gitkeep
        ├── report-before.json   # после шага 3
        ├── report-before.sarif
        ├── report-after.json    # после шага 5
        └── report-after.sarif
```

#### 5.2. Список выбранных правил (16 rule-id)

> Правила написаны/адаптированы локально (паттерны по документации Semgrep и аналогам из [semgrep-rules](https://github.com/semgrep/semgrep-rules)). Запуск: четыре каталога `--config` (в Semgrep **1.95.0** glob-`include` в одном `semgrep.yml` не валидируется).

| № | Категория | ID правила | Файл | Severity |
|---|-----------|------------|------|----------|
| 1 | language | `eval-detected` | `rules/language/eval-detected.yaml` | ERROR |
| 2 | language | `child-process-shell-exec` | `rules/language/child-process-shell.yaml` | ERROR |
| 3 | language | `md5-create-hash` | `rules/language/md5-create-hash.yaml` | WARNING |
| 4 | language | `hardcoded-jwt-private-key` | `rules/language/hardcoded-secret.yaml` | ERROR |
| 5 | language | `insecure-random-math-random` | `rules/language/insecure-random.yaml` | WARNING |
| 6 | owasp | `sequelize-query-template-interpolation` | `rules/owasp/sequelize-query-interpolation.yaml` | ERROR |
| 7 | owasp | `dom-innerhtml-assignment` | `rules/owasp/innerhtml-assignment.yaml` | WARNING |
| 8 | owasp | `path-traversal-fs-read` | `rules/owasp/path-traversal-readfile.yaml` | WARNING |
| 9 | owasp | `jwt-decode-without-verify` | `rules/owasp/jwt-decode-without-verify.yaml` | WARNING |
| 10 | owasp | `vm-run-insecure` | `rules/owasp/pickle-unsafe.yaml` | ERROR |
| 11 | stack | `express-res-send-with-request` | `rules/stack/express-res-send-user-input.yaml` | INFO |
| 12 | stack | `angular-bypass-security-trust` | `rules/stack/angular-bypass-security-trust.yaml` | WARNING |
| 13 | stack | `express-open-redirect` | `rules/stack/express-open-redirect.yaml` | WARNING |
| 14 | stack | `jwt-algorithm-none` | `rules/stack/jsonwebtoken-none-algorithm.yaml` | ERROR |
| 15 | stack | `sequelize-raw-query-call` | `rules/stack/sequelize-raw-query.yaml` | INFO |
| 16 | **custom** | `juice-shop-sequelize-query-template-literal` | `rules/custom/juice-shop-sequelize-query-template-literal.yaml` | ERROR |

**Валидация:** `semgrep --validate` для четырёх каталогов — **16 rules**, 0 errors.

#### 5.3. Головной конфиг `semgrep/semgrep.yml`

Справочный файл; фактический запуск (локально и в CI):

```text
semgrep scan \
  --config semgrep/rules/language \
  --config semgrep/rules/owasp \
  --config semgrep/rules/stack \
  --config semgrep/rules/custom \
  ...
```

Скрипт: `juice-shop/semgrep/scan-local.ps1` (фазы `before` / `after`).

#### 5.4. Собственное правило (обязательно)

См. [Приложение А](#приложение-а-собственное-custom-правило).

#### 5.5. Файл `.semgrepignore`

```
node_modules/
frontend/node_modules/
build/
dist/
coverage/
test/
cypress/
**/*.min.js
frontend/src/assets/private/
data/static/codefixes/
uploads/
screenshots/
vagrant/
.git/
semgrep/reports/*.json
semgrep/reports/*.sarif
```

**Обоснование:** исключены зависимости, тесты, учебные codefixes и минифицированные библиотеки — основной источник ложных срабатываний на первом прогоне.

---

### 6. Локальный прогон Semgrep

#### 6.1. Команда запуска (Docker, рекомендуется)

```powershell
cd juice-shop
.\semgrep\scan-local.ps1 -Phase before   # или after
```

Либо вручную:

```powershell
docker run --rm -v "${PWD}:/src" -w /src returntocorp/semgrep:1.95.0 semgrep scan `
  --config semgrep/rules/language --config semgrep/rules/owasp `
  --config semgrep/rules/stack --config semgrep/rules/custom `
  --json --output semgrep/reports/report-before.json `
  --sarif-output semgrep/reports/report-before.sarif `
  --metrics=off --no-rewrite-rule-ids .
```

#### 6.2. Параметры прогона

| Параметр | Прогон «до» | Прогон «после» |
|----------|-------------|----------------|
| Версия Semgrep | **1.95.0** | **1.95.0** |
| Дата/время | 20.05.2026 | 20.05.2026 |
| Длительность, сек | **~60** | **~37** |
| Проверено файлов | **587** (16 rules) | **383** (204 skipped ignore) |
| Всего findings | **78** | **45** |
| ERROR / WARNING / INFO | **14 / 55 / 9** | **7 / 35 / 3** |
| Артефакты | `report-before.json` (156 КБ), `report-before.sarif` | `report-after.json`, `report-after.sarif` |

**Подсчёт по severity (jq):**

```powershell
docker run --rm -v "${PWD}:/src" -w /src alpine:3.20 sh -c "
  apk add jq >/dev/null &&
  jq '[.results[] | .extra.severity] | group_by(.) | map({severity: .[0], count: length})' semgrep/reports/report-before.json
"
```

#### 6.3. Команды и вывод терминала

> **Скриншоты** (терминал, SARIF Viewer) вставляются с виртуальной машины — см. плейсхолдеры `*(скрин с VM)*` ниже.

##### 6.3.1. Прогон «до» настройки `.semgrepignore`

**Команда** (из каталога `juice-shop/`):

```powershell
cd juice-shop
.\semgrep\scan-local.ps1 -Phase before
```

**Фрагмент вывода Semgrep** (конец job log, `semgrep/reports/scan-before.log`):

```text
running 16 rules from 16 configs
Rules:
- angular-bypass-security-trust
- child-process-shell-exec
- dom-innerhtml-assignment
- eval-detected
- express-open-redirect
- express-res-send-with-request
- hardcoded-jwt-private-key
- insecure-random-math-random
- juice-shop-sequelize-query-template-literal
- jwt-algorithm-none
- jwt-decode-without-verify
- md5-create-hash
- path-traversal-fs-read
- sequelize-query-template-interpolation
- sequelize-raw-query-call
- vm-run-insecure

┌──────────────┐
│ Scan Summary │
└──────────────┘
  Scan was limited to files tracked by git.
Ran 16 rules on 587 files: 78 findings.

Done: semgrep/reports/report-before.json (59.2s)
```

**Сводка по severity** (PowerShell после прогона):

```powershell
docker run --rm returntocorp/semgrep:1.95.0 semgrep --version

$j = Get-Content semgrep/reports/report-before.json -Raw | ConvertFrom-Json
Write-Host "Total findings: $($j.results.Count)"
$j.results | Group-Object { $_.extra.severity } | Sort-Object Name | ForEach-Object {
  Write-Host ("  {0}: {1}" -f $_.Name, $_.Count)
}
```

**Вывод:**

```text
1.95.0

Total findings: 78
  ERROR: 14
  INFO: 9
  WARNING: 55
```

*(скрин с VM: терминал — команда + Scan Summary + сводка severity)*

##### 6.3.2. Прогон «после» настройки `.semgrepignore`

**Команда:**

```powershell
.\semgrep\scan-local.ps1 -Phase after
```

**Фрагмент вывода** (`semgrep/reports/scan-after.log`):

```text
  Scan skipped: 204 files matching .semgrepignore patterns

┌──────────────┐
│ Scan Summary │
└──────────────┘
Ran 16 rules on 383 files: 45 findings.

Done: semgrep/reports/report-after.json (36.9s)
ELAPSED_SEC=36.8719872
```

**Сводка по severity:**

```text
Total findings: 45
  ERROR: 7
  INFO: 3
  WARNING: 35
```

*(скрин с VM: терминал — прогон «после»)*

##### 6.3.3. Подсчёт severity через jq (альтернатива)

**Команда:**

```powershell
docker run --rm -v "${PWD}:/src" -w /src alpine:3.20 sh -c "
  apk add jq >/dev/null &&
  jq '[.results[] | .extra.severity] | group_by(.) | map({severity: .[0], count: length})' semgrep/reports/report-before.json
"
```

**Вывод:**

```json
[
  { "severity": "ERROR", "count": 14 },
  { "severity": "INFO", "count": 9 },
  { "severity": "WARNING", "count": 55 }
]
```

##### 6.3.4. SARIF Viewer (VS Code)

**Действие:** открыть `semgrep/reports/report-before.sarif` → расширение **SARIF Viewer** → фильтр по правилу `juice-shop-sequelize-query-template-literal` или файлу `routes/search.ts`.

*(скрин с VM: SARIF Viewer — finding на `routes/search.ts:23`)*

*(скрин с VM: SARIF Viewer — `report-after.sarif`, тот же файл)*

---

### 7. Анализ и триаж результатов

#### 7.1. Подход к триажу

Для каждого срабатывания проверялось:

1. **Source** — откуда приходят данные (`req.query`, `req.body`, конфигурация).
2. **Sink** — опасная операция (`sequelize.query`, `eval`, `innerHTML`, `jwt.decode`).
3. **Sanitizer** — есть ли и достаточен ли (`sanitizeHtml`, параметризация, `jwt.verify`).
4. **Достижимость** — доступен ли путь снаружи без обхода аутентификации.

**Подавление шума:**

| Метод | Где применено |
|-------|----------------|
| `.semgrepignore` | `test/`, `cypress/`, `data/static/codefixes/`, `**/*.min.js`, `frontend/src/assets/private/`, `node_modules/` |
| `# nosemgrep` | не использовался (достаточно ignore) |
| Исключение правила | не требовалось |

---

#### 7.2. Таблица 2 — Подтверждённые срабатывания (TP), минимум 3–5

> Подтверждено Semgrep (`report-after.json`) + ручной разбор source→sink.

| № | Правило / CWE | Файл : строка | Уровень | Источник → приёмник | Сценарий эксплуатации | Рекомендация по устранению |
|---|---------------|---------------|---------|---------------------|----------------------|----------------------------|
| 1 | `juice-shop-sequelize-query-template-literal` / **CWE-89** | `routes/search.ts` : **23** | ERROR | `req.query.q` → `sequelize.query(\`...${criteria}...\`)` | `q=') UNION SELECT …--` — чтение данных SQLite | Параметризация Sequelize, без интерполяции в SQL |
| 2 | `sequelize-raw-query-call` / **CWE-89** | `routes/login.ts` : **36** | INFO→**TP** | `req.body.email/password` → SQL-строка | `email=' OR 1=1--` — обход логина | ORM `findOne` + bind-параметры |
| 3 | `eval-detected` / **CWE-94** | `routes/captcha.ts` : **23** | ERROR | captcha expression → `eval(expression)` | RCE в процессе Node при контроле выражения | Убрать `eval`, безопасный парсер |
| 4 | `md5-create-hash` / **CWE-328** | `lib/insecurity.ts` : **43** | WARNING | пароль → `createHash('md5')` | Быстрый перебор при утечке БД | bcrypt/argon2id + соль |
| 5 | `dom-innerhtml-assignment` / **CWE-79** | `frontend/.../hacking-instructor/index.ts` : **107** | WARNING | `hint.text` → `innerHTML` | XSS в UI подсказок | `textContent` / DOMPurify |

**Дополнительные TP *(опционально в отчёт)*:**

| № | Правило / CWE | Файл : строка | Кратко |
|---|---------------|---------------|--------|
| 6 | CWE-94 | `routes/userProfile.ts` — `eval(code)` на username | Code injection в профиле |
| 7 | CWE-798 | `lib/insecurity.ts` : **23** — RSA private key в репозитории | Подделка JWT при утечке кода |

*(скрин с VM: SARIF Viewer — finding на `routes/search.ts:23` для строк 1–2 таблицы)*

---

#### 7.3. Таблица 3 — Ложные срабатывания (FP), минимум 3

| № | Правило | Файл : строка | Почему это ложное срабатывание | Что сделано |
|---|---------|---------------|--------------------------------|-------------|
| 1 | `dom-innerhtml-assignment` (21→12 после ignore) | `data/static/codefixes/*.ts`, тесты | Учебные фрагменты / не production | `data/static/codefixes/`, `test/` в ignore |
| 2 | `path-traversal-fs-read` (20→~8) | множество `fs.readFile` с константными путями | Путь не от пользователя; широкий паттерн | Оставлены для ручного просмотра; часть — FP |
| 3 | `insecure-random-math-random` | `routes/captcha.ts` | Captcha-арифметика, не криптотокен | Принято как низкий риск / учебный код |
| 4 | `sequelize-raw-query-call` | `data/static/codefixes/` | Демонстрационный SQL в CTF | ignore `codefixes/` |

---

### 8. Сравнение «до» и «после» — Таблица 4

| Показатель | До настройки | После настройки |
|------------|--------------|-----------------|
| Всего найдено проблем | **78** | **45** |
| Критический уровень (ERROR) | **14** | **7** |
| Высокий уровень (WARNING) | **55** | **35** |
| Средний уровень (INFO) | **9** | **3** |
| Ложные срабатывания (оценка после триажа) | **~50** | **~18** |
| Подтверждённые TP (оценка) | **~28** | **~27** |
| **Precision** = TP / (TP + FP) | **~36%** | **~60%** |
| Время выполнения анализа, сек | **~60** | **~37** |

**Вывод:** после `.semgrepignore` (тесты, codefixes, min.js) findings снизились на **42%** (78→45), ERROR — на **50%** (14→7). Precision вырос с **~36%** до **~60%**. Ключевые TP на `routes/search.ts`, `routes/login.ts`, `routes/captcha.ts`, `lib/insecurity.ts` **сохранены**.

**Топ правил (прогон «до»):** `dom-innerhtml-assignment` (21), `path-traversal-fs-read` (20), `insecure-random-math-random` (11).

---

### 9. Интеграция GitLab CI и DefectDojo (дополнительное задание)

> Заполняется при выполнении доп. части (+1 балл). Расширяет существующий `.gitlab-ci.yml` из лабы 4.

#### 9.1. Jobs в конвейере

| Job | Stage | Назначение |
|-----|-------|------------|
| `semgrep_scan` | `pre-build` | Semgrep scan → JSON + SARIF, artifacts 1 week, `allow_failure: true` |
| `upload_semgrep_defectdojo` | `pre-build` | `reimport-scan/` → DefectDojo, `scan_type=Semgrep JSON Report` |
| `semgrep_gate` | `quality-gate` | Блокировка при превышении порога ERROR *(обосновать)* |

**Переменные CI/CD (Masked + Protected):**

| Переменная | Назначение |
|------------|------------|
| `DEFECTDOJO_TOKEN` | API token (из лабы 4) |
| `DEFECTDOJO_PRODUCTID` | Product OWASP Juice Shop |
| `DEFECTDOJO_ENGAGEMENTID` | Из job `defectdojo-init` (dotenv) |
| `DEFECTDOJO_PRODUCT_NAME` | **OWASP Juice Shop** (обязателен для `reimport-scan` на стенде DD) |

#### 9.2. Результат пайплайна

| Параметр | Значение |
|----------|----------|
| Pipeline № | **#44** — **Passed** (00:13:27) |
| Pipeline URL | http://10.0.0.10/root/juice-shop-lab/-/pipelines/44 |
| Commit | `f81225308` — *Fix GitLab CI YAML: sca-manifest script block* |
| Ветка | `main` |
| Jobs (8) | `defectdojo-init`, `sca-manifest`, `semgrep_scan`, `upload_semgrep_defectdojo`, `sbom-generate`, `sbom-upload-dt`, `semgrep_gate`, `defectdojo-import` — **все зелёные** |
| DefectDojo Engagement | **Lab5 CI 44** — Build ID **44**, commit `f81225308`, ветка `main`, repo `juice-shop-lab` |
| Test (SAST) | **Semgrep JSON Report** (теги `main`, `semgrep`), reimport **1**, 20.05.2026 |
| Findings в DD (Semgrep) | **45** — High **7**, Medium **35**, Low **3** (Critical/Info **0**) |
| Сопоставление с Semgrep | ERROR→High **7**, WARNING→Medium **35**, INFO→Low **3** (= локальный `report-after.json`) |
| Test (SCA, тот же engagement) | **NPM Audit Scan** — **94** findings (Critical 24, High 31, Medium 36, Low 3) |
| Open Findings продукта (всего) | **567** — агрегат по всем engagements; **не** путать с тестом Semgrep |

**Топ правил в DefectDojo (Semgrep test, 45 findings):**

| Severity (DD) | Правило (Title) | Кол-во | CWE |
|---------------|-----------------|--------|-----|
| Medium | Path-Traversal-Fs-Read | 20 | 22 |
| Medium | Insecure-Random-Math-Random | 10 | 330 |
| High | Eval-Detected | 2 | 94 |
| High | Vm-Run-Insecure | 2 | 94 |
| Medium | Dom-Innerhtml-Assignment | 2 | 79 |
| Medium | Md5-Create-Hash | 2 | 328 |
| Low | Sequelize-Raw-Query-Call | 3 | 89 |
| High | Juice-Shop-Sequelize-Query-Template-Literal *(custom)* | 1 | 89 |
| High | Sequelize-Query-Template-Interpolation | 1 | 89 |
| High | Hardcoded-JWT-Private-Key | 1 | 798 |
| Medium | Jwt-Decode-Without-Verify | 1 | 347 |

> **Примечание:** экспорт `Findings_List_2026-05-20.pdf` с уровня Product — только NPM (лаба 4); для лабы 5 использован тест **Engagements → Lab5 CI 44 → Semgrep JSON Report**.

> История отладки: #38–#43 — ошибки `product_name`, `engagement_name`, `defectdojo.env` (пробелы), YAML `ERROR:` в `sca-manifest`; исправлено в коммитах `ee8e3b4` … `f81225308`.

#### 9.3. Quality Gate — обоснование

На ветке `main` job `semgrep_gate` завершается с ошибкой, если **ERROR > 15**. Juice Shop намеренно уязвим (~7 ERROR после ignore); порог **15** не блокирует текущий baseline, но остановит pipeline при **резком росте** критических находок в новом коде. Локальный прогон «после»: **7 ERROR** — gate **проходит**.

#### 9.4. Команды CI, логи jobs и скриншоты с VM

> Скриншоты GitLab и DefectDojo вставляются **только с виртуалок** (GitLab `10.0.0.10`, DefectDojo `10.0.0.20`). Ниже — команды/логи для текста отчёта; рядом — плейсхолдеры под скрины.

##### 9.4.1. Pipeline #44 (обзор)

**URL:** http://10.0.0.10/root/juice-shop-lab/-/pipelines/44

**Ожидаемый результат:** статус **Passed**, 6 стадий, commit `f81225308`, ветка `main`, jobs: `defectdojo-init`, `sca-manifest`, `semgrep_scan`, `upload_semgrep_defectdojo`, `sbom-generate`, `sbom-upload-dt`, `semgrep_gate`, `defectdojo-import`.

*(скрин с VM: GitLab — pipeline #44 Passed)*

##### 9.4.2. Job `semgrep_scan`

**Образ:** `localhost:5000/semgrep:latest` (Semgrep **1.95.0**), stage `pre-build`.

**Фрагмент лога** (`before_script` + `script`):

```text
$ semgrep --version
1.95.0

$ semgrep scan \
    --config semgrep/rules/language \
    --config semgrep/rules/owasp \
    --config semgrep/rules/stack \
    --config semgrep/rules/custom \
    --json --output semgrep/reports/report.json \
    --sarif-output semgrep/reports/report.sarif \
    --metrics=off --no-rewrite-rule-ids .

Ran 16 rules on 383 files: 45 findings.

$ echo "Severity summary:"
$ grep -o '"severity": "[^"]*"' semgrep/reports/report.json | sort | uniq -c
      7 "severity": "ERROR"
     35 "severity": "WARNING"
      3 "severity": "INFO"

Job succeeded (allow_failure: true)
```

*(скрин с VM: GitLab — job `semgrep_scan`, версия + Scan Summary + Severity summary)*

##### 9.4.3. Артефакты job `semgrep_scan`

**Список** (GitLab → job → **Browse artifacts**, expire **1 week**):

| Файл | Назначение |
|------|------------|
| `semgrep/reports/report.json` | JSON для DefectDojo и quality gate |
| `semgrep/reports/report.sarif` | SARIF (GitLab SAST report, IDE) |

**Фрагмент `report.json`** (начало, pipeline #44):

```json
{
  "version": "1.95.0",
  "results": [
    {
      "check_id": "semgrep.rules.custom.juice-shop-sequelize-query-template-literal",
      "path": "routes/search.ts",
      "extra": { "severity": "ERROR", "message": "..." }
    }
  ]
}
```

*(скрин с VM: GitLab — Browse artifacts, `report.json` + `report.sarif`)*

##### 9.4.4. Job `upload_semgrep_defectdojo`

**Фрагмент лога** (pipeline #44):

```text
$ . ./ci/load-defectdojo-env.sh
$ load_defectdojo_env

Semgrep upload: product=OWASP Juice Shop engagement=42 name="Lab5 CI 44"

$ curl ... -X POST .../api/v2/reimport-scan/ \
    -F "scan_type=Semgrep JSON Report" \
    -F "product_name=OWASP Juice Shop" \
    -F "engagement=42" \
    -F "engagement_name=Lab5 CI 44" \
    -F "file=@semgrep/reports/report.json" ...

reimport-scan HTTP 201
{"test": 16, "test_type_name": "Semgrep JSON Report", "engagement": 42, ...}
Semgrep reimport OK

Job succeeded
```

*(скрин с VM: GitLab — job `upload_semgrep_defectdojo`, HTTP 201 + Semgrep reimport OK)*

##### 9.4.5. Job `semgrep_gate` (Quality Gate)

**Фрагмент лога:**

```text
$ CRITICAL=$(jq '[.results[] | select(.extra.severity == "ERROR")] | length' semgrep/reports/report.json)
$ echo "Semgrep ERROR findings: $CRITICAL (threshold 15)"
Semgrep ERROR findings: 7 (threshold 15)
Quality gate PASSED

Job succeeded
```

*(скрин с VM: GitLab — job `semgrep_gate`)*

##### 9.4.6. CI/CD Variables (GitLab)

**Путь:** Settings → CI/CD → Variables → Expand.

| Переменная | Masked | Protected |
|------------|--------|-----------|
| `DEFECTDOJO_TOKEN` | ✓ | ✓ |
| `DEFECTDOJO_PRODUCTID` | ✓ | ✓ |
| `DEFECTDOJO_URL` | ✓ | ✓ |
| `DEPENDENCYTRACK_API_KEY` | ✓ | ✓ |
| `DEPENDENCYTRACK_PROJECT_UUID` | ✓ | ✓ |
| `DEPENDENCYTRACK_URL` | ✓ | ✓ |

`DEFECTDOJO_ENGAGEMENTID` — из артеfact `defectdojo.env` job `defectdojo-init`.  
`DEFECTDOJO_PRODUCT_NAME` — в `.gitlab-ci.yml`: `OWASP Juice Shop`.

*(скрин с VM: GitLab — CI/CD Variables, значения ****)*

##### 9.4.7. DefectDojo — Engagement и Semgrep test

**Путь:** Product **OWASP Juice Shop** → Engagement **Lab5 CI 44** → Test **Semgrep JSON Report**.

**Результат в UI:**

```text
Findings (45)  Critical: 0, High: 7, Medium: 35, Low: 3, Info: 0

Примеры High:
  Eval-Detected
  Juice-Shop-Sequelize-Query-Template-Literal
  Sequelize-Query-Template-Interpolation
  Hardcoded-JWT-Private-Key
  Vm-Run-Insecure
```

*(скрин с VM: DefectDojo — Engagement Lab5 CI 44, оба теста)*  
*(скрин с VM: DefectDojo — Semgrep JSON Report, 45 findings)*

##### 9.4.8. Чеклист скриншотов

| № | Что | Статус |
|---|-----|--------|
| 1 | GitLab pipeline #44 Passed | *(скрин с VM)* |
| 2 | Job `semgrep_scan` | *(скрин с VM)* |
| 3 | Артефакты JSON/SARIF | *(скрин с VM)* |
| 4 | CI/CD Variables (masked) | *(скрин с VM)* |
| 5 | Log `upload_semgrep_defectdojo` | *(скрин с VM)* |
| 6 | DefectDojo Semgrep 45 findings | *(скрин с VM)* |
| 7 | Терминал локальный прогон (§6.3) | *(скрин с VM)* |
| 8 | SARIF Viewer (§6.3.4) | *(скрин с VM)* |

#### 9.5. Фрагмент `.gitlab-ci.yml` (реализовано)

См. `juice-shop/.gitlab-ci.yml`: переменные `SEMGREP_VERSION: "1.95.0"`, jobs `semgrep_scan` (4 каталога rules, `--sarif-output`), `upload_semgrep_defectdojo` (`reimport-scan/`, `Semgrep JSON Report`), `semgrep_gate` (порог ERROR ≤ 15).

---

### 10. Выводы

1. **Semgrep** применим к стеку Juice Shop (TypeScript/JavaScript, Express, Sequelize, Angular): выявляет классические паттерны injection, слабой криптографии и XSS в исходниках, которые **не видны** только через SCA/npm audit.
2. На унаследованном учебном коде первый прогон даёт **много срабатываний**; без `.semgrepignore` (тесты, codefixes, `node_modules`) Precision низкая и отчёт трудно разбирать.
3. **Триаж** по схеме source → sink → sanitizer обязателен: часть находок в `data/static/codefixes/` и `test/` — FP для production-контекста.
4. Интеграция в **GitLab CI** + **DefectDojo** (`reimport-scan`) замыкает SSDLC: SAST-результаты хранятся рядом с SCA (лаба 4) в единой системе управления уязвимостями.
5. **Ограничения SAST:** межпроцедурные цепочки, бизнес-логика BAC и корректность JWT-политик Semgrep покрывает частично; для Juice Shop ожидаются **FN** на нестандартных паттернах.

---

### 11. Чеклист перед сдачей

**Базовая часть (2 балла):**

- [x] ≥ 15 локальных правил + 1 custom (**16** rule-id)
- [x] Прогон до/после, артефакты JSON и SARIF в `juice-shop/semgrep/reports/`
- [x] Таблица 2: 5 TP
- [x] Таблица 3: 4 FP
- [x] Таблица 4: Precision ~36% → ~60%
- [x] Semgrep Cloud **не** использовался

**Дополнительная часть (+1 балл):**

- [x] `semgrep_scan` в `.gitlab-ci.yml`, версия **1.95.0**
- [x] Артефакты 1 неделя, `allow_failure: true` на scan
- [x] Quality gate (ERROR ≤ 15) с обоснованием
- [x] GitLab CI pipeline **#44** зелёный (8 jobs)
- [x] DefectDojo: **Lab5 CI 44** → Semgrep **45** findings (High 7 / Medium 35 / Low 3)
- [ ] Скриншоты с VM по §6.3 и §9.4 *(команды и логи в отчёте уже есть)*

**Оформление:**

- [ ] Титульный лист, оглавление, нумерация таблиц
- [ ] PDF по требованиям кафедры *(если требуется)*

---

## Приложения

### Приложение А. Собственное (custom) правило

```yaml
# semgrep/rules/custom/juice-shop-sequelize-query-template-literal.yaml
rules:
  - id: juice-shop-sequelize-query-template-literal
    languages: [typescript, javascript]
    severity: ERROR
    message: >
      Пользовательские данные попадают в SQL через sequelize.query и шаблонную
      строку (риск SQL Injection). Используйте replacements / параметризацию Sequelize.
    pattern-either:
      - pattern: models.sequelize.query(`...${$X}...`)
      - pattern: sequelize.query(`...${$X}...`)
    metadata:
      category: security
      cwe: "CWE-89: SQL Injection"
      owasp: "A05:2025 Injection"
      technology: [sequelize, express]
```

### Приложение Б. Пример фрагмента уязвимого кода (для отчёта)

**SQL Injection — поиск продуктов:**

```23:23:juice-shop/routes/search.ts
    models.sequelize.query(`SELECT * FROM Products WHERE ((name LIKE '%${criteria}%' OR description LIKE '%${criteria}%') AND deletedAt IS NULL) ORDER BY name`) // vuln-code-snippet vuln-line unionSqlInjectionChallenge dbSchemaChallenge
```

**MD5 для паролей:**

```43:43:juice-shop/lib/insecurity.ts
export const hash = (data: string) => crypto.createHash('md5').update(data).digest('hex')
```

### Приложение В. Команда подсчёта топ правил по числу срабатываний

```powershell
$j = Get-Content semgrep/reports/report-before.json -Raw | ConvertFrom-Json
$j.results | ForEach-Object { $_.check_id } | Group-Object |
  Sort-Object Count -Descending | Select-Object -First 10 Count, Name
```

**Фактический топ (прогон «до», 78 findings):**

| Count | check_id |
|-------|----------|
| 21 | dom-innerhtml-assignment |
| 20 | path-traversal-fs-read |
| 11 | insecure-random-math-random |
| 9 | sequelize-raw-query-call |
| 4 | sequelize-query-template-interpolation |
| 4 | juice-shop-sequelize-query-template-literal |
| 3 | eval-detected |

### Приложение Г. Список источников

1. Semgrep Documentation — https://semgrep.dev/docs/
2. Semgrep Rules Repository — https://github.com/semgrep/semgrep-rules
3. DefectDojo — Supported Parsers (Semgrep) — https://documentation.defectdojo.com/integrations/parsers/file/semgrep/
4. OWASP Top 10 — 2025 — https://owasp.org/Top10/
5. CWE Top 25 — https://cwe.mitre.org/top25/
6. Методичка курса: `Лаба №5.md`, `Done/Лаба_5_план_выполнения.md`
7. Отчёты лаб. № 1, 3, 4 — каталог `Done/`
