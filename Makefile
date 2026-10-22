
run:
	sudo docker run --name=$(NAME) -ti --rm $(NAME) bash

clean:
	sudo rm -rf /tmp/$(NAME)
	sudo docker rm -f $(NAME) || true
	sudo docker rmi $(NAME) || true
