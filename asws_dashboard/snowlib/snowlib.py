# ---
# jupyter:
#   jupytext:
#     formats: ipynb,py:percent
#     text_representation:
#       extension: .py
#       format_name: percent
#       format_version: '1.3'
#       jupytext_version: 1.16.1
#   kernelspec:
#     display_name: Python 3 (ipykernel)
#     language: python
#     name: python3
# ---

# %%
"""

Adapted from: jfraser/criddel
This is the function library for the BC Snow Survey Program. Contact Andrew.Loeppky@gov.bc.ca for inquiries and bug reports
"""

import requests
import os
import json

def login_from_json(file):
    """
    returns python strings from a json file containing attrs "username" and "password"
    best practice is to include the json file in a .gitignore to prevent uploading of credentials
    to unintended locations.
    """
    with open('credentials.json') as json_file:
        cred = json.load(json_file)
    
    # prod server login reads credentials from json file
    host = 'https://bcmoe-prod.aquaticinformatics.net:443'
    user = cred["username"]
    passwd = cred["password"]
    
    return user, passwd

def create_endpoint(host, path):
    """
    combine base url (host) and api url (path)
    """
    # check for root
    if host.startswith('http:') or host.startswith('https:'):
        endpoint = '{0}{1}'.format(host, path)
    else:
        endpoint = '{0}{1}{2}'.format('http://', host, path)
    return endpoint


def response_or_raise(resp):
    """
    check response is valid
    raise error if not
    """
    if resp.status_code >= 400:
        resp.raise_for_status()
    else:
        return resp


class aq_api_session(requests.sessions.Session):
    """
    requests Session object
    - directs all requests to base endpoint
    - raises exception if any http errors encountered
    """

    def __init__(self, host, path):
        super(aq_api_session, self).__init__()
        self.base_url = create_endpoint(host, path)

    def get(self, url, **kwargs):
        """
        makes requests.get call to url
        """
        r = super(aq_api_session, self).get(self.base_url + url, **kwargs)
        return response_or_raise(r)

    def post(self, url, **kwargs):
        """
        makes requests.post call to url
        """
        r = super(aq_api_session, self).post(self.base_url + url, **kwargs)
        return response_or_raise(r)

    def put(self, url, **kwargs):
        """
        makes requests.post call to url
        """
        r = super(aq_api_session, self).put(self.base_url + url, **kwargs)
        return response_or_raise(r)

    def delete(self, url, **kwargs):
        """
        makes requests.delete call to url
        """
        r = super(aq_api_session, self).delete(self.base_url + url, **kwargs)
        return response_or_raise(r)

    def set_token(self, token):
        """
        add auth token to headers for each request
        """
        self.headers.update({'X-Authentication-Token': token})


class aq_api_client:
    """
    wrap requests in REST api format
    """

    def __init__(self):
        """
        create target urls for each api, and authenticate session
        """
        host = 'https://bcmoe-prod.aquaticinformatics.net:443'
        
        self.publish = aq_api_session(host, '/AQUARIUS/Publish/v2')
        self.acquisition = aq_api_session(host, '/AQUARIUS/Acquisition/v2')
        self.provisioning = aq_api_session(host, '/AQUARIUS/Provisioning/v1')
        self.connect()

    def connect(self):
        """
        create authenticated api session
        """
        # get login credentials from json file
        user, passwd = login_from_json(".//credentials.txt")
        # get auth token
        token = self.publish.post('/session',
                                  json={'Username': user,
                                        'EncryptedPassword': passwd}).text
        # add token to headers for each endpoint url
        self.publish.set_token(token)
        self.acquisition.set_token(token)
        self.provisioning.set_token(token)

    def disconnect(self):
        """
        ends session and destroys auth token
        """
        self.publish.delete('/session')


# %%
