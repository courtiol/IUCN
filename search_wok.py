import mechanicalsoup
import requests
import re
from bs4 import BeautifulSoup

start_year = '1998'
end_year = '2015'
browser = mechanicalsoup.Browser()
page = browser.get('http://apps.webofknowledge.com/UA_GeneralSearch_input.do')

form = page.soup.select('form')[3] # The 4th form is the search form

form_dict = {e['name']: e.get('value', '') for e in form.find_all('input', {'name': True})}
selected_options = form.find_all('option', {'selected': True})
for sel in selected_options:
     form_dict.update({sel.find_parent()['name']: sel['value']})
# d['value(input1)'] = 'AU=test' # somehow putting the search type in this spot seemed to make the search work last time but i can't figure out how to make it work again. There's an empty client_error_input_message div in the response, maybe there's a error in the post request body?
# other differences: didn't add the selected_options values to the request data last time
form_dict['value(input1)'] = 'homo sapiens'
form_dict['startYear'] = start_year
form_dict['endYear'] = end_year

url = page.url[:-3] + form['action']
print(url)
#search_result = requests.post(url, data=form_dict)
search_result = requests.post(url, data=form_dict, cookies=page.cookies)
search_result_text = search_result.text
# this search result doesn't even have the value(input1) in the search box,  but if i send the request again it does. cookie issue?
# try running same search in browser and in script with the same SID/full search url, see what happens.....
r = BeautifulSoup(search_result_text) # why am i even using mechanicalsoup?

# Step 1:
# Get total number of results per search for some keywords
# result_count_location = re.compile('RESULTS_ = \d+').search(search_result_text).span()
# result_count = search_result_text[result_count_location[0]:result_count_location[1]].split()[-1]

# Step 2:
# Add to marked list and export with abstracts and everything

def write_res(string):
    f = open('out.html', 'w')
    f.write(string)
    f.close()
