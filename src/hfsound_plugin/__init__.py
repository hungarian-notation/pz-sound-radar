from zombuild import Invocation
from zombuild.plugins import ZombuildPlugin

from hfsound_plugin.gradients.gradients_task import GradientsTask


class CustomPlugin(ZombuildPlugin):
    def __init__(self, **kwargs) -> None:
        super().__init__(**kwargs)
        self.register_task(GradientsTask)

    def setup(self, invocation: Invocation) -> None:
        pass

