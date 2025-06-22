FROM mambaorg/micromamba:2.1.1

# these args are passed in from the docker command line, for example:
# docker build --build-arg USERNAME=... --build-arg USER_ID=... --build-arg GROUP_ID=... -t ...
# See Makefile target 'base-img'

ARG USERNAME
ARG USER_ID
ARG GROUP_ID

# create the new user and make them the active user so we don't run as root
USER root
RUN groupadd -g $GROUP_ID $USERNAME && useradd -m -u $USER_ID -g $GROUP_ID -s /bin/bash $USERNAME
USER $USERNAME

# set the container's working directory
WORKDIR /rb-micromamba

# create rb-micromamba-env per env_lock.yml and then activate it
COPY --chown=$USERNAME:$USERNAME env_lock.yml ./env_lock.yml
RUN micromamba create -n rb-micromamba-env -f env_lock.yml && micromamba clean --all --yes
ARG MAMBA_DOCKERFILE_ACTIVATE=1  # this is the default but keep it here for clarity

# append custom bashrc to the default ~/.bashrc file
COPY --chown=$USERNAME:$USERNAME bin/bashrc /home/$USERNAME/.bashrc.custom
RUN cat >> /home/$USERNAME/.bashrc <<EOF
if [ -f ~/.bashrc.custom ]; then
  . ~/.bashrc.custom
fi
EOF

ENV PATH="/opt/conda/envs/rb-micromamba-env/bin:$PATH"

# ENTRYPOINT ["/bin/bash"]
# CMD ["-c", "exec tail -f /dev/null"] 