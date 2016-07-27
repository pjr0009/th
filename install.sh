command_exists () {
    type "$1" &> /dev/null ;
}

if command_exists virtualbox; then
  printf "\nvirtual box installed... moving on\n"
else
  printf "\n\nERROR: please install virtualbox to run docker-machine\n"
  exit 1
fi

printf "checking if docker toolkit is installed..."
#check for docker toolbox
if command_exists docker && command_exists docker-machine && command_exists docker-compose; then
  printf "true\n"
else
  printf "\nplease install the docker toolkit: https://www.docker.com/products/docker-toolbox"
  printf "\nexiting\n"
  exit 1
fi

#check if tackhunter docker machine exists
if docker-machine ls -q | grep '^tackhunter$'; then
  docker-machine rm tackhunter
fi

docker-machine create --driver virtualbox --virtualbox-memory 2048 --virtualbox-cpu-count 2 tackhunter
#set up port forwarding rules so that you can connect from other machines on the network
#via the host machine's ip
#[--natpf<1-N> [<rulename>],tcp|udp,[<hostip>], <hostport>,[<guestip>],<guestport>]
# VBoxManage modifyvm "tackhunter" --natpf1 "dev, tcp,,8080,,80"
# VBoxManage modifyvm "tackhunter" --natpf1 "dev-ssl, tcp,,8443,,443"

docker-machine start tackhunter

printf "\nchecking host file for dev entries\n"

#check if bash profile entry that conditionally sets docker-machine env vars is present, if not then set it.
if ! grep -q "if docker-machine status | grep '^Running'; then eval" ~/.bash_profile; then
  echo "if docker-machine status | grep '^Running'; then eval \"\$(docker-machine env tackhunter)\"; fi" > ~/.bash_profile
fi


eval $(docker-machine env tackhunter)
docker-machine regenerate-certs tackhunter

if docker ps -a | grep 'pgdata'; then
  printf '\ndata volume already exists, skipping\n'
else
  docker run -v /var/lib/postgresql/data/pgdata --name="pgdata" ubuntu:14.04
fi

if docker ps -a | grep 'ruby_gems'; then
  printf '\ngem data volume already exists, skipping\n'
else
  docker run -v /usr/local/bundle --name="ruby_gems" ubuntu:14.04
fi

brew install tmux

#if tmux is started and there is already a session running, kill it
tmux kill-session


docker-compose build
#remove any one off containers that are around from previous sessions
docker-compose stop; echo "y" | docker-compose rm -a
docker-compose run web bundle install



#!/bin/bash
tmux new-session -d -s dorsata
tmux send-keys 'tmux source-file .tmux.conf' Enter
tmux rename-window 'tackhunter Dev'
tmux split-window -v -t 0
tmux send-keys 'docker-compose run web rails c' Enter
tmux split-window -h -t 0
tmux send-keys 'docker-compose up' Enter
tmux resize-pane -D 10
tmux -2 attach-session -t dorsata
