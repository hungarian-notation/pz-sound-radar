import numpy as np

smoothstep_polynomial = np.polynomial.Polynomial((0, 0, 0, 10, -15, 6))


def smoothstep(a, b, x):
    return smoothstep_polynomial(linear_step(a, b, x))


def circular_impl(x):
    a = 0.5 + easein_circular(0.5, 1, x) / 2
    b = 0.5 - easein_circular(0.5, 0, x) / 2
    return np.where(x > 0.5, a, b)


def circular(a, b, x):
    return circular_impl(linear_step(a, b, x))


def supercircular_impl(x):
    a = 0.5 + easein_supercircular(0.5, 1, x) / 2
    b = 0.5 - easein_supercircular(0.5, 0, x) / 2
    return np.where(x > 0.5, a, b)


def supercircular(a, b, x):
    return supercircular_impl(linear_step(a, b, x))


def easein_circular_impl(x):
    return np.sqrt(1 - (x - 1) ** 2)


def easein_circular(a, b, x):
    return easein_circular_impl(linear_step(a, b, x))


def easein_supercircular_impl(x):
    return 2 * np.sqrt(2 - x) * np.sqrt(x) - 2 * x + x**2


def easein_supercircular(a, b, x):
    return easein_supercircular_impl(linear_step(a, b, x))


def easein_impl(x):
    return 2 * smoothstep(0, 1, 0.5 + x / 2) - 1


def easein(a, b, x):
    return easein_impl(linear_step(a, b, x))


def linear_step(a, b, x):
    return np.clip((x - a) / (b - a), 0, 1)
