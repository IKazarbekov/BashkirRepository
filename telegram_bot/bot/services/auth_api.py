import os
import hashlib
import httpx

API_URL = os.getenv("API_URL", "http://10.136.202.1:8000")
ACCOUNTS_URL = os.getenv("ACCOUNTS_API_URL", "http://127.0.0.1:8000")


def _parse(r: httpx.Response):
    """Ответ как объект, если это JSON, иначе как строка."""
    try:
        return r.json()
    except ValueError:
        return r.text


async def _post(path: str, params: dict):
    try:
        async with httpx.AsyncClient(base_url=API_URL, timeout=10) as client:
            return await client.post(path, params=params)
    except httpx.ConnectError:
        return "Сервер недоступен (возможно, выключен бэкенд или другая сеть)"
    except httpx.TimeoutException:
        return "Сервер не ответил вовремя"

async def _accounts_post(path: str, body: dict):
    """Запрос к главному бэкенду (аккаунты приложения)."""
    try:
        async with httpx.AsyncClient(base_url=ACCOUNTS_URL, timeout=10) as client:
            return await client.post(path, json=body)
    except httpx.ConnectError:
        return "Сервер аккаунтов недоступен (запущен ли start_server.bat?)"
    except httpx.TimeoutException:
        return "Сервер аккаунтов не ответил вовремя"


def _error_text(r: httpx.Response) -> str:
    data = _parse(r)
    if isinstance(data, dict):
        for key in ("detail", "message", "error"):
            value = data.get(key)
            if isinstance(value, str):
                return value
    return f"код {r.status_code}"


async def _sync_tasks_account(username: str, password: str, telegram_id: int) -> tuple[bool, str]:
    """Находит или создаёт такого же пользователя в базе заданий (бэкенд друга)."""
    params = {"login": username, "password": password}
    r = await _post("/user/log", params)
    if not isinstance(r, str) and r.status_code == 401:
        email = "u" + hashlib.md5(username.encode()).hexdigest()[:12] + "@tg.local"
        await _post("/user/reg", {**params, "email": email})
        r = await _post("/user/log", params)
    if isinstance(r, str):
        return False, r
    if r.status_code != 200:
        return False, "Аккаунт есть в приложении, но не удалось войти в базу заданий. Попробуй ещё раз."
    return True, ""

def extract_user_id(data) -> int | None:
    """Пытается достать числовой id пользователя из ответа /user/log."""
    if isinstance(data, int):
        return data
    if isinstance(data, str) and data.isdigit():
        return int(data)
    if isinstance(data, dict):
        for key in ("user_id", "id"):
            if isinstance(data.get(key), int):
                return data[key]
    return None


async def find_user_id(username: str) -> int | None:
    """Запасной вариант: ищем id в списке пользователей (/user/getall)."""
    try:
        async with httpx.AsyncClient(base_url=API_URL, timeout=10) as client:
            r = await client.get("/user/getall")
    except httpx.HTTPError:
        return None

    print("GETALL:", r.status_code, r.text[:300])  # временно, для отладки

    if r.status_code != 200:
        return None
    data = _parse(r)
    if isinstance(data, list):
        for u in data:
            if isinstance(u, dict) and username in (u.get("login"), u.get("username")):
                uid = u.get("id") or u.get("user_id")
                if isinstance(uid, int):
                    return uid
    return None


async def register(username: str, password: str, email: str, telegram_id: int) -> tuple[bool, str]:
    r = await _accounts_post("/register", {"login": username, "password": password})
    if isinstance(r, str):
        return False, r
    print("REGISTER:", r.status_code)
    if not r.is_success:
        return False, f"Не удалось зарегистрироваться: {_error_text(r)}"
    await _sync_tasks_account(username, password, telegram_id)
    return True, "ok"


async def login(username: str, password: str, telegram_id: int):
    r = await _accounts_post("/login", {"login": username, "password": password, "remember": False})
    if isinstance(r, str):
        return False, r
    print("LOGIN:", r.status_code)
    if not r.is_success:
        return False, f"Не удалось войти: {_error_text(r)}"

    ok, info = await _sync_tasks_account(username, password, telegram_id)
    if not ok:
        return False, info

    data = _parse(r)
    token = data.get("token") if isinstance(data, dict) else None
    return True, {"token": token}