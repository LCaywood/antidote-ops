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

    # Set to hour 17 (9AM Pacific) as the publishing time.
    pubtime = now.replace(hour=17)

    # if it is currently after the publishing time, roll forward to the next day.
    if now > pubtime:
        return pubtime + timedelta(days=1)

    # Don't publish on Friday through Sunday. Roll forward the necessary number of days to make
    # it publish on Monday.
    if pubtime.weekday() in [4,5,6]:
        daysforward = 7 - pubtime.weekday()
        pubtime = pubtime + timedelta(days=daysforward)

    return pubtime


class WaitUntilAction(Action):

    def run(self, futuretime=""):

        next_pubtime = get_next_pubtime()

        self.logger.info('Waiting until %s' % next_pubtime)
        print('Waiting until %s' % next_pubtime)

        # DEPRECATED - still here, but will likely remove this in the near future.
        if futuretime:
            next_pubtime = datetime.strptime(futuretime, "%Y-%m-%dT%H:%M:%S")
        
        while True:
            now = datetime.utcnow()
            if now > next_pubtime:
                break
            time.sleep(5000)
