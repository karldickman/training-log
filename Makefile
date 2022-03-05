all: workout
clean:
	$(RM) -r *.pyc
install:
	cp bin/* ~/.local/bin
	cp workout.ini ~/.workout.ini
# Copy scripts to installation names
bin:
	mkdir bin
workout: bin training_log.py run.sh bike.sh hike.sh walk.sh run-walk.sh
	cp training_log.py bin/workout
	cp run.sh bin/run
	cp bike.sh bin/bike
	cp hike.sh bin/hike
	cp walk.sh bin/walk
	cp run-walk.sh bin/run-walk
