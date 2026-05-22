# Перенос `juice-shop-lab` на ваш GitLab

**Статус:** перенос на https://gitlab.com/Agent_Kate/juice-shop-lab выполнен (22.05.2026).

## Текущее состояние (уже сделано)

- Восстановлена папка **`juice-shop/.git`** с курсового GitLab.
- Remote курса: **`course`** → `http://10.0.0.10/root/juice-shop-lab.git`
- Ветки: **`main`**, **`lab7-demo-gate`** (на сервере курса).
- Локальный коммит поверх курса: `dc63df64d` (несинхронизированные правки лаб).
- Корневой `.git` у папки `Development_of_secure_software` **удалён** (чтобы не мешал `juice-shop`).

## Шаг 1 — создайте пустой проект на вашем GitLab

1. New project → **Create blank project**
2. Имя, например: `juice-shop-lab`
3. **Без** README / .gitignore / license (репозиторий должен быть пустым)
4. Скопируйте **HTTPS** URL клонирования, например:  
   `https://gitlab.YOUR-DOMAIN.com/your-group/juice-shop-lab.git`

## Шаг 2 — добавьте remote и отправьте всё

В PowerShell:

```powershell
cd "c:\Users\1\Desktop\neurohelp\Development_of_secure_software\juice-shop"

# ваш новый GitLab (подставьте URL)
git remote add origin https://gitlab.YOUR-DOMAIN.com/your-group/juice-shop-lab.git

# все ветки и теги
git push -u origin main
git push origin lab7-demo-gate

# если на курсе были теги:
git push origin --tags
```

При запросе логина используйте **Personal Access Token** (scope: `write_repository`), не пароль.

## Шаг 3 — (опционально) полное зеркало одной командой

Если нужны **все** refs как на курсе + ваш новый коммит:

```powershell
git push --mirror https://gitlab.YOUR-DOMAIN.com/your-group/juice-shop-lab.git
```

После `--mirror` на `origin` лучше снова:

```powershell
git remote set-url origin https://gitlab.YOUR-DOMAIN.com/your-group/juice-shop-lab.git
git push -u origin main
```

## Remotes после переноса (рекомендация)

| Имя | Назначение |
|-----|------------|
| `origin` | **ваш** GitLab |
| `course` | курсовый `10.0.0.10` (архив) |
| `upstream` | при необходимости: `https://github.com/juice-shop/juice-shop.git` |

```powershell
git remote add upstream https://github.com/juice-shop/juice-shop.git
```

## CI/CD на новом GitLab

Перенесётся файл `.gitlab-ci.yml`, но **раннеры, registry `10.0.0.11:5000`, DefectDojo, Dependency-Track** останутся в сети курса — на своём GitLab pipeline будут падать, пока не настроите свои Variables и runner (или отключите лишние jobs).

## Remotes сейчас

| Имя | URL |
|-----|-----|
| **origin** | https://gitlab.com/Agent_Kate/juice-shop-lab.git |
| **course** | http://10.0.0.10/root/juice-shop-lab.git (архив курса) |

Ветки на **origin**: `main` (полная история лаб), `lab7-demo-gate`.
