import feedparser
from st2reactor.sensor.base import PollingSensor


class RSSSensor(PollingSensor):

    def setup(self):
        self.last_feed_seen = {}
        self._logger = self.sensor_service.get_logger(name=self.__class__.__name__)

    def poll(self):

        feed_urls = [
            "https://networkreliability.engineering/feed/",
            "https://keepingitclassless.net/feed/",
        ]

        for url in feed_urls:
            feed = feedparser.parse(url)

            self._logger.info('Looking at feed: %s' % url)

            # If our dict doesn't have an entry, this is likely startup, so just add it and continue
            if not self.last_feed_seen.get(feed['href']):
                self._logger.info('First entry - skipping')
                self.last_feed_seen[feed['href']] = feed['entries'][0]['id']
                continue

            # If the top item is the same we have on record, nothing has changed.
            if self.last_feed_seen[feed['href']] == feed['entries'][0]['id']:
                self._logger.info('Nothing has changed. Skipping this feed.')
                continue

            # If we get to this point, something has changed. Starting at the top of the list, trigger
            # on new content until we reach the item we saw last, up to the most recent 5 items
            new_content_limit = 5
            i = 1
            for entry in feed['entries']:
                if self.last_feed_seen[feed['href']] == entry['id'] or i > new_content_limit:
                    self._logger.info('Reached new content limit. Breaking.')
                    break

                trigger = 'antidoteops.new_content'
                payload = {
                    "title": entry['title'],
                    "featuredimage": entry['featuredimage'],
                    "link": entry['link']
                }

                self._logger.info('Dispatching trigger for new content: %s' % payload)
                self.sensor_service.dispatch(trigger=trigger, payload=payload)

                i += 1

            # Update last seen dict
            self.last_feed_seen[feed['href']] = feed['entries'][0]['id']
        
        self._logger.info('Current last seen posts: %s' % self.last_feed_seen)

    def cleanup(self):
        pass

    def add_trigger(self, trigger):
        pass

    def update_trigger(self, trigger):
        pass

    def remove_trigger(self, trigger):
        pass
