import mechanicalsoup
import requests
import re
from bs4 import BeautifulSoup

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
    return search_result

def get_result_count(search_result_text):
    # Get total number of results per search
    # "Number of results is approximate" so not actually accurate
    # 'homo sapiens' search says 6,981, but when you go to the last record it's actually 4,681
    result_count_location = re.compile('FINAL_DISPLAY_RESULTS_COUNT = \d+').search(search_result_text).span()
    return search_result_text[result_count_location[0]:result_count_location[1]].split()[-1]

#def add_to_marked_list(search_results, mark_from, mark_to):
#    r = BeautifulSoup(search_results.text)
#    add_to_marked_list_form = r.select('form')[9]
#    add_to_marked_list_data = {e['name']: e.get('value', '') for e in add_to_marked_list_form.find_all('input', {'name': True})}
#    add_to_marked_list_data = {'product': add_to_marked_list_data['product'], 'mark_id': add_to_marked_list_data['mark_id'], 'SID': add_to_marked_list_data['SID'], 'qid': add_to_marked_list_data['qid'], 'search_mode': add_to_marked_list_data['search_mode'], 'viewType': 'summary', 'value(record_select_type)': 'range', 'mark_from': mark_from, 'mark_to': mark_to, 'markFrom': mark_from, 'markTo': mark_to}
#    marked_list_form_url = 'http://apps.webofknowledge.com/MarkRecords.do'
#    print(add_to_marked_list_data)
#
#    return requests.get(marked_list_form_url, params=add_to_marked_list_data)

def write_res(string):
    f = open('out.html', 'w')
    f.write(string)
    f.close()

search = search_wok('homo sapiens', 1998, 2015)
result_count = get_result_count(search.text)

# Export with abstracts and everything
soup = BeautifulSoup(search.text)
base_url = 'http://apps.webofknowledge.com'

# combine the following into recursive function
# start at record 1
req = requests.get(base_url + soup.find('div', id='RECORD_1').find('a')['href'])
soup = BeautifulSoup(req.text)
title = soup.select_one('div.title').select_one('value').text
pub_date = soup.find('span', string='Published:').findNext('value').text
authors = []
author_links = soup.find_all('a', attrs={'href': re.compile('AU')})
for link in author_links:
    authors.append(link.text)

doi = soup.find('span', string='DOI:').findNext('value').text
journal = soup.select_one('p.sourceTitle').select_one('value').text
abstract = soup.find('div', class_='title3', string='Abstract').findNext('p', class_='FR_field').text
next_link = soup.find('a', class_='paginationNext')['href']
# then write all values to file

# Next record
req = requests.get(base_url + next_link)
soup = BeautifulSoup(req.text)
# title needs if statement to check if 'item' or 'value'
title = soup.select_one('div.title').select_one('item').text
pub_date = soup.find('span', string='Published:').next.next # group in title if, formatted different depending on ....
authors = []
author_links = soup.find_all('a', attrs={'href': re.compile('AU')})
for link in author_links:
    authors.append(link.text)

# doi needs if statement in case no doi
doi = soup.find('span', string='DOI:').next.next
journal = soup.select_one('p.sourceTitle').select_one('value').text
abstract = soup.find('div', class_='title3', string='Abstract').findNext('p', class_='FR_field').text
next_link = soup.find('a', class_='paginationNext')['href']
# check for class="paginationNext paginationNextDisabled" to indicate last page
