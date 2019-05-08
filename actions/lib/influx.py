import requests

def get_lesson_usage():

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
        lesson_id = value[lessonIdIndex]
        description = "Lesson %s: %s" % (value[lessonIdIndex], value[lessonNameIndex])
        if lesson_id not in lesson_count:
            lesson_count[lesson_id] = {
                "lesson_count": 1,
                "description": description
            }
        else:
            lesson_count[lesson_id]['lesson_count'] += 1

    return lesson_count
