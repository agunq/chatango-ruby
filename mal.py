################################################################
# File: mal.py
# Author: Agunq <agunq.e@gmail.com>
# Version: 1.0
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
else:
  import urllib.request
  import urllib.parse

def Auth(user, password):
  if user != None or password != None:
    auth = base64.encodestring('{}:{}'.format(user, password).encode('utf-8')).decode('utf-8').strip()
    return auth

def Request(url, auth):
    headers = {
    'Host':'myanimelist.net',
    'Origin':'http://myanimelist.net',
    'User-Agent':'Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.22 Safari/537.36',
    'Authorization':'Basic %s' % (auth)
    }
    conn = urllib.request.Request(url=url, headers=headers)
    text = urllib.request.urlopen(conn).read().decode('utf-8', errors='ignore')
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
    self.duration = ""
    self.rating = ""
    self.japanese = ""
    self.producers = ""
    self.genres = ""
    self.ranked = ""
    self.popularity = ""
    self.members = ""
    self.favorites = ""
    for attr, val in kw.items():
      if val == None: continue
      setattr(self, attr, val)
      
  def getMoreInfo(self):
    _data = Request('http://myanimelist.net/anime/%s' % (self.id), self.mal.auth).replace('\r','').replace('\n','')
    try:self.duration = re.findall('<span class="dark_text">Duration:</span>(.*?)</div>', _data)[0][2:-2]
    except:pass
    try:self.rating = re.findall('<span class="dark_text">Rating:</span>(.*?)</div>', _data)[0][2:-2]
    except:pass
    try:self.japanese = re.findall('<span class="dark_text">Japanese:</span>(.*?)  </div>', _data)[0][1:]
    except:pass
    try:
      _producers = re.findall('<span class="dark_text">Producers:</span>(.*?)</div>', _data)[0]
      _producers = re.findall('<a href="(.*?)" title="(.*?)">(.*?)</a>', _producers)
      self.producers = ", ".join([x[1] for x in _producers])
    except:pass
    try:
      _genres = re.findall('<span class="dark_text">Genres:</span>(.*?)</div>', _data)[0]
      _genres = re.findall('<a href="(.*?)" title="(.*?)">(.*?)</a>', _genres)
      self.genres = ", ".join([x[1] for x in _genres])
    except:pass
    try:
      _score = re.findall('>(.*?)<', re.findall('<span class="dark_text">Score:</span>(.*?)</div>', _data)[0])
      self.score = "%s^%s (scored by %s users)" % (_score[0],_score[2],_score[4])
    except:pass
    try:
      _ranked = re.findall('>(.*?)<', re.findall('<span class="dark_text">Ranked:(.*?)</div>', _data)[0])
      self.ranked = "%s^%s" % (_ranked[0][2:], _ranked[1])
    except:pass
    try:self.popularity = re.findall('<span class="dark_text">Popularity:</span>(.*?)</div>', _data)[0][2:]
    except:pass
    try:self.members = re.findall('<span class="dark_text">Members:</span>(.*?)</div>', _data)[0][2:]
    except:pass
    try:self.favorites = re.findall('<span class="dark_text">Favorites:</span>(.*?)</div>', _data)[0][2:]
    except:pass

  moreinfo = property(getMoreInfo)
      
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
    self.genres = ""
    self.authors = ""
    self.japanese = ""
    self.serializations = ""
    self.ranked = ""
    self.popularity = ""
    self.members = ""
    self.favorites = ""
    for attr, val in kw.items():
      if val == None: continue
      setattr(self, attr, val)
      
  def getMoreInfo(self):
    _data = Request('http://myanimelist.net/manga/%s' % (self.id), self.mal.auth).replace('\r','').replace('\n','')
    try:
      _genres = re.findall('<a href="(.*?)" title="(.*?)">(.*?)</a>', re.findall('<span class="dark_text">Genres:</span>(.*?)</div>', _data)[0])
      self.genres = ", ".join([x[1] for x in _genres])
    except:pass
    try:
      _score = re.findall('>(.*?)<', re.findall('<span class="dark_text">Score:</span>(.*?)</div>', _data)[0])
      self.score = "%s^%s (scored by %s users)" % (_score[0],_score[3],_score[7])
    except:pass
    try:
      _authors = re.findall('<a href="(.*?)">(.*?)</a> \((.*?)\)', re.findall('<span class="dark_text">Authors:</span>(.*?)</div>', _data)[0])
      self.authors = ", ".join(["%s (%s)" % (x[1], x[2]) for x in _authors])
    except:pass
    try:self.japanese = re.findall('<span class="dark_text">Japanese:</span>(.*?)</div>', _data)[0][1:]
    except:pass
    try:self.serializations = "".join(re.findall('>(.*?)<', re.findall('<span class="dark_text">Serialization:</span>(.*?)</div>', _data)[0]))
    except:pass
    try:
      _ranked = re.findall('>(.*?)<', re.findall('<span class="dark_text">Ranked:(.*?)</div>', _data)[0])
      self.ranked = "%s^%s" % (_ranked[0][1:], _ranked[2])
    except:pass
    try:self.popularity = re.findall('<span class="dark_text">Popularity:</span>(.*?)</div>', _data)[0][1:]
    except:pass
    try:self.members = re.findall('<span class="dark_text">Members:</span>(.*?)</div>', _data)[0][1:]
    except:pass
    try:self.favorites = re.findall('<span class="dark_text">Favorites:</span>(.*?)</div>', _data)[0][1:]
    except:pass
    
  moreinfo = property(getMoreInfo)
      
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
      self.data = Request("https://myanimelist.net/api/anime/search.xml?q=%s" % self.query, self.auth).replace('\r','').replace('\n','').replace('&lt;br /&gt;','<br />').replace('&amp;','&')
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
      self.data = Request("https://myanimelist.net/api/manga/search.xml?q=%s" % self.query, self.auth).replace('\r','').replace('\n','').replace('&lt;br /&gt;','<br />').replace('&amp;','&')
      _id = re.findall("<id>(.*?)</id>", self.data)
      _title = re.findall("<title>(.*?)</title>", self.data)
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
          synonyms = entry[3],
          chapters = entry[4],
          volumes = entry[5],
          score = entry[6],
          type = entry[7],
          status = entry[8],
          start_date = entry[9],
          end_date = entry[10],
          synopsis = entry[11],
          image = entry[12]
          )
        if _manga not in self.mangaresults:
          self.mangaresults.append(_manga)
      return self.mangaresults

  anime = property(AnimeSearch)
  manga = property(MangaSearch)
