import pytz
import time

from datetime import datetime
from datetime import timedelta

from st2common.runners.base_action import Action

__all__ = [
    'WaitUntilAction'
]

def get_next_pubtime():

    now = datetime.utcnow()
    pubtime = now.replace(hour=17, minute=0, second=0, microsecond=0)

    # if before publishing time, return that time
    if now < pubtime:
        return pubtime
    else:
        # After publishing time, so go forward a day
        return pubtime + timedelta(days=1)

class WaitUntilAction(Action):

    def run(self, futuretime=""):

        next_pubtime = get_next_pubtime()

        if futuretime:
            next_pubtime = datetime.strptime('1985-04-12T23:20:50', "%Y-%m-%dT%H:%M:%S")
        
        while True:
            now = datetime.utcnow()
            if now > next_pubtime:
                break
            time.sleep(5000)
