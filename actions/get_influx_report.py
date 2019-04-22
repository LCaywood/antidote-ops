import requests
import collections

from st2common.runners.base_action import Action

__all__ = [
    'GetInfluxReport'
]

class GetInfluxReport(Action):

    def run(self):

        final_output_text = \
"""
:pill: *THIS WEEK IN NRE LABS* :syringe:

Number of lessons launched this week:
"""

        host = "10.138.0.3"
        port = "32503"

        r = requests.post('http://%s:%s/query' % (host, port), data = {
            'db':'syringe_metrics',
            'q': 'SELECT * from provisioningTime where time > now() - 7d'
        })

        dataset = r.json()['results'][0]['series'][0]

        total_lessons = len(dataset['values'])

        lessonIdIndex = dataset['columns'].index('lessonId')
        lessonNameIndex = dataset['columns'].index('lessonName')

        lesson_count = {}
        for value in dataset['values']:
            full_name_id = "Lesson %s: %s" % (value[lessonIdIndex], value[lessonNameIndex])
            if full_name_id not in lesson_count:
                lesson_count[full_name_id] = 1
            else:
                lesson_count[full_name_id] += 1

        i = 0
        for count, name in sorted(((value, key) for (key,value) in lesson_count.items()), reverse=True):
            i += count
            final_output_text += "%s - %s\n" % (name, count)

        final_output_text += "\n Total Lessons launched this week: %s" % i

        final_output_text += "\n"

        r = requests.post('http://%s:%s/query' % (host, port), data = {
            'db':'syringe_metrics',
            'q': 'SELECT * from sessionStatus where time > now() - 7d'
        })

        dataset = r.json()['results'][0]['series'][0]

        timeIndex = dataset['columns'].index('time')
        activeNowIndex = dataset['columns'].index('activeNow')

        largest_concurrent_seen = 0
        largest_concurrent_timestamp = ""
        last_seen_time = ""
        lessonCounter = 0
        for value in dataset['values']:
            # We've hit a new timestamp.
            if last_seen_time != value[timeIndex]:
                # Update largest_concurrent_seen if the previous counter exceeded the record
                if lessonCounter > largest_concurrent_seen:
                    largest_concurrent_seen = lessonCounter
                    largest_concurrent_timestamp = last_seen_time
                # Replace last_seen_time
                last_seen_time = value[timeIndex]
                # Start the counter using this first value
                lessonCounter = value[activeNowIndex]
            lessonCounter += value[activeNowIndex]


        final_output_text += "Most concurrent lessons was at %s with %s concurrent lessons\n" % (
            largest_concurrent_timestamp, largest_concurrent_seen)

        print(final_output_text)