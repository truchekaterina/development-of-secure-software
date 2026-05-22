# Dependency-Track — исправить `sbom-upload-dt` HTTP 401

Job **Lab 4** (не Lab 6). После pipeline #55+ при неверном ключе job завершается **exit 0** с WARN (pipeline не «ломается» из‑за DT).

## Быстрое исправление

1. Открой **Dependency-Track:** http://10.0.0.30:8081  
2. Войди под своей учёткой курса.  
3. **Administration → Access Management → Teams** (или **API Keys**).  
4. Создай **API Key** с правами на проект Juice Shop (или возьми ключ у преподавателя).  
5. GitLab → http://10.0.0.10/root/juice-shop-lab → **Settings → CI/CD → Variables**  
6. Обнови:
   - `DEPENDENCYTRACK_API_KEY` — новый ключ (**Masked**, **Protected**)
   - `DEPENDENCYTRACK_PROJECT_UUID` — UUID проекта в DT (вкладка проекта → About / API)  
7. **Retry** job `sbom-upload-dt` или Run pipeline.

## Проверка UUID

В DT открой проект **OWASP Juice Shop** (или ваш) → скопируй **UUID** (формат `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`).

Не путать с:
- `DEFECTDOJO_*` — другой сервер (10.0.0.20)
- опечаткой `DEPECTDOJO_TRACK_PROJECT_UUID` в Variables

## Полностью отключить job (не нужен для Lab 6)

GitLab Variables → `SKIP_SBOM_DT` = `true` → job не запускается.
