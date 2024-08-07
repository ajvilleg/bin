#!/usr/bin/env python

#import os
#import sys
#import time

# Reference: http://www.blog.pythonlibrary.org/2013/11/14/python-101-how-to-write-a-cleanup-script/

def remove(path):
	# Remove the file or directory
	if os.path.isdir(path):
		try:
			os.rmdir(path)
		except OSError:
			print "Unable to remove folder: %s" % path
	else:
		try:
			if os.path.exists(path):
				os.remove(path)
		except OSError:
			print "Unable to remove file: %s" % path

def cleanup(number_of_days, path):
	# Removes files from the passed in path that are older or equal
	# to the number_of_days
	time_in_secs = time.time() - (number_of_days * 24 * 60 * 60)
	for root, dirs, files in os.walk(path, topdown=False):
		for file_ in files:
			full_path = os.path.join(root, file_)
			stat = os.stat(full_path)

			if stat.st_mtime <= time_in_secs:
				remove(full_path)

		if not os.listdir(root):
			remove(root)

if __name__ == "__main__":
	days, path = int(sys.argv[1]), sys.argv[2]
	cleanup(days, path)
