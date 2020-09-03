#----------------------------------------------------------------------
# makefile for Hydra
# John T. O'Donnell
# See README.txt, LICENSE.txt, index.html
#----------------------------------------------------------------------

# Compilation requires ghc
# Building user guide requires pandoc, m4

# Usage:

#  make show-parameters for debugging, show makefile variables
#  make install         compile and install
#  make doc             haddock and user guide
#  make userguide       create doc/html files from markdown source
#  make clean           delete temp files but keep documentation
#  make veryclean       also delete generated doc/html files
#  make snapshot        save a .tgz tarball in archive directory
#  make fullcopy        save a full copy in archive directory
#  make listarchive     list the archive directory

# The ArchiveLocation is relative to the parent directory of
# Hydra-i.j.k

ArchiveLocation := ../../Hydra/archive

#----------------------------------------------------------------------
# Calculate locations and times, don't need to edit these

# Generate filename for archive
PackagePath := $(shell pwd)
PackageName := $(shell basename $(PackagePath))
DateTimeStamp := $(shell date +%Y-%m-%d-at-%H-%M)
BuildDate != date +%d\ %b\ %Y
TarballName := $(PackageName)-on-$(DateTimeStamp).tgz
FullCopyName := $(PackageName)-on-$(DateTimeStamp)

# Provide version number in generated html documentation
HydraVersion != grep < Hydra.cabal ^version
VersionDate = $(HydraVersion)

# make show-parameters -- print calculated parameters
.PHONY : show-parameters
show-parameters :
	echo PackagePath = $(PackagePath)
	echo PackageName = $(PackageName)
	echo DateTimeStamp = $(DateTimeStamp)
	echo BuildDate = $(BuildDate)
	echo TarballName = $(TarballName)
	echo FullCopyName = $(FullCopyName)
	echo ArchiveLocation = $(ArchiveLocation)
	echo HydraVersion = $(HydraVersion)
	echo VersionDate = $(VersionDate)

#----------------------------------------------------------------------
# Compilation

# Compile and install but don't try to build the user guide, which
# requires software that some users may not have installed (m4,
# pandoc).
.PHONY : install
install :
	cabal configure
	cabal install
	cabal haddock

# Compile, install, and build the user guide
.PHONY : all
all :
	make install
	make userguide

#----------------------------------------------------------------------
# User guide

# The source for the user guide (in src/docsrc) is written in pandoc.
# The object html files are placed in doc/userguide/html.  The m4 and
# pandoc programs are needed to build the html.

.PHONY : userguide
userguide :
	mkdir -p doc/userguide/html
	cp -r -u src/docsrc/figures doc/userguide
	cp src/docsrc/style.css doc/userguide/html
	m4 -P src/docsrc/indexsrc.m4 \
	  >doc/userguide/html/indextemp.txt
	pandoc --standalone \
          --read markdown --write html \
          --table-of-contents --toc-depth=4 \
          --variable=date:'$(VersionDate)' \
          --variable=css:style.css \
          -o doc/userguide/html/index.html \
	    doc/userguide/html/indextemp.txt

#----------------------------------------------------------------------
# Make a listing as pdf file

.PHONY : listing
listing :
	a2ps src/haskell/*.hs src/haskell/HDL/Hydra/*/*.hs \
	  -o listing.ps
	ps2pdf listing.ps
	rm -f listing.ps

#----------------------------------------------------------------------
# Maintaining the directories

# make clean -- remove backup and object files
.PHONY : clean
clean :
	find . \( -name '*~' -o -name '*.hi' -o \
	          -name '*.bak' -o -name '*.o' \) \
	       -delete
	rm -f doc/userguide/html/indextemp.txt
	rm -f listing.pdf
	runhaskell Setup clean

# make veryclean -- remove html documentation files generated by
# pandoc and cabal, leaving a minimal source directory
.PHONY : veryclean
veryclean :
	make clean
	rm -rf doc

# make snapshot -- create a tgz file of the entire
# Sigma16-i.j.k directory and place it in the archive directory.  See
# README.txt for directory layout.
.PHONY : snapshot
snapshot :
	cd .. ; \
	  pwd ; \
	  tar -czf $(TarballName) $(PackageName) ; \
	  mv $(TarballName) $(ArchiveLocation)

# make fullcopy -- create a full copy of the entire Sigma16-i.j.k
# directory and place it in the archive directory.
.PHONY : fullcopy
fullcopy :
	cd ..; \
	  pwd ; \
	  cp -rp $(PackagePath) $(ArchiveLocation)/$(FullCopyName)

# make listarchive -- list contents of the archive directory
.PHONY : listarchive
listarchive :
	ls -lctr ../$(ArchiveLocation)
