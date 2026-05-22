# Лабораторная работа №3

## Управление и поиск уязвимостей в используемых компонентах: OWASP Juice Shop

### 1. Шапка


| Поле                            | Значение                                                                                                           |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| **ФИО**                         | Трюх Екатерина Александровна                                                                                       |
| **Группа**                      | М09КИИ-25                                                                                                          |
| **Лабораторная работа**         | № 3                                                                                                                |
| **Объект анализа**              | OWASP Juice Shop **17.0.0** (продолжение лаб. № 1)                                                                 |
| **Репозиторий на GitLab курса** | `http://10.0.0.10` (материалы курса DevSecOps); локальная рабочая копия — каталог `Development_of_secure_software` |
| **Локальная копия**             | `juice-shop/` (версия в `package.json`: **17.0.0**)                                                                |
| **Upstream**                    | [https://github.com/juice-shop/juice-shop](https://github.com/juice-shop/juice-shop)                               |
| **Стенд приложения**            | Docker на рабочей станции: `http://127.0.0.1:3000` *(или `localhost:3000`)*                                        |
| **DefectDojo (стенд курса)**    | [http://10.0.0.20:8080](http://10.0.0.20:8080)                                                                     |
| **Дата**                        | 19.05.2026                                                                                                         |


---

### 2. Связь с лабораторной работой № 1

В лабораторной работе № 1 выполнена **инвентаризация поверхности атаки** OWASP Juice Shop: архитектура (SPA Angular + Express/Node.js 20), единый контейнер, SQLite через Sequelize, публикация порта **3000**, перечень HTTP API (`/rest/user/login`, `/rest/products/search`, `/api/Users`, `/rest/basket/:id` и др.).

В настоящей работе тот же объект используется для процесса **управления уязвимостями компонентов (third-party)**: инвентаризация версий зависимостей и образа, **ручной** поиск публично известных уязвимостей в открытых источниках, оценка **применимости** к фактическому стенду, формирование реестра и учёт находок в **DefectDojo**.

**Что не выполнялось в рамках данной работы (и не требуется методичкой):** CI/CD на GitLab Runner, сканеры в пайплайне (Trivy, Semgrep и др.), развёртывание приложения на серверных ВМ курса, Dependency-Track.

---

### 3. DefectDojo

#### 3.1. Развёртывание

Развёртывание DefectDojo **не выполнялось** — использован готовый экземпляр на VM курса:


| Параметр       | Значение                                          |
| -------------- | ------------------------------------------------- |
| URL            | [http://10.0.0.20:8080](http://10.0.0.20:8080)    |
| Учётная запись | `admin`                                           |
| Пароль         | *(указать при сдаче по требованию преподавателя)* |


#### 3.2. Структура в DefectDojo


| Уровень             | Наименование                                                                          | Примечание                               |
| ------------------- | ------------------------------------------------------------------------------------- | ---------------------------------------- |
| **Product**         | OWASP Juice Shop                                                                      | Объект VM                                |
| **Engagement**      | Lab3                                                                                  | Период 7 дней; тип: Manual / Interactive |
| **Test**            | `Lab3 — ручной реестр CVE компонентов (Manual Code Review) (Generic Findings Import)` | Импорт `findings.json`, 19.05.2026       |
| **Метрики Product** | Findings: **7** (Critical: 1, High: 5, Medium: 1)                                     | После импорта                            |


**Подтверждение:** *(вставить скриншот: Engagement Lab3 → Test → Findings; опционально Product → Findings 7)*.

#### 3.3. Типовые замечания

- Требуется доступ к сети `10.0.0.0/24` (VPN/лабораторная сеть).
- Пайплайн GitLab и API DefectDojo для сдачи **не обязательны** (достаточно UI).

---

### 4. Сбор компонентов и методика ручного поиска

#### 4.1. Описание стенда


| Параметр                   | Значение                                                                                                         |
| -------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| ОС хоста                   | Windows 10/11                                                                                                    |
| Среда                      | Docker Desktop                                                                                                   |
| Образ                      | `bkimminich/juice-shop:latest`, digest `sha256:25fd268112350ae9e0ddc7878371f9f12f5b0b546c7bf934d6599aa8e724418f` |
| Команда запуска            | `docker run -d -p 127.0.0.1:3000:3000 --name juice-shop bkimminich/juice-shop`                                   |
| URL приложения             | [http://127.0.0.1:3000](http://127.0.0.1:3000)                                                                   |
| Отдельные сервисы БД/nginx | **Нет** (SQLite и Express в одном контейнере)                                                                    |


#### 4.2. Источники инвентаризации (≥ 4)


| №   | Источник                           | Что извлекалось                                                            |
| --- | ---------------------------------- | -------------------------------------------------------------------------- |
| 1   | `juice-shop/package.json`          | Версия приложения, прямые зависимости npm                                  |
| 2   | `juice-shop/Dockerfile`            | Node 20, этапы сборки, образ `gcr.io/distroless/nodejs20-debian11`         |
| 3   | `juice-shop/frontend/package.json` | Angular и зависимости клиента                                              |
| 4   | Отчёт / факты лаб. № 1             | Архитектура, API, модель экспозиции (localhost)                            |
| 5   | Запущенный контейнер               | `docker inspect`, `docker exec … /nodejs/bin/node` — точные версии пакетов |


**Важно (distroless-образ):** в `bkimminich/juice-shop` **нет** команды `node` в PATH. Используйте `**/nodejs/bin/node`** и полный путь `/juice-shop/node_modules/...`. Это не ошибка стенда.

**Команды для фиксации версий в контейнере:**

```powershell
docker pull bkimminich/juice-shop
docker rm -f juice-shop 2>$null
docker run -d -p 127.0.0.1:3000:3000 --name juice-shop bkimminich/juice-shop
docker inspect juice-shop --format "{{.Config.Image}}"
docker image inspect bkimminich/juice-shop --format "{{.Id}}"

docker exec juice-shop /nodejs/bin/node -e "const p=['express','sequelize','sqlite3','sanitize-html','jsonwebtoken','multer','helmet','body-parser','cookie-parser','cors']; p.forEach(n=>{try{console.log(n, require('/juice-shop/node_modules/'+n+'/package.json').version)}catch(e){console.log(n,'?')}})"

docker exec juice-shop /nodejs/bin/node -e "console.log('socket.io', require('/juice-shop/node_modules/socket.io/package.json').version); console.log('libxmljs2', require('/juice-shop/node_modules/libxmljs2/package.json').version)"
```

**Альтернатива (версии из исходников, если контейнер не запущен):**

```powershell
cd juice-shop
npm install --omit=dev
npm list express sequelize sqlite3 sanitize-html jsonwebtoken socket.io multer helmet --depth=0
```

Версии из `npm list` могут **отличаться** от образа Hub — для Таблицы 1 приоритет у `**docker exec`** на запущенном контейнере.

**Angular:**

```powershell
Select-String -Path "frontend\package.json" -Pattern "@angular/core"
```

#### 4.3. Методика ручного поиска CVE

Для каждого компонента из таблицы 1:

1. Зафиксировать **точную** версию (не диапазон из `^`).
2. Определить тип: npm-библиотека → **GHSA** / **OSV.dev** → **NVD**; Node.js → security releases + NVD; базовый образ → NVD/OSV (с осторожностью к minimal/distroless).
3. Записать CVE/GHSA, CVSS v3.1 (вектор), CWE при наличии.
4. Проверить **диапазон уязвимых версий** — попадает ли версия стенда.
5. Оценить **применимость**: функция, эндпоинт из лаб. № 1, сетевая экспозиция (loopback vs LAN).
6. По желанию: [EPSS](https://www.first.org/epss/), [CISA KEV](https://www.cisa.gov/known-exploited-vulnerabilities-catalog), **[БДУ ФСТЭК](https://bdu.fstec.ru/vul)** — поиск по номеру CVE: `https://bdu.fstec.ru/search/index?q=CVE-…` (если запись есть — идентификатор вида `BDU:YYYY-NNNNN`, карточка `https://bdu.fstec.ru/vul/YYYY-NNNNN`).

**Основные источники:** NVD, MITRE CVE, GHSA, OSV, БДУ ФСТЭК.

---

### 5. Таблица 1 — Компоненты для анализа

> Версии npm-пакетов сняты с запущенного контейнера `juice-shop` (`docker exec … /nodejs/bin/node`). Образ Juice Shop — distroless: команда `node` в PATH отсутствует.


| Компонент                     | Тип                     | Версия                                                                            | Источник версии                                                             | Где используется                                                           |
| ----------------------------- | ----------------------- | --------------------------------------------------------------------------------- | --------------------------------------------------------------------------- | -------------------------------------------------------------------------- |
| OWASP Juice Shop              | приложение              | 17.0.0                                                                            | `package.json`                                                              | продукт целиком                                                            |
| Node.js                       | рантайм                 | **v24.15.0** (факт в контейнере)                                                  | `docker exec juice-shop /nodejs/bin/node -e "console.log(process.version)"` | процесс сервера; в `Dockerfile` указан Node 20, образ Hub может отличаться |
| distroless nodejs20-debian11  | базовый образ           | nodejs20 (Debian 11)                                                              | `Dockerfile`, строка 31                                                     | финальный runtime-образ                                                    |
| Debian 11 (в образе)          | ОС (минимальная)        | 11                                                                                | label образа distroless                                                     | среда исполнения Node                                                      |
| express                       | библиотека              | 4.22.2                                                                            | `docker exec juice-shop /nodejs/bin/node`                                   | HTTP API, `server.ts`                                                      |
| sequelize                     | библиотека              | 6.37.8                                                                            | `docker exec juice-shop /nodejs/bin/node`                                   | ORM, доступ к SQLite                                                       |
| sqlite3                       | библиотека / драйвер БД | 5.1.7                                                                             | `docker exec juice-shop /nodejs/bin/node`                                   | файл БД внутри контейнера                                                  |
| sanitize-html                 | библиотека              | 1.4.2                                                                             | `docker exec juice-shop /nodejs/bin/node`                                   | очистка HTML в API                                                         |
| jsonwebtoken                  | библиотека              | 0.4.0                                                                             | `docker exec juice-shop /nodejs/bin/node`                                   | JWT после `/rest/user/login`                                               |
| socket.io                     | библиотека              | 3.1.2                                                                             | `docker exec` (полный путь к `node_modules/socket.io`)                      | realtime / чат                                                             |
| socket.io-parser (транзитив.) | библиотека              | 4.0.5                                                                             | `docker exec` → `node_modules/socket.io-parser`                             | разбор пакетов Socket.IO                                                   |
| send (транзитив. express)     | библиотека              | 0.19.2                                                                            | `docker exec` → `node_modules/send`                                         | раздача статики Express                                                    |
| libxmljs2                     | библиотека (XML)        | 0.37.0                                                                            | `docker exec juice-shop /nodejs/bin/node`                                   | разбор XML (в репозитории: `libxmljs ^1.0.11`)                             |
| multer                        | библиотека              | 1.4.5-lts.2                                                                       | `docker exec juice-shop /nodejs/bin/node`                                   | загрузка файлов                                                            |
| helmet                        | библиотека              | 4.6.0                                                                             | `docker exec juice-shop /nodejs/bin/node`                                   | HTTP security headers                                                      |
| request                       | библиотека              | 2.88.2 (declared)                                                                 | `package.json` ^2.88.2                                                      | в runtime-образе **не найден**; исходящие HTTP (deprecated)                |
| body-parser                   | библиотека              | 1.20.5                                                                            | `docker exec juice-shop /nodejs/bin/node`                                   | разбор тел запросов                                                        |
| cookie-parser                 | библиотека              | 1.4.7                                                                             | `docker exec juice-shop /nodejs/bin/node`                                   | cookies                                                                    |
| cors                          | библиотека              | 2.8.6                                                                             | `docker exec juice-shop /nodejs/bin/node`                                   | CORS                                                                       |
| Angular (@angular/core)       | фреймворк (frontend)    | 15.0.4                                                                            | `frontend/package.json`                                                     | SPA в браузере (статика в образе)                                          |
| bkimminich/juice-shop         | образ Docker            | latest; `sha256:25fd268112350ae9e0ddc7878371f9f12f5b0b546c7bf934d6599aa8e724418f` | `docker inspect juice-shop`, `docker image inspect`                         | развёртывание стенда `http://127.0.0.1:3000`                               |


---

### 6. Таблица 2 — Реестр уязвимостей компонентов

**Требования:** 10–15 записей; минимум 2–3 CVE за 2024–2025 г.; 3–5 High/Critical; разные классы компонентов; обоснованная **применимость** к стенду `http://127.0.0.1:3000`.

> Поиск выполнен в NVD, GHSA, OSV (май 2026). **БДУ ФСТЭК:** сверка по CVE в выгрузке БДУ (снимок [bdu-fstec-mirror](https://github.com/velvetway/bdu-fstec-mirror), 18.04.2026) и поиск `https://bdu.fstec.ru/search/index?q=CVE-…`. Ссылки — в [§ 6.1](#61-ссылки-на-источники-по-записям-реестра).


| ID  | Компонент         | Версия            | Идентификатор (CVE / бюллетень)          | **БДУ ФСТЭК**                                                             | Критичность (CVSS v3.1) | Условия применимости                                                                                                                                                                                     | Сценарий эксплуатации                                                                                                                                   | Рекомендация по устранению                                                                                 | Статус в стенде |
| --- | ----------------- | ----------------- | ---------------------------------------- | ------------------------------------------------------------------------- | ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- | --------------- |
| 1   | sanitize-html     | 1.4.2             | **CVE-2016-1000237**                     | не внесено; [поиск](https://bdu.fstec.ru/search/index?q=CVE-2016-1000237) | Medium **6.1**          | Версия **< 1.4.3** (стенд: 1.4.2); библиотека обрабатывает HTML в API                                                                                                                                    | Пользователь отправляет специально сформированную разметку в поле, проходящее через sanitize-html → обход фильтра → **XSS** в контексте SPA             | Обновить до **≥ 1.4.3** (лучше — актуальная ветка 2.x); на учебном стенде — bind `127.0.0.1`               | Не устранено    |
| 2   | jsonwebtoken      | 0.4.0             | **CVE-2015-9235**                        | не внесено; [поиск](https://bdu.fstec.ru/search/index?q=CVE-2015-9235)    | **Critical 9.8**        | Версия **< 4.2.2**; в Juice Shop JWT подписывается **RS256** (`lib/insecurity.ts`), проверка асимметричным ключом                                                                                        | Атакующий подменяет алгоритм на **HS*** и подписывает токен секретом/публичным ключом → **обход аутентификации** на `/rest/basket/*`, `/api/*` с Bearer | Обновить jsonwebtoken до **≥ 9.x**; явно задавать `algorithms: ['RS256']` в `jwt.verify`; ротировать ключи | Не устранено    |
| 3   | jsonwebtoken      | 0.4.0             | **CVE-2022-23540**                       | не внесено; [поиск](https://bdu.fstec.ru/search/index?q=CVE-2022-23540)   | High **7.6**            | Версия **≤ 8.5.1**; в коде `jwt.verify(token, publicKey)` **без** опции `algorithms` (`lib/insecurity.ts`, `routes/chatbot.ts`)                                                                          | При уязвимой конфигурации verify допускается алгоритм `**none`** → подделка JWT без валидной подписи                                                    | Обновить до **≥ 9.0.0**; в `jwt.verify` указать `algorithms: ['RS256']`                                    | Не устранено    |
| 4   | multer            | 1.4.5-lts.2       | **CVE-2025-47944** (GHSA-4pg4-qvpc-4q3h) | не внесено; [поиск](https://bdu.fstec.ru/search/index?q=CVE-2025-47944)   | High **7.5**            | Уязвимы версии **≥ 1.4.4-lts.1 и < 2.0.0**; multer используется для загрузки файлов                                                                                                                      | Злоумышленник отправляет **искажённый multipart** на эндпоинт загрузки → необработанное исключение → **DoS** (падение процесса Node)                    | Обновить multer до **2.0.0+**; лимиты размера тела; WAF/rate limit                                         | Не устранено    |
| 5   | socket.io-parser  | 4.0.5             | **CVE-2026-33151** (GHSA-677m-j7p3-52f9) | не внесено; [поиск](https://bdu.fstec.ru/search/index?q=CVE-2026-33151)   | High **7.5**            | Парсер **4.0.0–4.2.5** (стенд: **4.0.5**); socket.io **3.1.2** на порту 3000                                                                                                                             | Специальный пакет Socket.IO с множеством binary-вложений → буферизация → **исчерпание памяти** (DoS) на realtime-канале                                 | Обновить socket.io / socket.io-parser до **≥ 4.2.6** (или ветки 3.3.5+ по advisory)                        | Не устранено    |
| 6   | libxmljs2         | 0.37.0            | **CVE-2024-34393** (GHSA-mjr4-7xg5-pfvh) | не внесено; [поиск](https://bdu.fstec.ru/search/index?q=CVE-2024-34393)   | High **8.1**            | Все версии до патча; пакет **не поддерживается**; разбор XML в приложении                                                                                                                                | Загрузка/передача **специально сформированного XML** → type confusion при `attrs()` → DoS / утечка / RCE (условия в advisory)                           | Заменить библиотеку (например, `fast-xml-parser` с отключёнными опасными сущностями); валидация входа      | Не устранено    |
| 7   | libxmljs2         | 0.37.0            | **CVE-2024-34394**                       | не внесено; [поиск](https://bdu.fstec.ru/search/index?q=CVE-2024-34394)   | High **8.1**            | Аналогично ID 6; другой кодовый путь (`namespaces()` на узле)                                                                                                                                            | Эксплуатация через цепочку вызовов XML API при обработке пользовательского XML                                                                          | См. ID 6                                                                                                   | Не устранено    |
| 8   | sequelize         | 6.37.8            | **CVE-2026-30951** (GHSA-6457-6jrx-69cr) | **[BDU:2026-04971](https://bdu.fstec.ru/vul/2026-04971)**                 | High **7.5**            | **Неприменимо:** уязвимы версии **< 6.37.8**; на стенде установлена **6.37.8** (исправление в этой версии)                                                                                               | SQLi через `::` в ключах JSON where — **не воспроизводится** на текущей версии                                                                          | —                                                                                                          | Неприменимо     |
| 9   | send (транзитив.) | 0.19.2            | **CVE-2024-43799** (GHSA-m6fv-jmcg-4jfg) | не внесено; [поиск](https://bdu.fstec.ru/search/index?q=CVE-2024-43799)   | Medium **4.7**          | **Неприменимо:** уязвимы **< 0.19.0**; в контейнере **0.19.2** (патч применён)                                                                                                                           | XSS через `SendStream.redirect()` — не актуально для версии стенда                                                                                      | —                                                                                                          | Неприменимо     |
| 10  | sqlite3           | 5.1.7             | **CVE-2022-43441** (GHSA-jqv5-7xpx-qj74) | не внесено; [поиск](https://bdu.fstec.ru/search/index?q=CVE-2022-43441)   | High **8.1**            | **Неприменимо:** уязвимы **5.0.0–5.1.4**; стенд на **5.1.7** (≥ 5.1.5)                                                                                                                                   | RCE через Object coercion в binding — **не воспроизводится**                                                                                            | —                                                                                                          | Неприменимо     |
| 11  | nginx             | —                 | *(напр. CVE-2024-7347)*                  | —                                                                         | —                       | **Неприменимо:** отдельный **nginx не развёрнут**; HTTP обслуживает Express                                                                                                                              | —                                                                                                                                                       | —                                                                                                          | Неприменимо     |
| 12  | request           | 2.88.2 (declared) | —                                        | —                                                                         | —                       | **Неприменимо:** пакет **отсутствует** в runtime-образе (`docker exec` → модуль не найден)                                                                                                               | Исходящие HTTP из `package.json` не исполняются в контейнере Hub                                                                                        | Удалить из `package.json` при сборке своего образа                                                         | Неприменимо     |
| 13  | Node.js           | v24.15.0          | **CVE-2025-27209**                       | **[BDU:2025-09383](https://bdu.fstec.ru/vul/2025-09383)**                 | High **7.5**            | **Неприменимо (вероятно):** HashDoS в V8 для **24.x**; исправлено в [релизах безопасности июля 2025](https://nodejs.org/en/blog/vulnerability/july-2025-security-releases); **24.15.0** новее патч-ветки | Массовые коллизии хешей → DoS CPU — **не ожидается** на 24.15.0 после патча                                                                             | Держать Node на актуальном LTS/security-релизе при пересборке образа                                       | Неприменимо     |


> **Примечание по БДУ:** в официальной выгрузке на дату снимка (18.04.2026) из перечисленных CVE в БДУ найдены только **BDU:2026-04971** (CVE-2026-30951) и **BDU:2025-09383** (CVE-2025-27209). Для остальных CVE в БДУ записи нет — указана ссылка на поиск; при сдаче можно повторить запрос на [https://bdu.fstec.ru](https://bdu.fstec.ru) (из сети курса/VPN).

#### 6.1. Ссылки на источники (по записям реестра)


| ID  | NVD                                                                   | GHSA / advisory                                                                                           | БДУ ФСТЭК                                                     | Прочее                                                                                                                               |
| --- | --------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| 1   | [CVE-2016-1000237](https://nvd.nist.gov/vuln/detail/CVE-2016-1000237) | [Node Security #135](https://nodesecurity.io/advisories/135)                                              | [поиск](https://bdu.fstec.ru/search/index?q=CVE-2016-1000237) | [OSV](https://osv.dev/vulnerability/GHSA-5j98-qpf4-rmwp)                                                                             |
| 2   | [CVE-2015-9235](https://nvd.nist.gov/vuln/detail/CVE-2015-9235)       | [GHSA-c7hr-j4mj-j2w6](https://github.com/advisories/GHSA-c7hr-j4mj-j2w6)                                  | [поиск](https://bdu.fstec.ru/search/index?q=CVE-2015-9235)    | [Auth0 blog](https://auth0.com/blog/2015/03/31/critical-vulnerabilities-in-json-web-token-libraries/)                                |
| 3   | [CVE-2022-23540](https://nvd.nist.gov/vuln/detail/CVE-2022-23540)     | [GHSA-qwph-4952-7xr6](https://github.com/auth0/node-jsonwebtoken/security/advisories/GHSA-qwph-4952-7xr6) | [поиск](https://bdu.fstec.ru/search/index?q=CVE-2022-23540)   | Код: `juice-shop/lib/insecurity.ts`                                                                                                  |
| 4   | [CVE-2025-47944](https://nvd.nist.gov/vuln/detail/CVE-2025-47944)     | [GHSA-4pg4-qvpc-4q3h](https://github.com/expressjs/multer/security/advisories/GHSA-4pg4-qvpc-4q3h)        | [поиск](https://bdu.fstec.ru/search/index?q=CVE-2025-47944)   | [Issue #1176](https://github.com/expressjs/multer/issues/1176)                                                                       |
| 5   | [CVE-2026-33151](https://nvd.nist.gov/vuln/detail/CVE-2026-33151)     | [GHSA-677m-j7p3-52f9](https://github.com/socketio/socket.io/security/advisories/GHSA-677m-j7p3-52f9)      | [поиск](https://bdu.fstec.ru/search/index?q=CVE-2026-33151)   | [OSV](https://osv.dev/vulnerability/GHSA-677m-j7p3-52f9)                                                                             |
| 6   | [CVE-2024-34393](https://nvd.nist.gov/vuln/detail/CVE-2024-34393)     | [GHSA-mjr4-7xg5-pfvh](https://github.com/advisories/GHSA-mjr4-7xg5-pfvh)                                  | [поиск](https://bdu.fstec.ru/search/index?q=CVE-2024-34393)   | [JFrog research](https://research.jfrog.com/vulnerabilities/libxmljs2-attrs-type-confusion-rce-jfsa-2024-001034097/)                 |
| 7   | [CVE-2024-34394](https://nvd.nist.gov/vuln/detail/CVE-2024-34394)     | —                                                                                                         | [поиск](https://bdu.fstec.ru/search/index?q=CVE-2024-34394)   | [JFrog JFSA-2024-001034096](https://research.jfrog.com/vulnerabilities/libxmljs2-namespaces-type-confusion-rce-jfsa-2024-001034096/) |
| 8   | [CVE-2026-30951](https://nvd.nist.gov/vuln/detail/CVE-2026-30951)     | [GHSA-6457-6jrx-69cr](https://github.com/sequelize/sequelize/security/advisories/GHSA-6457-6jrx-69cr)     | [BDU:2026-04971](https://bdu.fstec.ru/vul/2026-04971)         | —                                                                                                                                    |
| 9   | [CVE-2024-43799](https://nvd.nist.gov/vuln/detail/CVE-2024-43799)     | [GHSA-m6fv-jmcg-4jfg](https://github.com/pillarjs/send/security/advisories/GHSA-m6fv-jmcg-4jfg)           | [поиск](https://bdu.fstec.ru/search/index?q=CVE-2024-43799)   | —                                                                                                                                    |
| 10  | [CVE-2022-43441](https://nvd.nist.gov/vuln/detail/CVE-2022-43441)     | [GHSA-jqv5-7xpx-qj74](https://github.com/TryGhost/node-sqlite3/security/advisories/GHSA-jqv5-7xpx-qj74)   | [поиск](https://bdu.fstec.ru/search/index?q=CVE-2022-43441)   | —                                                                                                                                    |
| 13  | [CVE-2025-27209](https://nvd.nist.gov/vuln/detail/CVE-2025-27209)     | —                                                                                                         | [BDU:2025-09383](https://bdu.fstec.ru/vul/2025-09383)         | [Node.js July 2025](https://nodejs.org/en/blog/vulnerability/july-2025-security-releases)                                            |


---

### 7. Выводы

#### 7.1. Топ-3 наиболее критичных уязвимостей для данного стенда

1. **ID 2 — CVE-2015-9235 (jsonwebtoken 0.4.0)** — **Critical 9.8**; JWT — основа авторизации после `/rest/user/login`; используется RS256, что попадает под сценарий algorithm confusion; при публикации порта на LAN (`-p 3000:3000`) атака доступна удалённо.
2. **ID 3 — CVE-2022-23540 (jsonwebtoken 0.4.0)** — **High 7.6**; подтверждено отсутствие `algorithms` в `jwt.verify` в коде приложения; прямой путь к обходу проверки подписи на защищённых маршрутах.
3. **ID 6 — CVE-2024-34393 (libxmljs2 0.37.0)** — **High 8.1**; нет исправленной версии пакета; при обработке пользовательского XML возможны DoS и (в ограниченных условиях) RCE.

#### 7.2. «Чистые» и «грязные» компоненты


| Категория             | Компоненты                                                                                                                                                                                                                                                                                              |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Относительно «чистые» | **sequelize** 6.37.8 (CVE-2026-30951 неприменим), **sqlite3** 5.1.7, **send** 0.19.2, **express** 4.22.2 + **path-to-regexp** 0.1.13, **helmet** 4.6.0 (прямых CVE для версии не найдено), **nginx** / **request** (не в стенде), **Node.js** v24.15.0 (актуальные CVE 2025, вероятно, закрыты патчами) |
| «Грязные»             | **jsonwebtoken** 0.4.0 (2 критичных/высоких CVE), **sanitize-html** 1.4.2, **multer** 1.4.5-lts.2, **socket.io-parser** 4.0.5, **libxmljs2** 0.37.0 (2 CVE 2024, патча нет)                                                                                                                             |


#### 7.3. Приоритеты устранения


| Приоритет                      | Действие                                                                                      | Компоненты / CVE                                 |
| ------------------------------ | --------------------------------------------------------------------------------------------- | ------------------------------------------------ |
| Срочно                         | Обновить **jsonwebtoken**; явно задать `algorithms` в verify; ротировать ключи                | CVE-2015-9235, CVE-2022-23540                    |
| Срочно                         | Заменить или изолировать **libxmljs2**; запретить опасный XML                                 | CVE-2024-34393, CVE-2024-34394                   |
| Планово                        | Обновить **multer** → 2.x, **socket.io** / parser, **sanitize-html**                          | CVE-2025-47944, CVE-2026-33151, CVE-2016-1000237 |
| Компенсирующие меры            | `-p 127.0.0.1:3000:3000`, firewall, rate limiting на upload и WebSocket                       | Все применимые ID                                |
| Принятие риска (учебный стенд) | Оставить уязвимости для демонстрации OWASP-заданий **только** при изоляции от production-сети | Juice Shop по назначению — уязвимое приложение   |


---

### 8. Внесение результатов в DefectDojo (дополнительное задание)

**Способ:** □ ручной ввод UI  ☑ **импорт Generic Findings Import JSON** — файл `[findings.json](findings.json)` (7 находок: 1 Critical, 5 High, 1 Medium)

**Соответствие полей:**


| Поле DefectDojo | Содержание из реестра                                          |
| --------------- | -------------------------------------------------------------- |
| Title           | CVE + краткое имя компонента                                   |
| Severity        | Critical / High / Medium / Low                                 |
| CVE             | Идентификатор                                                  |
| CVSSv3          | Векторная строка                                               |
| Description     | Уязвимость + место в Juice Shop + версия                       |
| Mitigation      | Колонка «Рекомендация»                                         |
| Impact          | Последствия для стенда (RCE, обход auth, утечка данных SQLite) |
| References      | NVD, GHSA, БДУ ФСТЭК (`https://bdu.fstec.ru/vul/…`)            |


**Подтверждение:** *(скриншот Findings с фильтром по severity)*.

#### Импорт `findings.json`

Полный файл в корне репозитория: `**findings.json`** (только **применимые** записи из таблицы 2, статус «Не устранено»). Фрагмент для отчёта — [Приложение В](#приложение-в-фрагмент-файла-findingsjson-generic-findings-import).


| Severity | Кол-во | CVE                                                                            |
| -------- | ------ | ------------------------------------------------------------------------------ |
| Critical | 1      | CVE-2015-9235                                                                  |
| High     | 5      | CVE-2022-23540, CVE-2024-34393, CVE-2024-34394, CVE-2025-47944, CVE-2026-33151 |
| Medium   | 1      | CVE-2016-1000237                                                               |


**Выполнено:** 19.05.2026, Engagement **Lab3** → **Add Tests** (или Import Scan Results): Scan type **Generic Findings Import**, файл `findings.json`, Active/Verified — Force to True. Результат: **7 findings** (Critical 1, High 5, Medium 1), статус Active/Verified, теги `lab3`, `juice-shop`, `component-vm`.

**Шаги (для повторения):**

1. [http://10.0.0.20:8080](http://10.0.0.20:8080) → Product **OWASP Juice Shop** → Engagement **Lab3**.
2. **Add Tests** / **Import Scan Results** → Scan type: **Generic Findings Import**.
3. Загрузить `findings.json` → Submit.
4. Скриншот: Test → **Findings (7)**; опционально Product → **Findings 7**.

> Записи со статусом «Неприменимо» в JSON **не включены** (можно добавить отдельно с `false_p: true`, если преподаватель требует полный реестр).

---

### 9. Ответы на контрольные вопросы

> Краткие ответы (1–2 абзаца на вопрос). Номера соответствуют методичке.

**1. CVE, CWE, CVSS, CPE — отличия и примеры**

**CVE** (Common Vulnerabilities and Exposures) — уникальный идентификатор конкретной уязвимости, например **CVE-2015-9235** (jsonwebtoken). **CWE** (Common Weakness Enumeration) — класс ошибки в дизайне/коде, например **CWE-327** (слабая криптография) для algorithm confusion в JWT. **CVSS** — числовая оценка серьёзности (вектор + score), например **9.8 Critical** для CVE-2015-9235. **CPE** (Common Platform Enumeration) — формат имени продукта/версии для привязки CVE к ПО в NVD (`cpe:2.3:a:auth0:jsonwebtoken:*:*:*:*:*:node.js:*:*`).

**2. Почему CVSS alone — плохой критерий приоритизации?**

CVSS описывает **теоретную** тяжесть уязвимости в «среднем» сценарии, но не учитывает: эксплуатируется ли уязвимость в дикой природе (**EPSS**, **CISA KEV**), доступен ли стенд из интернета, используется ли уязвимая функция в коде, ценность актива (учебный Juice Shop на `127.0.0.1` vs production). Например, **CVE-2026-30951** (sequelize, High 7.5) имеет высокий CVSS, но на стенде **неприменима** — версия 6.37.8 уже содержит исправление; приоритет ниже, чем у **CVE-2015-9235** (Critical), которая реально бьёт по JWT в `/rest/user/login`.

**3. EPSS**

**EPSS** (Exploit Prediction Scoring System) — вероятность эксплуатации уязвимости в ближайшие 30 дней на основе данных об атаках. Дополняет CVSS: высокий CVSS + низкий EPSS может означать «опасно, но пока не бьют»; низкий CVSS + высокий EPSS — повод поднять приоритет. В DefectDojo для импортированных findings EPSS отображается как N.A., если не подгружался отдельно; для приоритизации Juice Shop разумно смотреть EPSS вместе с KEV для CVE в стеке auth (jsonwebtoken).

**4. Как проверить применимость CVE к стенду?**

Последовательность: (1) зафиксировать **точную версию** компонента (`docker exec` → jsonwebtoken **0.4.0**); (2) в NVD/GHSA проверить **диапазон уязвимых версий**; (3) проверить **использование в коде** — JWT и `jwt.verify` в `lib/insecurity.ts`; (4) учесть **сеть** — стенд `http://127.0.0.1:3000` снижает удалённую экспозицию; (5) записать статус. Пример: **CVE-2022-23540** — версия 0.4.0 ≤ 8.5.1, `jwt.verify` без `algorithms` → **применимо**; **CVE-2022-43441** (sqlite3) — стенд на 5.1.7, патч в 5.1.5 → **неприменимо**.

**5. NVD vs БДУ vs GHSA**

**NVD** (США, NIST) — эталонный каталог CVE, CVSS, CPE; предпочтителен для официальной ссылки на CVE. **GHSA** / **OSV** — удобны для **npm**-пакетов (быстрый поиск по имени библиотеки). **БДУ ФСТЭК** — российский банк угроз; обязателен для отчётности в РФ, идентификатор **BDU:YYYY-NNNNN** (в работе найдены BDU:2026-04971, BDU:2025-09383). Для Juice Shop сначала GHSA/OSV → CVE → NVD; БДУ — для сверки и compliance.

**6. Транзитивная зависимость**

Транзитивная зависимость — библиотека, подтянутая **не напрямую**, а через другой пакет. В стенде **socket.io-parser 4.0.5** не указан в `package.json`, но присутствует через **socket.io 3.1.2**; уязвимость **CVE-2026-33151** относится к парсеру. Такие зависимости часто пропускают при ручном анализе только `package.json` — нужен `docker exec`, `npm list` или SBOM.

**7. Уязвимость в приложении vs в базовом образе**

Уязвимость **приложения** — в npm-коде или зависимостях приложения (jsonwebtoken, multer в `/juice-shop/node_modules`). Уязвимость **базового образа** — в ОС или runtime-слое контейнера (Debian в distroless, Node.js **v24.15.0**). Пример: **CVE-2015-9235** — уровень приложения; **CVE-2025-27209** — уровень Node/V8. Устранение разное: `npm update` vs пересборка образа на новом Node.

**8. Статус, если версия уязвима, но функция не используется**

Статус: **Неприменимо** (или **Not Applicable** в реестре), с обоснованием в колонке «Условия применимости». Это не то же самое, что **False Positive** (ошибка сканера): версия формально уязвима, но кодовый путь/компонент отсутствует. Примеры из реестра: **nginx** (не развёрнут), **request** (нет в runtime-образе), **sequelize CVE-2026-30951** (версия уже с патчем). **Risk Accepted** — осознанное принятие риска при эксплуатации функции; для учебного Juice Shop на localhost допустимо с оговоркой.

**9. Компенсирующая мера — пример из реестра**

Компенсирующая мера — контроль, **снижающий риск без патча**. Пример: публикация контейнера только на loopback `**docker run -p 127.0.0.1:3000:3000`** — удалённый атакующий из LAN не достучится до CVE в jsonwebtoken/multer; rate limiting на upload и WebSocket снижает DoS по **CVE-2025-47944** и **CVE-2026-33151**.

**10. Зачем DefectDojo при наличии отчётов сканеров?**

Сканеры (Trivy, SAST) дают **сырой поток** находок; DefectDojo — **система учёта**: единый реестр по продуктам/релизам, статусы (Active, Mitigated, False Positive), SLA, дедупликация, история импортов, связь с engagement/test. Для лабы №3 ручной реестр CVE загружен через **Generic Findings Import** — те же поля, что при автоматическом SCA, но с обоснованной применимостью к Juice Shop.

**11. Дедупликация в DefectDojo**

При повторном импорте DefectDojo сопоставляет findings по **title, severity, component** (и настройкам reimport), чтобы не плодить дубликаты. Важно для CI/CD: каждый pipeline не создаёт сотни копий одного CVE. При повторной загрузке `findings.json` с теми же CVE старые записи могут быть помечены mitigated или обновлены — зависит от флагов **Close old findings** (в работе не включался).

**12. CISA KEV**

**KEV** (Known Exploited Vulnerabilities) — каталог CISA с уязвимостями, **реально эксплуатируемыми** в атаках; федеральные органы США обязаны устранять в сжатые сроки. Для приоритизации: CVE из KEV поднимаются выше равных по CVSS. Для Juice Shop npm-CVE из реестра в KEV, как правило, нет — но проверка KEV — обязательный шаг зрелого VM.

**13. CVSS v3.1 vs v4.0**

**CVSS v3.1** — широко используемая шкала (AV, AC, PR, UI, S, C, I, A); в NVD для jsonwebtoken указан **9.8 v3.0/v3.1**. **CVSS v4.0** уточняет контекст (атака по цепочке поставок, пользовательские атрибуты); оценки могут **отличаться** на 0.5–1.5 балла для той же CVE. В реестре использован v3.1 из NVD/GHSA; v4.0 для libxmljs2 в некоторых источниках выше (до 9.2) — нужно явно указывать версию шкалы в отчёте.

**14. SBOM**

**SBOM** (Software Bill of Materials) — машиночитаемый перечень компонентов и версий (SPDX/CycloneDX). Связь с VM: по SBOM автоматически сопоставляют CVE (SCA). В upstream Juice Shop в `Dockerfile` есть этап `**npm run sbom`** для генерации SBOM при сборке. Ручная Таблица 1 в лабе — упрощённый аналог SBOM; полный SBOM покрыл бы и транзитивные пакеты (socket.io-parser, send) без отдельного `docker exec`.

**15. Процесс VM из 5 этапов**

По методичке (NIST SSDF / курс DevSecOps): **(1) Инвентаризация** — Таблица 1, `package.json`, `docker exec` (компоненты Juice Shop). **(2) Выявление** — ручной поиск CVE в NVD/GHSA/БДУ, Таблица 2. **(3) Приоритизация** — CVSS + применимость + контекст стенда, §7.3 (срочно jsonwebtoken, libxmljs2). **(4) Устранение** — патч/обновление/компенсация (в учебном стенде уязвимости намеренно не закрывались). **(5) Контроль** — учёт в DefectDojo (7 findings), повторная инвентаризация при смене образа, SLA (Critical 7 дней в настройках Product).

---

### 10. Список источников

1. DefectDojo — репозиторий: [https://github.com/DefectDojo/django-DefectDojo](https://github.com/DefectDojo/django-DefectDojo)
2. Документация DefectDojo: [https://docs.defectdojo.com/](https://docs.defectdojo.com/)
3. National Vulnerability Database: [https://nvd.nist.gov/](https://nvd.nist.gov/)
4. MITRE CVE: [https://www.cve.org/](https://www.cve.org/)
5. БДУ ФСТЭК России: [https://bdu.fstec.ru/](https://bdu.fstec.ru/)
6. GitHub Security Advisories: [https://github.com/advisories](https://github.com/advisories)
7. OSV.dev: [https://osv.dev/](https://osv.dev/)
8. Open Source Insights (deps.dev): [https://deps.dev/](https://deps.dev/)
9. CISA Known Exploited Vulnerabilities: [https://www.cisa.gov/known-exploited-vulnerabilities-catalog](https://www.cisa.gov/known-exploited-vulnerabilities-catalog)
10. EPSS: [https://www.first.org/epss/](https://www.first.org/epss/)
11. CVSS v3.1: [https://www.first.org/cvss/v3-1/specification-document](https://www.first.org/cvss/v3-1/specification-document)
12. NIST SP 800-218 (SSDF): [https://csrc.nist.gov/pubs/sp/800/218/final](https://csrc.nist.gov/pubs/sp/800/218/final)
13. OWASP Juice Shop (upstream): [https://github.com/juice-shop/juice-shop](https://github.com/juice-shop/juice-shop)
14. Методические материалы курса: `Лаба №3. Управление и поиск уязвимостей в используемых компонентах.md`
15. Отчёт лаб. № 1: `lab_report_1.md`

---

### Приложение А. Чеклист перед сдачей

- Таблица 1: ≥ 15 компонентов, **точные** версии, ≥ 4 источника
- Таблица 2: **13** записей, применимость и сценарии заполнены, колонка БДУ ФСТЭК
- Минимум 2–3 CVE 2024–2025 (CVE-2024-34393/94, CVE-2025-47944, CVE-2026-33151)
- Минимум 3–5 High/Critical (1 Critical + 5 High применимых)
- Есть записи со статусом **Неприменимо** с обоснованием (ID 8–13)
- Выводы: топ-3, чистые/грязные, приоритеты
- DefectDojo: Product, Engagement Lab3, Test, импорт 7 findings
- Связь с лаб. № 1 в §2; GitLab курса указан в шапке
- **Скриншоты** вставить в §3.2 и §8 *(единственное, что остаётся сделать вручную)*

### Приложение Б. Быстрые ссылки на поиск


| Компонент         | GHSA/OSV                                                                                                                              | NVD                                                                                                                                |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| sanitize-html     | [https://github.com/advisories?query=sanitize-html](https://github.com/advisories?query=sanitize-html)                                | [https://nvd.nist.gov/vuln/search](https://nvd.nist.gov/vuln/search)                                                               |
| jsonwebtoken      | [OSV](https://osv.dev/list?ecosystem=npm&name=jsonwebtoken), [GHSA-c7hr-j4mj-j2w6](https://github.com/advisories/GHSA-c7hr-j4mj-j2w6) | [CVE-2015-9235](https://nvd.nist.gov/vuln/detail/CVE-2015-9235), [CVE-2022-23540](https://nvd.nist.gov/vuln/detail/CVE-2022-23540) |
| multer            | [GHSA-4pg4-qvpc-4q3h](https://github.com/expressjs/multer/security/advisories/GHSA-4pg4-qvpc-4q3h)                                    | [CVE-2025-47944](https://nvd.nist.gov/vuln/detail/CVE-2025-47944)                                                                  |
| libxmljs2         | [OSV](https://osv.dev/list?q=libxmljs2)                                                                                               | [CVE-2024-34393](https://nvd.nist.gov/vuln/detail/CVE-2024-34393)                                                                  |
| Node.js (runtime) | [https://nodejs.org/en/blog/vulnerability](https://nodejs.org/en/blog/vulnerability)                                                  | [https://nvd.nist.gov/vuln/search](https://nvd.nist.gov/vuln/search)                                                               |


### Приложение В. Фрагмент файла `findings.json` (Generic Findings Import)

Полный файл для импорта в DefectDojo: `[findings.json](findings.json)` (7 записей, формат DefectDojo Generic Findings Import). Ниже — структура файла, **первая запись целиком** (Critical) и **сводка остальных** записей (в файле для каждой — те же поля).

**Перечень всех findings в файле:**


| №   | severity | cve              | component_name   | component_version |
| --- | -------- | ---------------- | ---------------- | ----------------- |
| 1   | Critical | CVE-2015-9235    | jsonwebtoken     | 0.4.0             |
| 2   | High     | CVE-2022-23540   | jsonwebtoken     | 0.4.0             |
| 3   | High     | CVE-2024-34393   | libxmljs2        | 0.37.0            |
| 4   | High     | CVE-2024-34394   | libxmljs2        | 0.37.0            |
| 5   | High     | CVE-2025-47944   | multer           | 1.4.5-lts.2       |
| 6   | High     | CVE-2026-33151   | socket.io-parser | 4.0.5             |
| 7   | Medium   | CVE-2016-1000237 | sanitize-html    | 1.4.2             |


**Фрагмент JSON (запись № 1 — CVE-2015-9235):**

```json
{
  "findings": [
    {
      "title": "CVE-2015-9235: jsonwebtoken algorithm confusion (RS256/HS)",
      "date": "2026-05-19",
      "cve": "CVE-2015-9235",
      "cwe": 327,
      "cvssv3": "CVSS:3.0/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H",
      "severity": "Critical",
      "description": "OWASP Juice Shop 17.0.0, стенд http://127.0.0.1:3000 (Docker bkimminich/juice-shop). Компонент: jsonwebtoken 0.4.0. JWT выдаётся при POST /rest/user/login (RS256, lib/insecurity.ts). Версия < 4.2.2 — обход проверки подписи при подмене алгоритма на HS*.",
      "mitigation": "Обновить jsonwebtoken до >= 9.x; в jwt.verify явно указать algorithms: ['RS256']; ротировать ключи в encryptionkeys/.",
      "impact": "Обход аутентификации: доступ к /rest/basket/*, /api/* от имени другого пользователя; компрометация сессий при экспозиции порта 3000.",
      "references": "https://nvd.nist.gov/vuln/detail/CVE-2015-9235, https://github.com/advisories/GHSA-c7hr-j4mj-j2w6, https://bdu.fstec.ru/search/index?q=CVE-2015-9235",
      "active": true,
      "verified": true,
      "false_p": false,
      "component_name": "jsonwebtoken",
      "component_version": "0.4.0",
      "tags": ["lab3", "juice-shop", "component-vm"]
    }
  ]
}
```

**Фрагмент JSON (запись № 7 — CVE-2016-1000237, Medium):**

```json
    {
      "title": "CVE-2016-1000237: sanitize-html XSS",
      "date": "2026-05-19",
      "cve": "CVE-2016-1000237",
      "cwe": 79,
      "cvssv3": "CVSS:3.1/AV:N/AC:L/PR:N/UI:R/S:C/C:L/I:L/A:N",
      "severity": "Medium",
      "description": "Juice Shop 17.0.0, 127.0.0.1:3000. sanitize-html 1.4.2 (< 1.4.3). Очистка HTML в API — обход фильтра, XSS в контексте Angular SPA.",
      "mitigation": "Обновить sanitize-html до >= 1.4.3 (рекомендуется актуальная 2.x); bind 127.0.0.1 на учебном стенде.",
      "impact": "XSS: компрометация сессии пользователя, выполнение скрипта в браузере жертвы.",
      "references": "https://nvd.nist.gov/vuln/detail/CVE-2016-1000237, https://nodesecurity.io/advisories/135, https://bdu.fstec.ru/search/index?q=CVE-2016-1000237",
      "active": true,
      "verified": true,
      "false_p": false,
      "component_name": "sanitize-html",
      "component_version": "1.4.2",
      "tags": ["lab3", "juice-shop", "component-vm"]
    }
```

> Записи № 2–6 в полном файле `findings.json` оформлены аналогично (поля `title`, `date`, `cve`, `cwe`, `cvssv3`, `severity`, `description`, `mitigation`, `impact`, `references`, `active`, `verified`, `false_p`, `component_name`, `component_version`, `tags`).

---

*Отчёт подготовлен: Трюх Е.А., группа М09КИИ-25, 19.05.2026. Перед сдачей: вставить скриншоты DefectDojo в §3.2 и §8; при наличии — уточнить URL личного проекта на GitLab курса.*