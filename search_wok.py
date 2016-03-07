import mechanicalsoup
import requests
import re
from bs4 import BeautifulSoup
import csv

csv_name_file = 'Table_2007.csv'
column_number = 1 # Column with scientific names to query for

base_url = 'http://apps.webofknowledge.com'
errors = []

def search_wok(search_string, start_year, end_year):
    print('!!!! Searching ' + search_string + ' !!!!')
    browser = mechanicalsoup.Browser()
    url = base_url + '/UA_GeneralSearch.do'
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
    try:
        result_count_location = re.compile('FINAL_DISPLAY_RESULTS_COUNT = \d+').search(search_result_text).span()
        return search_result_text[result_count_location[0]:result_count_location[1]].split()[-1]
    except:
        print('Error in get_result_count')
        errors.append(['get_result_count', search_result_text])

def scrape_record_data(record_link, last_record_number):
    req = requests.get(base_url + record_link)
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
    abstract = soup.find('div', class_='title3', string='Abstract').findNext('p', class_='FR_field').text.strip()
    times_cited = soup.find('span', class_='TCcountFR').text
    next_link = soup.find('a', class_='paginationNext')['href']
    print(next_link.split('='))
    if soup.find('a', class_='paginationNextDisabled') == None:
        record_number = int(next_link.split('=')[-1]) - 1
        record_data_list = [record_number, title, authors, journal, doi, pub_date, times_cited, abstract]
        print(record_number)
        write_to_csv('records_out.csv', record_data_list)
        scrape_record_data(next_link, record_number)
    else:
        record_number = last_record_number + 1
        record_data_list = [record_number, title, authors, journal, doi, pub_date, times_cited, abstract]
        print(record_number)
        write_to_csv('records_out.csv', record_data_list)
        print('Done with scraping this search!')

def write_res(html_string): # output a html file for debugging
    f = open('out.html', 'w')
    f.write(html_string)
    f.close()

def write_to_csv(file_name, list):
    with open(file_name, 'a', newline='') as csvfile:
        outputter = csv.writer(csvfile, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
        outputter.writerow(list)

# import csv file with species names
species_list = []
listfile_unprocessed = []
with open(csv_name_file, newline='') as csvfile:
     listfile = csv.reader(csvfile, delimiter=',', quotechar='"')
     for row in listfile:
         listfile_unprocessed.append(row)

listfile_unprocessed.pop(0) # Get rid of column title

for row in listfile_unprocessed:
    species_name = row[(column_number - 1)]
    if species_name not in species_list:
        species_list.append(species_name)

print(species_list)

year_range_before = [listfile_unprocessed[0][5], listfile_unprocessed[0][4]]
year_range_after = [str(int(listfile_unprocessed[0][4]) + 1), listfile_unprocessed[0][6]]
print('RANGES')
print(year_range_before)
print(year_range_after)

def process_search(species, search_string, start_year, end_year): # search result object is search_wok(search_string, start_year, end_year):
    search_result_text = search_wok(search_string, start_year, end_year).text
    result_count = get_result_count(search_result_text)
    write_to_csv('result_count.csv', [species, search_string, start_year, end_year, result_count])
    soup = BeautifulSoup(search_result_text)
    record_1_link = soup.find('div', id='RECORD_1').find('a')['href']
    scrape_record_data(record_1_link, 0)


for species in species_list:
    search_string_1 = '"' + species + '"'
    search_string_2 = ' AND '.join(species.split())
    process_search(species, search_string_1, year_range_before[0], year_range_before[1])
    process_search(species, search_string_2, year_range_before[0], year_range_before[1])
    process_search(species, search_string_1, year_range_after[0], year_range_after[1])
    process_search(species, search_string_2, year_range_after[0], year_range_after[1])
