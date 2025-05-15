def get_serial() -> str:
    """
    Read the Raspberry Pi's CPU serial number from /proc/cpuinfo.
    Returns the hex serial string, or a default string if not found.
    """
    try:
        with open("/proc/cpuinfo", "r") as f:
            for line in f:
                if line.startswith("Serial"):
                    parts = line.split(":", 1)
                    if len(parts) == 2:
                        return parts[1].strip()
    except FileNotFoundError:
        # /proc/cpuinfo not available
        return "cda0"
    return "cda0"