################################################################
# File: mal.py
# Author: Agunq <agunq.e@gmail.com>
# Version: 1.0
# Description:
# A module that is used to obtain information about the anime or manga of the site myanimelist.net
################################################################
# Copyright 2015 Agunq
################################################################

import sys
import re
import base64

if sys.version_info[0] < 3:
  class urllib:
    parse = __import__("urllib")
    request = __import__("urllib2")
  class http:
    client = __import__("httplib")
else:
  import http.client
  import urllib.request
  import urllib.parse

def Auth(USER = None, PASSWORD = None):
  if USER != None or PASSWORD != None:
    auth = base64.encodestring('{user}:{password}'.format(user = USER, password = PASSWORD).encode('utf-8')).decode('utf-8').strip()
    return auth

def Request(URL = None, TYPE = None, AUTH = None):
    host =  URL[7:].split("/")[0]
    path = "/" + "/".join(URL[7:].split("/")[1:])
    headers = {
    'Content-Type':'application/x-www-form-urlencoded',
    'Host':'myanimelist.net',
    'Origin':'http://myanimelist.net',
    'User-Agent':'Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.22 Safari/537.36',
    'Authorization':'Basic %s' % (AUTH)
    }
    conn = http.client.HTTPConnection("myanimelist.net")
    conn.request(TYPE, path, None, headers)
    text = conn.getresponse().read().decode('utf-8', errors='ignore')
    conn.close()
    return text

class _Anime:
  
  def __init__(self, **kw):
    self.mal = None
    self.id = ""
    self.title = ""
    self.english = ""
    self.synonyms = ""
    self.episodes = ""
    self.score = ""
    self.type = ""
    self.status = ""
    self.start_date = ""
    self.end_date = ""
    self.synopsis = ""
    self.image = ""
    for attr, val in kw.items():
      if val == None: continue
      setattr(self, attr, val)
      
  def __repr__(self):
    return "<Anime.id.%s: %s>" %(self.id, self.title)

class _Manga:
  
  def __init__(self, **kw):
    self.mal = None
    self.id = ""
    self.title = ""
    self.english = ""
    self.synonyms = ""
    self.chapters = ""
    self.volumes = ""
    self.score = ""
    self.type = ""
    self.status = ""
    self.start_date = ""
    self.end_date = ""
    self.synopsis = ""
    self.image = ""
    for attr, val in kw.items():
      if val == None: continue
      setattr(self, attr, val)
      
  def __repr__(self):
    return "<Manga.id.%s: %s>" %(self.id, self.title)

class MyAnimeList:
  
  def __init__(self, query = None, auth = None):
    self.query = urllib.parse.quote(query)
    self.auth = Auth(auth[0], auth[1])
    self.data = None
    self.animeresults = list()
    self.mangaresults = list()
    self.entry = None

  def AnimeSearch(self):
      self.data = Request('http://myanimelist.net/api/anime/search.xml?q=%s'% (self.query), TYPE = "GET", AUTH = self.auth).replace('\r','').replace('\n','').replace('&lt;br /&gt;','<br />').replace('&amp;','&')
      _id = re.findall("<id>(.*?)</id>", self.data)
      _title= re.findall("<title>(.*?)</title>", self.data)
      _english = re.findall("<english>(.*?)</english>", self.data)
      _synonyms = re.findall("<synonyms>(.*?)</synonyms>", self.data)
      _episodes = re.findall("<episodes>(.*?)</episodes>", self.data)
      _score = re.findall("<score>(.*?)</score>", self.data)
      _type = re.findall("<type>(.*?)</type>", self.data)
      _status = re.findall("<status>(.*?)</status>", self.data)
      _start_date = re.findall("<start_date>(.*?)</start_date>", self.data)
      _end_date = re.findall("<end_date>(.*?)</end_date>", self.data)
      _synopsis = re.findall("<synopsis>(.*?)</synopsis>", self.data)
      _image = re.findall("<image>(.*?)</image>", self.data)
      self.entry = [pair for pair in zip(_id,_title,_english,_synonyms,_episodes,_score,_type,_status,_start_date,_end_date,_synopsis,_image)]
      for entry in self.entry:
        _anime = _Anime(
          mal = self,
          id = entry[0],
          title = entry[1],
          english = entry[2],
          synonyms = entry[3],
          episodes = entry[4],
          score = entry[5],
          type = entry[6],
          status = entry[7],
          start_date = entry[8],
          end_date = entry[9],
          synopsis = entry[10],
          image = entry[11]
          )
        if _anime not in self.animeresults:
          self.animeresults.append(_anime)
      return self.animeresults
    
  def MangaSearch(self):
      self.data = Request('http://myanimelist.net/api/manga/search.xml?q=%s'% (self.query), TYPE = "GET", AUTH = self.auth).replace('\r','').replace('\n','').replace('&lt;br /&gt;','<br />').replace('&amp;','&')
      _id = re.findall("<id>(.*?)</id>", self.data)
      _title= re.findall("<title>(.*?)</title>", self.data)
      _english = re.findall("<english>(.*?)</english>", self.data)
      _synonyms = re.findall("<synonyms>(.*?)</synonyms>", self.data)
      _chapters = re.findall("<chapters>(.*?)</chapters>", self.data)
      _volumes = re.findall("<volumes>(.*?)</volumes>", self.data)
      _score = re.findall("<score>(.*?)</score>", self.data)
      _type = re.findall("<type>(.*?)</type>", self.data)
      _status = re.findall("<status>(.*?)</status>", self.data)
      _start_date = re.findall("<start_date>(.*?)</start_date>", self.data)
      _end_date = re.findall("<end_date>(.*?)</end_date>", self.data)
      _synopsis = re.findall("<synopsis>(.*?)</synopsis>", self.data)
      _image = re.findall("<image>(.*?)</image>", self.data)
      self.entry = [pair for pair in zip(_id,_title,_english,_synonyms,_chapters,_volumes,_score,_type,_status,_start_date,_end_date,_synopsis,_image)]
      for entry in self.entry:
        _manga = _Manga(
          mal = self,
          id = entry[0],
          title = entry[1],
          english = entry[2],
          chapters = entry[3],
          volumes = entry[4],
          score = entry[5],
          type = entry[6],
          status = entry[7],
          start_date = entry[8],
          end_date = entry[9],
          synopsis = entry[10],
          image = entry[11]
          )
        if _manga not in self.mangaresults:
          self.mangaresults.append(_manga)
      return self.mangaresults

  anime = property(AnimeSearch)
  manga = property(MangaSearch)
