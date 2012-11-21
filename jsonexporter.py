import json

def jsonizer(obj, specify_object_type = True):
	'''Assists in serializing models to JSON.

	>>> json.dumps(an_artist, default=jsonizer)
	'{"_type" : "Artist", "name" : ...
	'''
	j_dict = {}
	if specify_object_type:
		j_dict['object_type_name'] = obj.__class__.__name__
	j_dict.update(obj.__dict__)
	return j_dict 

def screen(what):
	print what

class JsonConsoleExporter:
	def __init__(self, params):
		self.out = screen
		self.file = None
		if params:
			self.file = open(params, 'w')
			self.out = self.file.write

	def dump(self, what):
		self.out(json.dumps(what, default=jsonizer))
		
	def finish(self, completely_done = False):
		if completely_done and self.file:
			self.file.close()
	
	def storeArtist(self, artist):
		self.dump(artist)
	
	def storeLabel(self, label):
		self.dump(label)

	def storeRelease(self, release):
		self.dump(release)

	def storeMaster(self, master):
		self.dump(master)
