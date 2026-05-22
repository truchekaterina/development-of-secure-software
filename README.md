# Разработка защищённого ПО — портфолио курса

**Студент:** Трюх Екатерина Александровна · **Группа:** М09КИИ-25  
**Практика:** OWASP Juice Shop 17.0.0 (`juice-shop/`)

## Для рекрутера и интервьюера

**[COURSE_SUMMARY.md](COURSE_SUMMARY.md)** — полная пошаговая сводка курса: лабы 1, 3–7, матрица навыков, DevSecOps pipeline, метрики и ссылки на отчёты.

## Структура репозитория

| Папка / файл | Содержание |
|--------------|------------|
| [COURSE_SUMMARY.md](COURSE_SUMMARY.md) | Сводка навыков и результатов |
| [Done/reports/lab_report_1.md](Done/reports/lab_report_1.md) | Лаба 1 — attack surface |
| [Done/reports/lab_report_3.md](Done/reports/lab_report_3.md) | Лаба 3 — ручной CVE |
| [Done/reports/lab_report_4.md](Done/reports/lab_report_4.md) | Лаба 4 — SCA / SBOM |
| [Done/reports/lab_report_5.md](Done/reports/lab_report_5.md) | Лаба 5 — SAST / Semgrep |
| [Done/reports/lab_report_6.md](Done/reports/lab_report_6.md) | Лаба 6 — DAST / ZAP |
| [Done/reports/lab_report_7.md](Done/reports/lab_report_7.md) | Лаба 7 — Gitleaks, secret gate |
| [juice-shop/](juice-shop/) | Код, `.gitlab-ci.yml`, конфиги сканеров |

## Git

| Репозиторий | Путь | Назначение |
|-------------|------|------------|
| **Корень** | `Development_of_secure_software/` | Портфолио: отчёты, `COURSE_SUMMARY.md`, копия `juice-shop/` |
| **Juice Shop** | `juice-shop/` | Отдельный git → push CI/кода на GitLab |

В `.gitignore` корня: только `Done/how_to_do/`, `.cursor/`, `.env`.

## GitLab

- **Juice Shop (CI, код):** https://gitlab.com/Agent_Kate/juice-shop-lab  
- **Курс (архив):** http://10.0.0.10/root/juice-shop-lab
