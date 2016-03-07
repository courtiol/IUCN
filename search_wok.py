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
    # 'homo sapiens' search says 6,981, but when you go to the last record it's actually 4,681 with the databases FU has
    result_count_location = re.compile('FINAL_DISPLAY_RESULTS_COUNT = \d+').search(search_result_text).span()
    return search_result_text[result_count_location[0]:result_count_location[1]].split()[-1]

def write_res(string):
    f = open('out.html', 'w')
    f.write(string)
    f.close()

def write_record_to_csv(list):
    with open('records_out.csv', 'a', newline='') as csvfile:
        outputter = csv.writer(csvfile, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
        outputter.writerow(list)

search = search_wok('homo sapiens', 1998, 2015)
result_count = get_result_count(search.text)

# Export with abstracts and everything
soup = BeautifulSoup(search.text)
base_url = 'http://apps.webofknowledge.com'
record_1_link = soup.find('div', id='RECORD_1').find('a')['href']
# combine the following into recursive function
# start at record 1

req = requests.get(base_url + record_1_link)
soup = BeautifulSoup(req.text)
if soup.select_one('div.title').select_one('item') != None:
    title = soup.select_one('div.title').select_one('item').text
    pub_date = soup.find('span', string='Published:').next.next
elif soup.select_one('div.title').select_one('value') != None:
    title = soup.select_one('div.title').select_one('value').text
    pub_date = soup.find('span', string='Published:').findNext('value').text

authors = []
author_links = soup.find_all('a', attrs={'href': re.compile('AU')})
for link in author_links:
    authors.append(link.text)

if soup.find('span', string='DOI:') != None:
    if soup.find('span', string='DOI:').next.next == '\n':
        doi = soup.find('span', string='DOI:').findNext('value').text
    else:
        doi = soup.find('span', string='DOI:').next.next
else:
    doi = 'NA'
journal = soup.select_one('p.sourceTitle').select_one('value').text
abstract = soup.find('div', class_='title3', string='Abstract').findNext('p', class_='FR_field').text
times_cited = soup.find('span', class_='TCcountFR').text
next_link = soup.find('a', class_='paginationNext')['href']
record_data_list = [title, authors, pub_date, journal, doi, times_cited]
# then write all values to file
write_record_to_csv(record_data_list)

# Next record
req = requests.get(base_url + next_link)
soup = BeautifulSoup(req.text)
authors = []
author_links = soup.find_all('a', attrs={'href': re.compile('AU')})
for link in author_links:
    authors.append(link.text)

journal = soup.select_one('p.sourceTitle').select_one('value').text
abstract = soup.find('div', class_='title3', string='Abstract').findNext('p', class_='FR_field').text
next_link = soup.find('a', class_='paginationNext')['href']
# check for class="paginationNext paginationNextDisabled" to indicate last page
