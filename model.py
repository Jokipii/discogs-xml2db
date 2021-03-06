class Artist:
   def __init__(self):
      self.id = 0
      self.name = ''
      self.realname = ''
      self.images = []
      #self.urls = {'wikipedia':None, 'myspace':None,'other':[]}
      self.urls = []
      self.namevariations = [] 
      self.aliases = []
      self.profile = ''
      self.members = []#MemberNameList, foreign key name, class Artist
      self.groups = []#GroupNameList, foreign key name, class Artist
      #self.artistType = 0 #0 = person, 1 = group 
      #self.artist_id = ''
      self.data_quality = ''

class Release:
   def __init__(self):
     self.id = 0
     self.status = ''
     self.title = ''
     self.country = ''
     self.released = ''
     self.notes = ''
     self.genres = []
     self.styles = []
     self.images = []
     self.formats = []
     self.labels = []
     self.anv = '' #used only if artist name is missing
     self.artist = ''
     self.artists = [] #join
     self.tracklist = [] #join
     self.extraartists = []
     self.data_quality = ''
     self.master_id = 0
     self.identifiers = []
     self.companies = []
     self.videos = []

class Master:
   def __init__(self):
     self.id = 0
     #self.status = ''
     self.title = ''
     self.main_release = 0
     self.year = 0
     self.notes = ''
     self.genres = []
     self.styles = []
     self.images = []
     self.artist = ''
     self.artists = [] #join
     self.extraartists = []
     self.data_quality = ''
     self.videos = []
     #self.tracklist = []

class ArtistJoin:
  def __init__(self):
    self.artist1 = ''
    self.join_relation = ''

class Extraartist:
  def __init__(self):
    self.name = ''
    self.roles = []

class ReleaseLabel:
  def __init__(self):
    self.name = ''
    self.catno = ''

class Label:
  def __init__(self):
    self.id = 0
    self.name = ''
    self.images = []
    self.contactinfo = ''
    self.profile = ''
    self.parentLabel = ''
    self.urls = []
    self.sublabels = []
    self.data_quality = ''

class Format:
  def __init__(self):
    self.name = ''
    self.qty = 0
    self.text = ''
    self.descriptions = []

class Style:
  def __init__(self, name):
    self.name = name
    #self.genres = []

class Genre:
  def __init__(self, name):
    self.name = name

class Track:
  def __init__(self):
    self.artists = []
    self.artistJoins = []
    self.extraartists = []
    self.title = ''
    self.duration = ''
    self.position = ''

class ImageInfo:
  def __init__(self):
    self.height = 0      
    self.imageType = None #enum ImageType.PRIMARY or ImageType.SECONDARY
    self.uri = ''    
    self.uri150 = '' 
    self.width = 0   

class ImageType:
  PRIMARY = 0
  SECONDARY = 1

class Video:
  def __init__(self):
    self.duration = 0
    self.embed = ''
    self.title = ''
    self.description = ''
    self.uri = ''

class ArtistCredit:
  def __init__(self):
    self.id = 0
    self.join = ''
    self.tracks = ''
    self.roles = []
    self.anv = ''
    self.name = ''

class Identifier:
  def __init__(self):
    self.type = ''
    self.value = ''
    self.description = ''

class ParserStopError(Exception):
	"""Raised by a parser to signal that it wants to stop parsing."""
	def __init__(self, count):
		self.records_parsed = count

