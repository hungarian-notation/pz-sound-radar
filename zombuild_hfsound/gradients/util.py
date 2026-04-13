from typing import Callable, TypeVarTuple, Unpack

import numpy

Args = TypeVarTuple("Args")


def cached_function[T1, T](base: Callable[[T1], T]) -> Callable[[T1], T]:

    cache: dict[T1, T] = dict()

    def closure(arg: T1):
        if isinstance(arg, numpy.ndarray):
            return base(arg)
        if arg in cache:
            return cache[arg]
        else:
            return cache.setdefault(arg, base(arg))

    return closure


def cached_function_variadic[*Args, T](base: Callable[[*Args], T]) -> Callable[[*Args], T]:

    cache: dict[tuple[*Args], T] = dict()

    def closure(*args: Unpack[Args]):
        if args in cache:
            return cache[args]
        else:
            return cache.setdefault(args, base(*args))

    return closure
