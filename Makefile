all: workout
clean:
	$(RM) *.pyc workout
install:
	cp workout ~/.local/bin
# Copy scripts to installation names
workout:
	cp training_log.py workout
