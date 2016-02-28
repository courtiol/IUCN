import mechanicalsoup
import requests
import re
from bs4 import BeautifulSoup

browser = mechanicalsoup.Browser()
page = browser.get("http://apps.webofknowledge.com/UA_GeneralSearch_input.do?product=UA&search_mode=GeneralSearch&SID=Q1ma1TSYfPRb1qUor5s&preferencesSaved=")

form = page.soup.select("form")[3] # The 4th form is the search form

d = {e['name']: e.get('value', '') for e in form.find_all('input', {'name': True})}
d['value(input1)'] = 'AU=test' #figure out what topic is, this is for author
# possible interesting parts from request body from website for "homo and sapiens": 

#&value%28input1%29=homo+and+sapiens
#&sa_params=UA||Q1ma1TSYfPRb1qUor5s|https://apps.webofknowledge.com:443|'
#&formUpdated=true
#&value(input1)=homo and sapiens
#&value(select1)=TS
#&x=75&y=12&ss_lemmatization=On&ss_spellchecking=Suggest&range=ALL
#&period=Year Range&startYear=1998&endYear=2015
#&rs_sort_by=PY.D;LD.D;SO.A;VL.D;PG.A;AU.A

d['startYear'] = 1998
d['endYear'] = 2015

url = 'http://apps.webofknowledge.com/UA_GeneralSearch_input.do?product=UA&search_mode=GeneralSearch&SID=Q1ma1TSYfPRb1qUor5s&preferencesSaved=' + form['action']
search_result = requests.post(url, data=d)
search_result_text = search_result.text
r = BeautifulSoup(search_result_text) # why am i even using mechanicalsoup?

# Step 1:
# Get total number of results per search for some keywords
result_count_location = re.compile('RESULTS_ = \d+').search(search_result_text).span
result_count = search_result_text[result_count_location[0]:result_count_location[1]].split()[-1]

# Step 2:
# Add to marked list and export with abstracts and everything


