from lib.influx import get_lesson_usage

from datetime import datetime

import gspread
from oauth2client.service_account import ServiceAccountCredentials

from st2common.runners.base_action import Action

__all__ = [
    'UpdateNRELabsSheet'
]

class UpdateNRELabsSheet(Action):

    def run(self):

        # use creds to create a client to interact with the Google Drive API
        scope = ['https://spreadsheets.google.com/feeds']
        creds = ServiceAccountCredentials.from_json_keyfile_name('/home/stanley/nrelabs-stats.json', scope)
        client = gspread.authorize(creds)

        # Find a workbook by name and open the first sheet
        # Make sure you use the right name here.
        # sheet = client.open("NRE Labs Weekly Stats").sheet1
        sheet = client.open_by_url('https://docs.google.com/spreadsheets/d/1EROKZ1BWnyP3-mbzHSdFmu4U-HjucIMFPJiJb6W8QO8/edit#gid=0').sheet1

        # Get the next free column to write to
        next_col = len(sheet.row_values(2)) + 1

        # Get the next free row to write to
        next_row = len(sheet.col_values(1)) + 1

        # First, if we need to create a new row, we should do that first.
        # For that, let's get all the existing lesson IDs and make sure
        # if any lessons exist in our dataset but not here, that they're created.
        existing_lesson_ids = sheet.col_values(1)[2:]
        usage = get_lesson_usage()
        diff = [x for x in usage.keys() if x not in existing_lesson_ids]
        for lessonid in diff:
            sheet.insert_row([lessonid, usage[lessonid]['description']], index=next_row)
        existing_lesson_ids = sheet.col_values(1)[2:]

        # Build map of lesson IDs to sheet row index so we don't have to look it up later
        lessonid_sheet_index_map = {}
        i = 3
        for lid in existing_lesson_ids:
            lessonid_sheet_index_map[lid] = i
            i += 1

        # Write out the current dataset
        sheet.update_cell(2, next_col, datetime.now().strftime("%m/%d/%Y"))
        # import pdb; pdb.set_trace()
        for lid, details in usage.items():
            sheet.update_cell(lessonid_sheet_index_map[lid], next_col, details['lesson_count'])
