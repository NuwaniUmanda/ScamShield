import time


def with_retry(func, attempts=2, delay=1.0):
    """Run func(). If it fails, wait a moment and try again (up to `attempts` times)."""
    last_error = None
    for i in range(attempts):
        try:
            return func()
        except Exception as e:
            last_error = e
            if i < attempts - 1:
                time.sleep(delay)
    raise last_error