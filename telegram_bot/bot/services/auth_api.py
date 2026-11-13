import os

import httpx

API_URL = os.getenv("API_URL", "http://localhost:8000")
USE_MOCK = os.getenv("USE_MOCK", "1") == "1"  # 1 = заглушка, пока нет бэкенда

_fake_users: dict[str, str] = {}  # только для заглушки


async def register(username: str, password: str, telegram_id: int) -> tuple[bool, str]:
    if USE_MOCK:
        if username in _fake_users:
            return False, "Такой username уже занят"
        _fake_users[username] = password
        return True, "ok"

    async with httpx.AsyncClient(base_url=API_URL, timeout=10) as client:
        r = await client.post(
            "/auth/register",
            json={"username": username, "password": password, "telegram_id": telegram_id},
        )
    if r.status_code == 201:
        return True, "ok"
    return False, r.json().get("detail", "Ошибка регистрации")


async def login(username: str, password: str, telegram_id: int) -> tuple[bool, str]:
    """Возвращает (успех, токен или текст ошибки)."""
    if USE_MOCK:
        if _fake_users.get(username) == password:
            return True, "fake-token"
        return False, "Неверное имя или пароль"

    async with httpx.AsyncClient(base_url=API_URL, timeout=10) as client:
        r = await client.post(
            "/auth/login",
            json={"username": username, "password": password, "telegram_id": telegram_id},
        )
    if r.status_code == 200:
        return True, r.json()["access_token"]
    return False, "Неверное имя или пароль"