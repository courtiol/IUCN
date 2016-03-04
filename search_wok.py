import mechanicalsoup
import requests
import re

def search_wok(search_string, start_year, end_year):
    browser = mechanicalsoup.Browser()
    url = 'http://apps.webofknowledge.com/UA_GeneralSearch.do'
    page = browser.get(url)

    form = page.soup.select('form')[3] # The 4th form is the search form

    form_dict = {e['name']: e.get('value', '') for e in form.find_all('input', {'name': True})}
    selected_options = form.find_all('option', {'selected': True})
    for sel in selected_options:
        form_dict.update({sel.find_parent()['name']: sel['value']})
    form_dict['value(input1)'] = search_string
    form_dict['startYear'] = start_year
    form_dict['endYear'] = end_year

    search_result = requests.post(url, data=form_dict) # don't seem to need cookies, add 'cookies=page.cookies' if issues arise
    # probably a good idea to add some error management before returning
    return search_result.text

def get_result_count(search_result_text):
    # Get total number of results per search for some keywords
    result_count_location = re.compile('FINAL_DISPLAY_RESULTS_COUNT = \d+').search(search_result_text).span()
    result_count = search_result_text[result_count_location[0]:result_count_location[1]].split()[-1]

# Step 2:
# Add to marked list and export with abstracts and everything

def write_res(string):
    f = open('out.html', 'w')
    f.write(string)
    f.close()

search_wok('homo sapiens', 1998, 2015)
