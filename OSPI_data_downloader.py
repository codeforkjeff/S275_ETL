
# coding: utf-8

# # Dowloading multiple S275 files from state web-site

import urllib
import urllib.request
import requests
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

 
def get_data_links():
     
    # create request object
    r = requests.get(archive_url)
     
    # create beautiful-soup object like inspect element in chrome
    soup = BeautifulSoup(r.content,'html5lib')
     
    # find all links on web-page
    links = soup.findAll('a')
 
    # only look at links that end with desired file type...in our case ".mdb" and ".accdb"...both access files
    l_links = [data_url + link['href'] for link in links if link['href'].endswith(('.mdb', '.accdb'))]
    
    data_links=[]
    # remove the duplication...there must be a better way!
    i = set(l_links) 
    for x in i:
        link = str(x)       
        data_links+=(x,)
 
    return data_links
 


# ## Let's try to create a loop to do the job...

#test = 'http://www.k12.wa.us/safs/PUB/PER/0405/2004-2005S275FinalForPublic.mdb'
#test.split('/')[-1]   
#'C:/Users/jhernandez/Documents/S275/'+test.split('/')[-1]

hd = 'C:/Users/jhernandez/Documents/S275/'
data_links = get_data_links()

for link in data_links:
         
        # Specify the location path and append the file name from the link
        file_name = hd+link.split('/')[-1]   

        # retrienve file and dump in the specified folder
        urllib.request.urlretrieve(link, file_name)


