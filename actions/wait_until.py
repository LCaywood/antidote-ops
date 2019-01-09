import time

from datetime import datetime
from datetime import timedelta

from st2common.runners.base_action import Action

__all__ = [
    'WaitUntilAction'
]

class WaitUntilAction(Action):

    def run(self, timestr):
        
        next_pubtime = datetime.strptime(timestr, "%Y-%m-%dT%H:%M:%S")
        
        while True:
            now = datetime.utcnow()
            if now > next_pubtime:
                break
            time.sleep(5)
