import os

import httpx

API_URL = os.getenv("API_URL", "http://10.136.202.1:8000")


async def get_current_step(user_id: int) -> tuple[dict | None, str | None]:
    """Возвращает (данные шага, None) или (None, текст ошибки)."""
    try:
        async with httpx.AsyncClient(base_url=API_URL, timeout=10) as client:
            r = await client.post(
                "/step/get_by_current_step",
                params={"user_id": user_id},
            )
    except httpx.ConnectError:
        return None, "Сервер недоступен (проверь сеть и адрес API)"
    except httpx.TimeoutException:
        return None, "Сервер не ответил вовремя"

    print("STEP:", r.status_code, r.text)  # временно, для отладки

    if r.status_code != 200:
        return None, f"Не удалось получить задание (код {r.status_code})"
    try:
        data = r.json()
    except ValueError:
        return None, "Бэкенд вернул не JSON"
    if not isinstance(data, dict):
        return None, "Непонятный формат ответа от бэкенда"
    return data, None

async def create_answer(user_id: int, step_id: int) -> tuple[bool, str | None]:
    """Сообщает бэкенду, что пользователь ответил на шаг."""
    try:
        async with httpx.AsyncClient(base_url=API_URL, timeout=10) as client:
            r = await client.post(
                "/answer/create_answer",
                params={"user_id": user_id, "step_id": step_id},
            )
    except httpx.ConnectError:
        return False, "Сервер недоступен"
    except httpx.TimeoutException:
        return False, "Сервер не ответил вовремя"

    print("ANSWER:", r.status_code, r.text)  # временно, для отладки

    if r.status_code == 200:
        return True, None
    return False, f"код {r.status_code}"