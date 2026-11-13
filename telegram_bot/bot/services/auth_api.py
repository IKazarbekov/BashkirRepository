import os

import httpx

API_URL = os.getenv("API_URL", "http://10.161.85.19:8000")


def _parse(r: httpx.Response):
    """Ответ как объект, если это JSON, иначе как строка."""
    try:
        return r.json()
    except ValueError:
        return r.text


async def _post(path: str, username: str, password: str):
    try:
        async with httpx.AsyncClient(base_url=API_URL, timeout=10) as client:
            return await client.post(
                path,
                params={"login": username, "password": password},
            )
    except httpx.ConnectError:
        return "Сервер недоступен (возможно, у друга выключен бэкенд или другая сеть)"
    except httpx.TimeoutException:
        return "Сервер не ответил вовремя"


async def register(username: str, password: str, telegram_id: int) -> tuple[bool, str]:
    r = await _post("/register", username, password)
    if isinstance(r, str):  # пришла ошибка соединения
        return False, r

    print("REGISTER:", r.status_code, r.text)  # временно, для отладки

    if r.status_code == 200:
        return True, str(_parse(r))
    return False, f"Не удалось зарегистрироваться (код {r.status_code})"


async def login(username: str, password: str, telegram_id: int) -> tuple[bool, str]:
    r = await _post("/login", username, password)
    if isinstance(r, str):
        return False, r

    print("LOGIN:", r.status_code, r.text)  # временно, для отладки

    if r.status_code == 200:
        return True, str(_parse(r))
    return False, f"Не удалось войти (код {r.status_code})"