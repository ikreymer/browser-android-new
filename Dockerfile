#adapted from
#https://github.com/softsam/docker-android-emulator

FROM oldwebtoday/base-browser

# Install all dependencies
RUN apt-get update && \
    apt-get install -qqy software-properties-common && \
    add-apt-repository ppa:openjdk-r/ppa && \
    apt-get update && \
    apt-get install -y wget openjdk-8-jre-headless libc6-i386 lib32stdc++6 x11-xserver-utils unzip && \
    apt-get clean && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install android tools + sdk
ARG SDK_BASE=https://dl.google.com/android/repository/tools_r25.2.5-linux.zip

ENV ANDROID_HOME /opt/android-sdk-linux
ENV PATH $PATH:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools

#RUN wget -qO- "$SDK_BASE" | tar -zx -C /opt && \
#    echo y | android update sdk --no-ui --all --filter platform-tools --force
RUN curl "$SDK_BASE" > /tmp/sdk.zip && unzip /tmp/sdk.zip -d /opt/android-sdk-linux && \
    echo y | android update sdk --no-ui --all --filter platform-tools --force

# Needed to be able to run VNC - bug of Android SDK
#RUN mkdir ${ANDROID_HOME}/tools/keymaps && touch ${ANDROID_HOME}/tools/keymaps/en-us

#RUN android list sdk --all
RUN mkdir -m 0750 /.android

RUN sdkmanager --update

RUN mkdir $ANDROID_HOME/licenses
RUN echo 8933bad161af4178b1185d1a37fbf41ea5269c55 > $ANDROID_HOME/licenses/android-sdk-license
RUN echo 84831b9409646a918e30573bab4c9c91346d8abd > $ANDROID_HOME/licenses/android-sdk-preview-license

ARG SDK_VERS=25
ARG ANDROID_ARCH=x86_64

RUN sdkmanager "tools" "platforms;android-$SDK_VERS" "emulator"

RUN sdkmanager --verbose "system-images;android-$SDK_VERS;google_apis;$ANDROID_ARCH"

RUN echo n | avdmanager --verbose create avd --force -n "$ANDROID_ARCH" -k "system-images;android-$SDK_VERS;google_apis;$ANDROID_ARCH" --tag google_apis

# Add entrypoint
ADD addcert.sh /app/addcert.sh
ADD layout $ANDROID_HOME/platforms/android-$SDK_VERS/skins/WVGA800/layout
ADD jwmrc /root/.jwmrc

ENV ANDROID_ARCH $ANDROID_ARCH
ENV SDK_VERS $SDK_VERS

# qemu tools for snapshot
RUN apt-get update && apt-get install -qqy qemu-utils

ADD run.sh /app/run.sh
CMD /app/entry_point.sh /app/run.sh


LABEL wr.name="Android" \
      wr.version="API $SDK_VERS" \
      wr.os="android" \
      wr.release="2016-09-14" \
      wr.icon="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAABCUlEQVR4nMWQoU4DYRCEvznopSAQRdQhEGgUFs5cQlA8AQLZUMUb1CEpFslTHJCrgIcgkJCQlCAIqg0Q7gYDSa/8F+o6cnZ2dmdg3lDdoD9INzAPYEVivbOd3YV0UXA5T1uCHjACjUt00s/T9swG4PPSXgUbaFC6Ab74N8JZnrbBhdExsFSxhBKpt+Ci2dm5HP7yi1WR+4axYB9Y+XPJ5XKB1oDdoAEoFnyFY4FRDMSTXE0Hs6PygfDA6B3YC4mFb4zuq1wAp3n6KmhNcoYCu9lNskrEqQ5+XO1NpCvsa+AN6RB7a3oZajo4SrInzAj0AgxtPrpJ9hjSBj8AUOQDm2fEJyW3dbr54xuZP12+ugYsYQAAAABJRU5ErkJggg=="


