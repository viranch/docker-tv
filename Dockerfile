FROM base/archlinux

RUN pacman --noprogressbar --noconfirm -Syy archlinux-keyring

RUN pacman --noprogressbar --noconfirm -S apache transmission-cli
