from abc import ABC
from typing import TYPE_CHECKING

import numpy as np
from PIL import Image

from zombuild_hfsound.gradients.easing import smoothstep

if TYPE_CHECKING:
    from typing import Any, Callable

type GradientFunction = Callable[
    [float | np.float64, float | np.float64], float | np.float64
]

type VectorFunction = Callable[[GradientArray], GradientArray]
"""
A callable that operates on a numpy vector
"""

type GradientArray = np.ndarray[tuple[Any, ...], np.dtype[np.float64]]


class Gradient(ABC):
    def solve(self, width: int, height: int) -> GradientArray: ...
    def render(self, width: int, height: int) -> Image.Image:
        values = self.solve(width=width, height=height)
        alpha = np.expand_dims((values * 255).astype(np.uint8), 2)
        value = np.full((height, width, 1), 0xFF, dtype=alpha.dtype)
        av = np.dstack((value, alpha))
        img = Image.fromarray(av, mode="LA")
        return img


class ClosureGradient(Gradient):
    def __init__(self, fn: GradientFunction):
        self.fn = fn

    def evaluate(self, x, y):
        return self.fn(x, y)

    def solve(self, width: int, height: int):
        def scaled(y, x):
            return self.evaluate(x / width, y / height)

        base = np.clip(np.fromfunction(scaled, (height, width)), 0, 1)
        return base


class IndependentGradient(Gradient):
    """
    A gradient where the alpha value of any pixel can be found by multiplying
    some function of its x coordinate by some function of its y coordinate.

    This lets us compute a horizontal and vertical alpha vector independently,
    and then efficiently compute the full array by taking the outer product
    of those two vectors.
    """

    def __init__(self, fx: VectorFunction, fy: VectorFunction, scalar: float = 1.0):
        self.xfn = fx
        self.yfn = fy
        self.scalar = scalar

    def solve(self, width: int, height: int):
        horizontal_alpha = np.fromfunction(
            lambda x: np.multiply(
                self.scalar, self.xfn(np.divide(np.float64(x), np.float64(width)))
            ),
            (width,),
            dtype=np.float64,
        )

        vertical_alpha = np.fromfunction(
            lambda y: np.multiply(
                self.scalar, self.yfn(np.divide(np.float64(y), np.float64(height)))
            ),
            (height,),
            dtype=np.float64,
        )

        return np.clip(horizontal_alpha[None, :] * vertical_alpha[:, None], 0, 1)


def gradient_default(exposure: float, softness: float, knee: float = 0.25):

    def xalpha(x):
        return smoothstep(0, softness, x) * smoothstep(1, 1 - softness, x)

    def yalpha(y):
        return smoothstep(0, knee, y) * smoothstep(1, knee, y)

    return IndependentGradient(
        xalpha,
        yalpha,
        scalar=exposure,
    )


def gradient_electronic(frequency: float, pointy=False):

    cos_factor = frequency * 2 * np.pi

    def xalpha(x):
        return smoothstep(0, 0.5, x) * smoothstep(1, 0.5, x)

    if pointy:

        def sec(a):
            return 1 / np.cos(a)

        def yalpha(y):
            return 1 - 1 / np.abs(sec(cos_factor * y / 2))

    else:

        def yalpha(y):
            return np.add(1, -np.cos(np.multiply(y, cos_factor)))

    return IndependentGradient(xalpha, yalpha)
