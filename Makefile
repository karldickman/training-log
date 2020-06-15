all: workout
clean:
	$(RM) *.pyc workout run bike hike walk
install:
	cp workout run bike hike walk ~/.local/bin
# Copy scripts to installation names
workout:
	cp training_log.py workout
	cp run.sh run
	cp bike.sh bike
	cp hike.sh hike
	cp walk.sh walk
