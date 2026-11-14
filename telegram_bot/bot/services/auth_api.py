import os

import httpx

API_URL = os.getenv("API_URL", "http://10.136.202.1:8000")


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
    r = await _post("/user/reg", {"login": username, "password": password, "email": email})
    if isinstance(r, str):
        return False, r

    print("REGISTER:", r.status_code, r.text)  # временно, для отладки

    if r.status_code == 200:
        return True, str(_parse(r))
    return False, f"Не удалось зарегистрироваться (код {r.status_code})"


async def login(username: str, password: str, telegram_id: int):
    r = await _post("/user/log", {"login": username, "password": password})
    if isinstance(r, str):
        return False, r

    print("LOGIN:", r.status_code, r.text)  # временно, для отладки

    if r.status_code == 200:
        return True, _parse(r)
    return False, f"Не удалось войти (код {r.status_code})"