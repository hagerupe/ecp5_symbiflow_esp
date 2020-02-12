all :
	docker build --network=host -t ecp5:local .

run : all
	docker run --network=host -it ecp5:local

