import base64
import os

import httpx

API_URL = os.getenv("API_URL", "http://10.136.202.1:8000")


async def get_image(image_id: int) -> tuple[bytes | None, str | None]:
    """Возвращает (байты картинки, None) или (None, текст ошибки)."""
    try:
        async with httpx.AsyncClient(base_url=API_URL, timeout=10, follow_redirects=True) as client:
            r = await client.get(f"/images/{image_id}")
            print("IMAGE:", r.status_code, r.headers.get("content-type"), r.text[:200])  # для отладки

            if r.status_code != 200:
                return None, f"Картинка не найдена (код {r.status_code})"

            # 1) сервер отдал сам файл
            if r.headers.get("content-type", "").startswith("image/"):
                return r.content, None

            # 2) сервер отдал JSON-строку
            try:
                data = r.json()
            except ValueError:
                return None, "Бэкенд вернул не картинку"

            if isinstance(data, str):
                # 2а) ссылка или путь к файлу
                if data.startswith("http") or data.startswith("/"):
                    img = await client.get(data)
                    if img.status_code == 200 and img.headers.get("content-type", "").startswith("image/"):
                        return img.content, None
                    return None, "Не удалось скачать картинку по ссылке"
                # 2б) base64
                try:
                    return base64.b64decode(data, validate=True), None
                except ValueError:
                    return None, "Непонятный формат ответа от бэкенда"

            return None, "Непонятный формат ответа от бэкенда"
    except httpx.ConnectError:
        return None, "Сервер недоступен (возможно, у друга выключен бэкенд или другая сеть)"
    except httpx.TimeoutException:
        return None, "Сервер не ответил вовремя"