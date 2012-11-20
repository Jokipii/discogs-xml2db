#!/usr/bin/python
# -*- coding: utf-8 -*-
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
import threading, Queue
import time

# This is hard limit for worker threads Exporter starts
THREAD_LIMIT = 4

def select_exporter(options, exporters):
	if options.output is None:
		return exporters['json']
	if exporters.has_key(options.output):
		return exporters[options.output]
	# should I be throwing an exception here?
	return exporters['json']

def make_exporter(options, exporters):
	exp_module = select_exporter(options, exporters)
	parts = exp_module.split('.')
	m = __import__('.'.join(parts[:-1]))
	for i in xrange(1, len(parts)):
		m = getattr(m, parts[i])
	return m(options.params)

class Exporter:
	"""
	This is Exporter main class. It takes objects from parser and stores them to
	jobs queue. It spawns ExporterWorker thread(s) to take them from jobs
	queue and run actual exporter.

	Because this class works between parser and actual exporters all data
	quality checking tasks are done here.
	"""
	
	def __init__(self, options, jobs, exporters):
		self.options = options
		self.min_data_quality = list(x.strip().lower() for x in (options.data_quality or '').split(',') if x)
		self.jobs = jobs
		self.exporters = exporters
		self.runningThreads = 0
		self.workers = []
		self.count = 0
		self.startWorkers(options.number_of_workers)
		if self.options.verbose:
			print 'in verbose mode we print out timeing and queue size info per 10.000 entries' 
			self.timer = time.time()
	
	def good_quality(self, what):
		if len(self.min_data_quality):
			# print "Bad quality: %s for %s" % (what.data_quality, what.id)
			return what.data_quality.lower() in self.min_data_quality
		return True

	def finish(self, completely_done = False):
		# waits for all jobs to be done
		if self.options.verbose:
			if completely_done:
				print 'Stopping all workers'
			else:
				print 'Waiting for all jobs to be done!'
		self.jobs.join()
		# now we can safely send finish to exporter
		for worker in self.workers:
			worker.exporter.finish(completely_done)
			if completely_done:
				# we are finnished so set workers to mode where they can stop
				worker.finish()
	
	def storeArtist(self, artist):
		self.store('artist', artist)
	
	def storeLabel(self, label):
		self.store('label', label)

	def storeRelease(self, release):
		self.store('release', release)

	def storeMaster(self, master):
		self.store('master', master)
	
	def store(self, entity_type, task_object):
		if not self.good_quality(task_object): return
		try:
			job = (entity_type, task_object)
			# tries to put task_object to queue 15s timeout is max time that is allowed before throwing Queue.Full
			self.jobs.put(job, block=False)
		except Queue.Full as e:
			if self.options.verbose:
				print "The jobs queue is full!"
			time.sleep(10)
			try:
				self.jobs.put(job, block=True, timeout=15)
			except Queue.Full as e2:
				raise Exporter.ExecuteError(e2.args)
		self.count = self.count + 1
		if self.count % 500 == 0:
			qs = self.jobs.qsize()
			# with every 100,00 we print out current queue size
			if self.options.verbose and self.count % 1000 == 0:
				print "%.2fs queue size %s" % (time.time()-self.timer, qs)
				self.timer = time.time()
			# if queue start filling we sleep
			if qs < 5000: pass
			elif qs > 9500: time.sleep(10)
			elif qs > 9000: time.sleep(3)
			elif qs > 8000: time.sleep(1)
			elif qs > 7000: time.sleep(.5)
			else: time.sleep(.1)
	
	def startWorkers(self, number_of_workers):
		for x in xrange(number_of_workers):
			self.startWorker()
	
	def startWorker(self):
		if self.runningThreads < THREAD_LIMIT:
			# Spawn the threads
			self.runningThreads = self.runningThreads + 1
			if self.options.verbose:
				print "Starting ExporterWorker thread {0} ...".format(self.runningThreads)
			exporter = make_exporter(self.options, self.exporters)
			worker = ExporterWorker(exporter, self.jobs)
			self.workers.append(worker)
			worker.start()
		else:
			print "ExporterWorker not stated. Number of threads limited to {0}.".format(THREAD_LIMIT)
	
	class ExecuteError(Exception):
		def __init__(self, args):
			self.args = args


class ExporterWorker(threading.Thread):
	"""
	This is ExporterWorker class. It is based on threading.Thread so it can be 
	cloned/used as a thread template to spawn exporter threads.

	The class run function gets a job out of the
	jobs queue and handles actual exporting task to underlaying specific exporter.
	It also lets the queue object know when actual export has finished.
	"""
	
	def __init__(self, exporter, jobs):
		super(ExporterWorker, self).__init__()
		self.exporter = exporter
		self.jobs = jobs
		self.finished = False

	def finish(self):
		self.finished = True

	def doTask(self, entity_type, task_object):
		if entity_type == 'release':
			self.exporter.storeRelease(task_object)
		elif entity_type == 'artist':
			self.exporter.storeArtist(task_object)
		elif entity_type == 'master':
			self.exporter.storeMaster(task_object)
		elif entity_type == 'label':
			self.exporter.storeLabel(task_object)

	def run(self):
		# run forever
		while 1:
			try:
				# Try and get a job out of the queue
				job = self.jobs.get(False)
				# Run actual exporter
				self.doTask(job[0], job[1])
				# Let the queue know the job is finished.
				self.jobs.task_done()
			except Queue.Empty:
				# No more jobs in the queue, we finish if that is allowed
				if self.finished: break
				time.sleep(.1)
