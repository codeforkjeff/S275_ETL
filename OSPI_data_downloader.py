
# coding: utf-8

# # Dowloading multiple S275 files from state web-site

import urllib
import urllib.request
import os
import requests
import time
import zipfile


input_dir = os.path.join(os.path.dirname(__file__), "input")

data_links = [
"https://ospi.k12.wa.us/sites/default/files/2023-08/2013-2014_final_s-275_personnel_database.zip"
,"https://ospi.k12.wa.us/sites/default/files/2023-08/2014-2015_final_s-275_personnel_database.zip"
,"https://ospi.k12.wa.us/sites/default/files/2023-08/2015-2016_final_s-275_personnel_database.zip"
,"https://ospi.k12.wa.us/sites/default/files/2023-08/2016-2017_final_s-275_personnel_database.zip"
,"https://ospi.k12.wa.us/sites/default/files/2023-08/2017-2018finals-275personneldatabase.zip"
,"https://ospi.k12.wa.us/sites/default/files/2023-08/2018-2019_final_s-275_personnel_database.zip"
,"https://ospi.k12.wa.us/sites/default/files/2023-08/2019-2020_final_s-275_personnel_database.zip"
,"https://ospi.k12.wa.us/sites/default/files/2023-08/2020-2021_final_s-275_personnel_database.zip"
,"https://ospi.k12.wa.us/sites/default/files/2023-11/2021-2022_final_s-275_personnel_database.zip"
,"https://ospi.k12.wa.us/sites/default/files/2023-10/2022-2023_final_s-275_personnel_database_1.zip"
]

for link in data_links:

    # Specify the location path and append the file name from the link
    file_name = os.path.join(input_dir, link.split('/')[-1])

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
        zip_ref.extractall(input_dir)
