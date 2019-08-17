
# coding: utf-8

# # Dowloading multiple S275 files from state web-site

import urllib
import urllib.request
import os
import requests
import time
import zipfile
from bs4 import BeautifulSoup

'''
URL of the OSPI web-page which provides link to
all the data files.
In this example, we first crawl the webpage to extract
all the links and then download the data.
'''
 
# specify the URL's
data_url = "http://www.k12.wa.us/safs/"
archive_url = "http://www.k12.wa.us/safs/db.asp"

# OSPI's website changed in 2019: this no longer works
def get_data_links():
     
    # create request object
    r = requests.get(archive_url)
     
    # create beautiful-soup object like inspect element in chrome
    soup = BeautifulSoup(r.content,'html5lib')
     
    # find all links on web-page
    links = soup.findAll('a')
 
    # only look at links that end with desired file type...in our case ".mdb" and ".accdb"...both access files
    l_links = [data_url + link['href'] for link in links if link['href'].endswith(('.mdb', '.accdb')) and ("S275" in link['href'] or "S-275" in link['href'])]

    data_links = sorted([str(link) for link in set(l_links)])

    return data_links
 


# ## Let's try to create a loop to do the job...

hd = os.path.join(os.path.dirname(__file__), "input")

#data_links = get_data_links()

data_links = [
"https://www.k12.wa.us/sites/default/files/public/safs/pub/per/1819/2018-2019PreliminaryS-275PersonnelDatabase.zip"
,"https://www.k12.wa.us/sites/default/files/public/safs/pub/per/1718/2017-2018FinalS-275PersonnelDatabase.zip"
,"https://www.k12.wa.us/sites/default/files/public/safs/pub/per/1617/2016-2017_Final_S-275_Personnel_Database.zip"
,"https://www.k12.wa.us/sites/default/files/public/safs/pub/per/1516/2015-2016_Final_S-275_Personnel_Database.zip"
,"https://www.k12.wa.us/sites/default/files/public/safs/pub/per/1415/2014-2015_Final_S-275_Personnel_Database.zip"
,"https://www.k12.wa.us/sites/default/files/public/safs/pub/per/1314/2013-2014_Final_S-275_Personnel_Database.zip"
]

for link in data_links:

    # Specify the location path and append the file name from the link
    file_name = os.path.join(hd, link.split('/')[-1])

    if not os.path.exists(file_name):
        # retrienve file and dump in the specified folder
        # I get intermittent 400 errors from site, so retry
        tries = 0
        success = False
        while not success and tries < 3:
            try:
                print("Downloading %s" % (file_name,))
                urllib.request.urlretrieve(link, file_name)
                success = True
            except Exception as e:
                print("Error downloading %s: %s" % (file_name, e))
                print("Retrying in 10 seconds...")
                os.remove(file_name)
            tries = tries + 1
    else:
        print("File already exists, skipping download: %s" % (file_name,))

    print("Unzipping  %s" % (file_name,))

    with zipfile.ZipFile(file_name, 'r') as zip_ref:
        zip_ref.extractall(hd)
