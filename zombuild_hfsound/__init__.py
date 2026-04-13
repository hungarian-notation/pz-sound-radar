import zombuild
import zombuild.plugins
from zombuild import Invocation
from zombuild.plugins import ZombuildPlugin

from .gradients.gradients_task import GradientsTask


class _CustomPlugin(ZombuildPlugin):
    def __init__(self, **kwargs) -> None:
        super().__init__(**kwargs)
        self.register_task(GradientsTask)

    def setup(self, invocation: Invocation) -> None:
        pass


@zombuild.plugins.plugin()
def plugin(**kwargs):
    return _CustomPlugin(**kwargs)
