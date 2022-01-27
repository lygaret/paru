FROM ruby:3.0
ENV LANG C.UTF-8
RUN apt-get update \
  ; apt-get install -y wget texlive-base \
  ; wget -q https://github.com/jgm/pandoc/releases/download/2.17.0.1/pandoc-2.17.0.1-1-amd64.deb \
  ; apt-get install ./pandoc-2.17.0.1-1-amd64.deb  \
  ; useradd -ms /bin/bash paru-user
USER paru-user 
SHELL ["/bin/bash", "-l", "-c"]
COPY . /home/paru-user/
WORKDIR /home/paru-user
RUN gem install bundler \
  ; bundler install
