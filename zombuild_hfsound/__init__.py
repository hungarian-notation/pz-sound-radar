import zombuild

from zombuild import Invocation
import zombuild.plugins

from .gradients.gradients_task import GradientsTask

from zombuild.plugins import ZombuildPlugin


class _CustomPlugin(ZombuildPlugin):
    def __init__(self, **kwargs) -> None:
        super().__init__(**kwargs)
        self.register_task(GradientsTask)

    def setup(self, invocation: Invocation) -> None:
        pass


@zombuild.plugins.plugin()
def plugin(**kwargs):
    return _CustomPlugin(**kwargs)
