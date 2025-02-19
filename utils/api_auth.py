# -*- coding: utf-8 -*-
"""
@author: criddel - adapted from existing code by jfraser

Created on 02-08-2023
Updated 02-18-2025 to use dotenv package

"""

import requests
import os
from dotenv import load_dotenv, dotenv_values

# loading variables from .env file
load_dotenv() 

# accessing values
user = os.getenv("user")
passwd = os.getenv("passwd")

token_samples = ''

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
        
class aq_api_client():
    """
    wrap requests in REST api format
    """

    def __init__(self, host_type):
        """
        create target urls for each api, and authenticate session
        """
        if host_type == "test":
            host = 'https://bcmoe-test.aquaticinformatics.net'
        elif host_type == "prod":
            host = 'https://bcmoe-prod.aquaticinformatics.net:443'
        elif host_type == "samples":
            host = 'https://bcenv-training.aqsamples.com'
            self.samples = aq_api_session(host, '/')
            self.connect_samples()
        self.publish = aq_api_session(host, '/AQUARIUS/Publish/v2')
        self.acquisition = aq_api_session(host, '/AQUARIUS/Acquisition/v2')
        self.provisioning = aq_api_session(host, '/AQUARIUS/Provisioning/v1')
        self.samples = aq_api_session(host, '/api/v1')

    def connect_samples(self):  
        self.samples.post('/session', json = {'Authorization': token_samples}).text

    def connect(self):
        """
        create authenticated api session
        """
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

