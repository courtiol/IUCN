import mechanicalsoup

browser = mechanicalsoup.Browser()
page = browser.get("http://apps.webofknowledge.com/UA_GeneralSearch_input.do?product=UA&search_mode=GeneralSearch&SID=Q1ma1TSYfPRb1qUor5s&preferencesSaved=")

form = page.soup.select("form")[3] # The 4th form is the search form
fields = form.find_all("input")

search_term = fields[-13]
#fields[-13] = '<input id="value(hidInput1)" name="value(hidInput1)" type="hidden" value="test"/>'

d = {e['name']: e.get('value', '') for e in form.find_all('input', {'name': True})}
d['value(input1)'] = 'AU=test' #figure out what topic is
# request body from website for "homo sapiens" and "homo and sapiens": fieldCount=1&action=search&product=UA&search_mode=GeneralSearch&SID=Q1ma1TSYfPRb1qUor5s&max_field_count=25&max_field_notice=Notice%3A+You+cannot+add+another+field.&input_invalid_notice=Search+Error%3A+Please+enter+a+search+term.&exp_notice=Search+Error%3A+Patent+search+term+could+be+found+in+more+than+one+family+%28unique+patent+number+required+for+Expand+option%29+&input_invalid_notice_limits=+%3Cbr%2F%3ENote%3A+Fields+displayed+in+scrolling+boxes+must+be+combined+with+at+least+one+other+search+field.&sa_params=UA%7C%7CQ1ma1TSYfPRb1qUor5s%7Chttps%3A%2F%2Fapps.webofknowledge.com%3A443%7C%27&formUpdated=true&value%28input1%29=%22homo+sapiens%22&value%28select1%29=TS&x=0&y=0&value%28hidInput1%29=&limitStatus=collapsed&ss_lemmatization=On&ss_spellchecking=Suggest&SinceLastVisit_UTC=&SinceLastVisit_DATE=&range=ALL&period=Year+Range&startYear=1945&endYear=2016&update_back2search_link_param=yes&ssStatus=display%3Anone&ss_showsuggestions=ON&ss_query_language=auto&ss_numDefaultGeneralSearchFields=1&rs_sort_by=PY.D%3BLD.D%3BSO.A%3BVL.D%3BPG.A%3BAU.A


fieldCount=1&action=search&product=UA&search_mode=GeneralSearch&SID=Q1ma1TSYfPRb1qUor5s&max_field_count=25&max_field_notice=Notice%3A+You+cannot+add+another+field.&input_invalid_notice=Search+Error%3A+Please+enter+a+search+term.&exp_notice=Search+Error%3A+Patent+search+term+could+be+found+in+more+than+one+family+%28unique+patent+number+required+for+Expand+option%29+&input_invalid_notice_limits=+%3Cbr%2F%3ENote%3A+Fields+displayed+in+scrolling+boxes+must+be+combined+with+at+least+one+other+search+field.&sa_params=UA%7C%7CQ1ma1TSYfPRb1qUor5s%7Chttps%3A%2F%2Fapps.webofknowledge.com%3A443%7C%27&formUpdated=true&value%28input1%29=homo+and+sapiens&value%28select1%29=TS&x=75&y=12&value%28hidInput1%29=&limitStatus=collapsed&ss_lemmatization=On&ss_spellchecking=Suggest&SinceLastVisit_UTC=&SinceLastVisit_DATE=&range=ALL&period=Year+Range&startYear=1998&endYear=2015&update_back2search_link_param=yes&ssStatus=display%3Anone&ss_showsuggestions=ON&ss_query_language=auto&ss_numDefaultGeneralSearchFields=1&rs_sort_by=PY.D%3BLD.D%3BSO.A%3BVL.D%3BPG.A%3BAU.A

d['startYear'] = 1998
d['endYear'] = 2015

url = 'http://apps.webofknowledge.com/UA_GeneralSearch_input.do?product=UA&search_mode=GeneralSearch&SID=Q1ma1TSYfPRb1qUor5s&preferencesSaved=' + form['action']
import requests
req = requests.post(url, data=d)
from bs4 import BeautifulSoup
r = BeautifulSoup(req.text)

# Step 1:
# Get total number of results per search for some keywords
# Step 2:
# Add to marked list and export with abstracts and everything


