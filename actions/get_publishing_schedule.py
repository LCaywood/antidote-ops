import time

from datetime import datetime
from datetime import timedelta

from st2common.runners.base_action import Action

__all__ = [
    'GetPublishingSchedule'
]

# TODO(mierdin): implement some testing https://docs.stackstorm.com/development/pack_testing.html
class GetPublishingSchedule(Action):

    def skipweekend(self, pubtime):

        # Don't publish on Friday through Sunday. Roll forward the necessary number of days to make
        # it publish on Monday.
        if pubtime.weekday() in [4,5,6]:
            daysforward = 7 - pubtime.weekday()
            pubtime = pubtime + timedelta(days=daysforward)
        
        return pubtime

    def run(self):

        now = datetime.utcnow()

        # Set to hour 17 (9AM Pacific) as the publishing time.
        pubtime = now.replace(hour=17, minute=0, second=0)

        # if it is currently after the publishing time, roll forward to the next day.
        pubtime = pubtime + timedelta(days=1)

        # get first date and put into schedule
        pubtime = self.skipweekend(pubtime)
        rettimes = [
            pubtime.strftime("%Y-%m-%dT%H:%M:%S")
        ]

        # Determine next two publishing days and place in schedule
        for i in range(2):
            pubtime = pubtime + timedelta(days=1)
            pubtime = self.skipweekend(pubtime)
            rettimes.append(pubtime.strftime("%Y-%m-%dT%H:%M:%S"))

        return rettimes
