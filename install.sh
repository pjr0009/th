command_exists () {
    type "$1" &> /dev/null ;
}

if docker ps -a | grep 'mysqldata'; then
  printf '\ndata volume already exists, skipping\n'
else
  docker run -v /var/lib/mysql --name="mysqldata" ubuntu:14.04
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
