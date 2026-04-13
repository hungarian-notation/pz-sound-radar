from zombuild_hfsound.gradients.gradients import Gradient, gradient_default, gradient_electronic

from zombuild.fs import expand
from zombuild import Invocation
from zombuild.tasks import ActionableTask
from zombuild_core import CorePlugin

import time


class GradientsTask(ActionableTask):
    def __init__(
        self,
        invocation: Invocation,
        output: str,
        width: int,
        height: int,
        **kwargs,
    ) -> None:
        super().__init__(invocation=invocation, **kwargs)

        self.output = expand(output, invocation.project_dir)
        self.width = width
        self.height = height

    def setup(self, invocation: Invocation) -> None:
        invocation.lifecycle_task("build").depends_on(self)
        invocation.require_task("enums").depends_on(self)
        invocation.require_task(CorePlugin.BUILD_TASK).depends_on(self)

        self.gradients: dict[str, Gradient] = {
            "normal": gradient_default(1, 0.5, 0.5),
            "edge": gradient_default(1, 0.5, 0.25),
            "electronics-2": gradient_electronic(2, pointy=True),
            "electronics-3": gradient_electronic(3, pointy=True),
            "electronics-4": gradient_electronic(4, pointy=True),
            "electronics-5": gradient_electronic(5, pointy=True),
        }

    def execute(self) -> None:
        if not self.output.exists():
            self.output.mkdir(parents=True)

        calctime = 0
        iotime = 0

        for name in self.gradients:
            gradient = self.gradients[name]

            s1 = time.time_ns()
            image = gradient.render(
                width=self.width,
                height=self.height,
            )

            s2 = time.time_ns()
            output_path = self.output / f"{name}.png"

            if output_path.exists():
                output_path.unlink()

            image.save(output_path, "png", quality=100)
            s3 = time.time_ns()

            calctime += s2 - s1
            iotime += s3 - s2

        print(f"cpu  = {calctime/(10**9):.8f}")
        print(f"disk = {iotime/(10**9):.8f}")
