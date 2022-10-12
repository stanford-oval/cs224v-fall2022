#!/usr/bin/env bash

set -e
set -x
set -o pipefail

install_node() {
	echo "About to install nvm and nodejs 14"
	if [[ -n $(nvm -v 2>&1) ]] ; then
		wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
		\. $HOME/.nvm/nvm.sh --no-use
	fi
	nvm install 14.18
}

install_deps_dnf() {
	echo "About to install git, make, gettext, g++, pulseaudio, python3"
	sudo dnf -y install git make gettext gcc-c++ pulseaudio-libs-devel python3-pip python3.8 python3-devel python3-distutils
}

install_deps_ubuntu() {
	echo "About to install git, make, gettext, curl, python3"
	sudo apt -y install software-properties-common
	sudo add-apt-repository ppa:deadsnakes/ppa
	sudo apt -y install git make gettext g++ curl libpulse-dev python3-pip python3.8 python3.8-dev python3.8-distutils
	sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.8 10
}

install_deps_debian() {
	echo "About to install git, make, gettext, curl"
	sudo apt -y install git make gettext g++ curl libpulse-dev python3-pip python3-distutils apt-transport-https bc

	echo "About to install python3.8 (from source)"
	sudo apt update
	sudo apt -y install build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libsqlite3-dev libreadline-dev libffi-dev curl libbz2-dev liblzma-dev
	curl -O https://www.python.org/ftp/python/3.8.2/Python-3.8.2.tar.xz
	tar -xf Python-3.8.2.tar.xz
	cd Python-3.8.2
	./configure --enable-optimizations --enable-loadable-sqlite-extensions
	make -j 8
	sudo make altinstall
	cd ..
}

install_deps() {
	if grep -qE "ID(_LIKE)?=.*fedora.*" /etc/os-release ; then
		install_deps_dnf
	elif grep -qE "ID(_LIKE)?=.*ubuntu.*" /etc/os-release ; then
		install_deps_ubuntu
	elif grep -qE "ID(_LIKE)?=.*debian.*" /etc/os-release ; then
		install_deps_debian
	else
		echo "Cannot detect the running distro. Please install dependencies using your package manager."
		exit 1
	fi
}

check_deps() {
	for dep in git make gettext g++ curl libpulse-dev python3-pip python3.8; do
		if ! which $dep >/dev/null 2>&1 ; then
			return 1
		fi
	done
	return 0
}

venv_activate() {
	if [[ -n "${VIRTUAL_ENV}" ]] ; then
		unset VIRTUAL_ENV & deactivate
	elif [[ -n "${CONDA_DEFAULT_ENV}" ]] ; then 
		CONDA_VERSION=$(cut -d ' ' -f 2 <<< "$(conda -V)")
		VERSION_NUM=$(cut -d '.' -f 1,2 <<< "$CONDA_VERSION")
		if [[ "`echo "${VERSION_NUM} < 4.6" | bc`" -eq 1 ]]; then
			conda init bash
			source deactivate
		else 
			conda init bash
			conda deactivate 
		fi
	fi

	python3 -m pip install --user virtualenv
	python3 -m virtualenv .virtualenv/genie --python=$(which python3.8)
	source .virtualenv/genie/bin/activate
}

if ! check_deps ; then
	install_deps
fi
	
install_node

if ! test -d genie-toolkit ; then
	git clone https://github.com/stanford-oval/genie-toolkit
	pushd genie-toolkit > /dev/null
	npm ci
	npm link
	popd >/dev/null
fi

if ! test -d genie-server ; then
	git clone https://github.com/stanford-oval/genie-server
	pushd genie-server > /dev/null
	npm ci
	popd
fi

if ! test -d thingpedia-common-devices ; then 
	git clone https://github.com/stanford-oval/thingpedia-common-devices
	pushd thingpedia-common-devices > /dev/null
	npm ci 
	npx make
	npm link genie-toolkit
	popd
fi

venv_activate
pip install --upgrade pip	
echo $(which python)
pip install genienlp tensorboard spacy 
python -m spacy download en_core_web_sm
pip install pathos==0.2.9
pip install pydantic==1.8
pip install 'ray[serve]==1.6.0'